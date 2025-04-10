// lib/data/repositories/chat_repository_impl.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:buapnet/data/models/chat_model.dart';
import 'package:buapnet/data/models/user_model.dart';
import 'package:buapnet/services/image_service.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final ImageService _imageService = ImageService();
  
  // Referencias a colecciones
  CollectionReference get _chatsCollection => _firestore.collection('chats');
  CollectionReference get _messagesCollection => _firestore.collection('messages');
  CollectionReference get _usersCollection => _firestore.collection('users');
  
  // Crear o obtener un chat entre dos usuarios
  Future<ChatModel> getOrCreateChat({
    required String currentUserId, 
    required String otherUserId,
    bool isModeratorChat = false,
  }) async {
    try {
      // Verificar si ya existe un chat entre estos usuarios
      final chatQuery = await _chatsCollection
          .where('participants', arrayContainsAny: [currentUserId, otherUserId])
          .get();
      
      // Filtrar para encontrar el chat específico que contiene exactamente estos dos usuarios
      final existingChat = chatQuery.docs.where((doc) {
        final chat = ChatModel.fromFirestore(doc);
        return chat.participants.contains(currentUserId) && 
               chat.participants.contains(otherUserId) &&
               chat.participants.length == 2;
      }).toList();
      
      // Si existe, retornar el chat existente
      if (existingChat.isNotEmpty) {
        return ChatModel.fromFirestore(existingChat.first);
      }
      
      // Si no existe, crear un nuevo chat
      // Obtener datos de los usuarios
      final currentUserDoc = await _usersCollection.doc(currentUserId).get();
      final otherUserDoc = await _usersCollection.doc(otherUserId).get();
      
      final currentUser = UserModel.fromFirestore(currentUserDoc);
      final otherUser = UserModel.fromFirestore(otherUserDoc);
      
      // Crear mapa de usernames y avatares
      final Map<String, String> usernames = {
        currentUserId: currentUser.username,
        otherUserId: otherUser.username,
      };
      
      final Map<String, String> avatars = {
        currentUserId: currentUser.avatarBase64,  // Actualizado a avatarBase64
        otherUserId: otherUser.avatarBase64,      // Actualizado a avatarBase64
      };
      
      // Crear el nuevo chat
      final chatId = _uuid.v4();
      final newChat = ChatModel(
        id: chatId,
        participants: [currentUserId, otherUserId],
        participantUsernames: usernames,
        participantAvatars: avatars,
        lastMessageTime: DateTime.now(),
        lastMessageText: '', // Sin mensajes aún
        lastMessageSenderId: '',
        isModeratorChat: isModeratorChat,
      );
      
      // Guardar en Firestore
      await _chatsCollection.doc(chatId).set(newChat.toMap());
      
      return newChat;
    } catch (e) {
      rethrow;
    }
  }
  
  // Obtener lista de chats de un usuario
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _chatsCollection
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList();
        });
  }
  
  // Enviar un mensaje de texto
  Future<MessageModel> sendTextMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    try {
      // Obtener datos del usuario
      final userDoc = await _usersCollection.doc(senderId).get();
      final user = UserModel.fromFirestore(userDoc);
      
      // Crear documento del mensaje
      final messageId = _uuid.v4();
      final message = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderUsername: user.username,
        content: content,
        mediaBase64: null,  // Actualizado a mediaBase64
        timestamp: DateTime.now(),
      );
      
      // Guardar mensaje en Firestore
      await _messagesCollection.doc(messageId).set(message.toMap());
      
      // Actualizar último mensaje en el chat
      await _chatsCollection.doc(chatId).update({
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
        'lastMessageText': content,
        'lastMessageSenderId': senderId,
      });
      
      return message;
    } catch (e) {
      rethrow;
    }
  }
  
  // Enviar un mensaje con media (actualizado para usar Base64)
  Future<MessageModel> sendMediaMessage({
    required String chatId,
    required String senderId,
    required String content,
    required File mediaFile,
  }) async {
    try {
      // Obtener datos del usuario
      final userDoc = await _usersCollection.doc(senderId).get();
      final user = UserModel.fromFirestore(userDoc);
      
      // Convertir imagen a Base64
      final mediaBase64 = await _imageService.encodeImageToBase64(
        mediaFile,
        quality: 50,  // Usar compresión media para imágenes de chat
        maxWidth: 1200,
        maxHeight: 1200,
      );
      
      // Crear documento del mensaje
      final messageId = _uuid.v4();
      final message = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderUsername: user.username,
        content: content,
        mediaBase64: mediaBase64,  // Actualizado a mediaBase64
        timestamp: DateTime.now(),
      );
      
      // Guardar mensaje en Firestore
      await _messagesCollection.doc(messageId).set(message.toMap());
      
      // Actualizar último mensaje en el chat
      await _chatsCollection.doc(chatId).update({
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
        'lastMessageText': content.isEmpty ? '📷 Imagen' : content,
        'lastMessageSenderId': senderId,
      });
      
      return message;
    } catch (e) {
      rethrow;
    }
  }
  
  // Obtener mensajes de un chat
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _messagesCollection
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();
        });
  }
  
  // Marcar mensajes como leídos
  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      // Obtener mensajes no leídos que no fueron enviados por el usuario actual
      final querySnapshot = await _messagesCollection
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      // Actualizar cada mensaje no leído
      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
  
  // Obtener chats de moderador (para moderadores)
  Stream<List<ChatModel>> getModeratorChats(String moderatorId) {
    return _chatsCollection
        .where('participants', arrayContains: moderatorId)
        .where('isModeratorChat', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList();
        });
  }
  
  // Iniciar un chat con un moderador (para estudiantes)
  Future<ChatModel> startModeratorChat({
    required String studentId,
    required String moderatorId,
  }) async {
    return getOrCreateChat(
      currentUserId: studentId,
      otherUserId: moderatorId,
      isModeratorChat: true,
    );
  }
}