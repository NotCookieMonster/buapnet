import 'dart:io';
import 'package:flutter/material.dart';
import 'package:buapnet/data/models/chat_model.dart';
import 'package:buapnet/data/repositories/chat_repository_impl.dart';

class ChatProvider with ChangeNotifier {
  final ChatRepository _chatRepository = ChatRepository();
  
  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  String? _currentChatId;
  bool _isLoading = false;
  String? _error;
  bool _isSendingMessage = false;
  
  // Getters
  List<ChatModel> get chats => _chats;
  List<MessageModel> get messages => _messages;
  String? get currentChatId => _currentChatId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSendingMessage => _isSendingMessage;
  
  // Iniciar escucha de chats para un usuario
  void initUserChats(String userId) {
    _setLoading(true);
    
    _chatRepository.getUserChats(userId).listen(
      (chats) {
        _chats = chats;
        _setLoading(false);
        notifyListeners();
      },
      onError: (e) {
        _setError(e.toString());
        _setLoading(false);
      },
    );
  }
  
  // Iniciar escucha de mensajes para un chat específico
  void initChatMessages(String chatId) {
    _currentChatId = chatId;
    _setLoading(true);
    
    _chatRepository.getChatMessages(chatId).listen(
      (messages) {
        _messages = messages;
        _setLoading(false);
        notifyListeners();
      },
      onError: (e) {
        _setError(e.toString());
        _setLoading(false);
      },
    );
  }
  
  // Crear o obtener un chat con otro usuario
  Future<ChatModel?> getOrCreateChat({
    required String currentUserId, 
    required String otherUserId,
    bool isModeratorChat = false,
  }) async {
    _setLoading(true);
    _error = null;
    
    try {
      final chat = await _chatRepository.getOrCreateChat(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        isModeratorChat: isModeratorChat,
      );
      
      _setLoading(false);
      return chat;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }
  
  // Enviar un mensaje de texto
  Future<bool> sendTextMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return false;
    
    _isSendingMessage = true;
    _error = null;
    notifyListeners();
    
    try {
      await _chatRepository.sendTextMessage(
        chatId: chatId,
        senderId: senderId,
        content: content,
      );
      
      _isSendingMessage = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _isSendingMessage = false;
      notifyListeners();
      return false;
    }
  }
  
  // Enviar un mensaje con media
  Future<bool> sendMediaMessage({
    required String chatId,
    required String senderId,
    required String content,
    required File mediaFile,
  }) async {
    _isSendingMessage = true;
    _error = null;
    notifyListeners();
    
    try {
      await _chatRepository.sendMediaMessage(
        chatId: chatId,
        senderId: senderId,
        content: content,
        mediaFile: mediaFile,
      );
      
      _isSendingMessage = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _isSendingMessage = false;
      notifyListeners();
      return false;
    }
  }
  
  // Marcar mensajes como leídos
  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      await _chatRepository.markMessagesAsRead(
        chatId: chatId,
        userId: userId,
      );
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  // Iniciar un chat con un moderador
  Future<ChatModel?> startModeratorChat({
    required String studentId,
    required String moderatorId,
  }) async {
    _setLoading(true);
    _error = null;
    
    try {
      final chat = await _chatRepository.startModeratorChat(
        studentId: studentId,
        moderatorId: moderatorId,
      );
      
      _setLoading(false);
      return chat;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }
  
  // Obtener chats específicos para moderadores
  void initModeratorChats(String moderatorId) {
    _setLoading(true);
    
    _chatRepository.getModeratorChats(moderatorId).listen(
      (chats) {
        _chats = chats;
        _setLoading(false);
        notifyListeners();
      },
      onError: (e) {
        _setError(e.toString());
        _setLoading(false);
      },
    );
  }
  
  // Helpers para actualizar estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}