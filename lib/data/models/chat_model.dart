import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants; // IDs de los usuarios
  final Map<String, String> participantUsernames; // Mapa de ID a username
  final Map<String, String> participantAvatars; // Mapa de ID a avatar URL
  final DateTime lastMessageTime;
  final String lastMessageText;
  final String lastMessageSenderId;
  final bool isModeratorChat; // Indica si es un chat con un moderador
  
  ChatModel({
    required this.id,
    required this.participants,
    required this.participantUsernames,
    required this.participantAvatars,
    required this.lastMessageTime,
    required this.lastMessageText,
    required this.lastMessageSenderId,
    this.isModeratorChat = false,
  });
  
  // Método para convertir un documento de Firestore a ChatModel
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantUsernames: Map<String, String>.from(data['participantUsernames'] ?? {}),
      participantAvatars: Map<String, String>.from(data['participantAvatars'] ?? {}),
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      lastMessageText: data['lastMessageText'] ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      isModeratorChat: data['isModeratorChat'] ?? false,
    );
  }
  
  // Método para convertir ChatModel a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantUsernames': participantUsernames,
      'participantAvatars': participantAvatars,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageText': lastMessageText,
      'lastMessageSenderId': lastMessageSenderId,
      'isModeratorChat': isModeratorChat,
    };
  }
  
  // Método para actualizar el último mensaje
  ChatModel copyWithLastMessage({
    required String messageText,
    required String senderId,
  }) {
    return ChatModel(
      id: this.id,
      participants: this.participants,
      participantUsernames: this.participantUsernames,
      participantAvatars: this.participantAvatars,
      lastMessageTime: DateTime.now(),
      lastMessageText: messageText,
      lastMessageSenderId: senderId,
      isModeratorChat: this.isModeratorChat,
    );
  }
  
  // Método para obtener el otro participante para chats de 2 personas
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId, 
        orElse: () => '');
  }
  
  // Método para obtener el nombre del otro participante
  String getOtherParticipantUsername(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantUsernames[otherId] ?? 'Usuario';
  }
  
  // Método para obtener el avatar del otro participante
  String getOtherParticipantAvatar(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantAvatars[otherId] ?? '';
  }
  
  // Para depuración
  @override
  String toString() {
    return 'ChatModel(id: $id, participants: $participants, lastMessage: $lastMessageText)';
  }
}

// Modelo para los mensajes individuales
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderUsername;
  final String content;
  final String? mediaBase64;  // Cambiado de mediaUrl a mediaBase64
  final DateTime timestamp;
  final bool isRead;
  
  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    this.mediaBase64,  // Actualizado
    required this.timestamp,
    this.isRead = false,
  });
  
  // Método para convertir un documento de Firestore a MessageModel
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderUsername: data['senderUsername'] ?? '',
      content: data['content'] ?? '',
      mediaBase64: data['mediaBase64'],  // Actualizado
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }
  
  // Método para convertir MessageModel a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'content': content,
      'mediaBase64': mediaBase64,  // Actualizado
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
  
  // Método para marcar como leído
  MessageModel copyWithRead() {
    return MessageModel(
      id: this.id,
      chatId: this.chatId,
      senderId: this.senderId,
      senderUsername: this.senderUsername,
      content: this.content,
      mediaBase64: this.mediaBase64,  // Actualizado
      timestamp: this.timestamp,
      isRead: true,
    );
  }
  
  // Para depuración
  @override
  String toString() {
    return 'MessageModel(id: $id, chatId: $chatId, sender: $senderUsername, content: $content)';
  }
}