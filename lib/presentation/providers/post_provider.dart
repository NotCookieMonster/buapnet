import 'dart:io';
import 'package:flutter/material.dart';
import 'package:buapnet/data/models/post_model.dart';
import 'package:buapnet/data/models/comment_model.dart';
import 'package:buapnet/data/repositories/post_repository_impl.dart';
import 'package:buapnet/data/models/user_model.dart';
import 'package:buapnet/utils/image_utility.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class PostProvider with ChangeNotifier {
  final PostRepository _postRepository = PostRepository();
  
  List<PostModel> _posts = [];
  List<PostModel> _userPosts = [];
  List<PostModel> _pendingPosts = [];
  List<PostModel> _reportedPosts = [];
  List<CommentModel> _comments = [];
  
  String? _currentPostId;
  bool _isLoading = false;
  String? _error;
  bool _isCreatingPost = false;
  bool _isSearching = false;
  String _searchQuery = '';
  List<PostModel> _searchResults = [];
  
  // Getters
  List<PostModel> get posts => _posts;
  List<PostModel> get userPosts => _userPosts;
  List<PostModel> get pendingPosts => _pendingPosts;
  List<PostModel> get reportedPosts => _reportedPosts;
  List<CommentModel> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isCreatingPost => _isCreatingPost;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  List<PostModel> get searchResults => _searchResults;
  
  // Iniciar escucha del feed principal
  void initPostsFeed() {
    _setLoading(true);
    
    _postRepository.getPostsFeed().listen(
      (posts) {
        _posts = posts;
        _setLoading(false);
        notifyListeners();
      },
      onError: (e) {
        _setError(e.toString());
        _setLoading(false);
      },
    );
  }
  
  // Iniciar escucha de las publicaciones de un usuario
  void initUserPosts(String userId) {
    _setLoading(true);
    
    _postRepository.getUserPosts(userId).listen(
      (posts) {
        _userPosts = posts;
        _setLoading(false);
        notifyListeners();
      },
      onError: (e) {
        _setError(e.toString());
        _setLoading(false);
      },
    );
  }
  
  // Iniciar escucha de publicaciones pendientes (para moderadores)
  void initPendingPosts() {
    _setLoading(true);
    
    _postRepository.getPendingApprovalPosts().listen(
      (posts) {
        _pendingPosts = posts;
        _setLoading(false);
        notifyListeners();
      },
      onError: (e) {
        _setError(e.toString());
        _setLoading(false);
      },
    );
  }
  
  // Iniciar escucha de publicaciones reportadas (para moderadores)
  void initReportedPosts() {
    _setLoading(true);
    
    _postRepository.getReportedPosts().listen(
      (posts) {
        _reportedPosts = posts;
        _setLoading(false);
        notifyListeners();
      },
      onError: (e) {
        _setError(e.toString());
        _setLoading(false);
      },
    );
  }
  
  // Iniciar escucha de comentarios para un post específico
  void initPostComments(String postId) {
    _currentPostId = postId;
    _setLoading(true);
    
    _postRepository.getPostComments(postId).listen(
      (comments) {
        _comments = comments;
        _setLoading(false);
        notifyListeners();
      },
      onError: (e) {
        _setError(e.toString());
        _setLoading(false);
      },
    );
  }
  
  // Crear una nueva publicación
Future<bool> createPost({
  required String userId,
  required String content,
  List<File>? mediaFiles,
  List<String>? tags,
}) async {
  _isCreatingPost = true;
  _error = null;
  notifyListeners();
  
  try {
    // Obtener datos del usuario
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final user = UserModel.fromFirestore(userDoc);
    
    // Convertir imágenes a base64 si existen
    List<String> mediaBase64 = [];
    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      // Limitar a máximo 3 imágenes para evitar exceder límites de Firestore
      final filesToProcess = mediaFiles.take(3).toList();
      
      for (final file in filesToProcess) {
        final base64String = await ImageUtility.imageFileToBase64(
          file,
          quality: 50, // Mayor compresión para fotos de post
        );
        mediaBase64.add(base64String);
      }
    }
    
    // Crear documento de la publicación
    final postId = Uuid().v4();
    final post = {
      'authorId': userId,
      'authorUsername': user.username,
      'authorAvatarBase64': user.avatarBase64,
      'content': content,
      'mediaBase64': mediaBase64,
      'tags': tags ?? [],
      'likesCount': 0,
      'dislikesCount': 0,
      'likedBy': [],
      'dislikedBy': [],
      'commentsCount': 0,
      'reportsCount': 0,
      'reportedBy': [],
      'isApproved': mediaBase64.isEmpty, // Auto-aprobar si no contiene media
      'isHidden': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    // Guardar en Firestore
    await _firestore.collection('posts').doc(postId).set(post);
    
    _isCreatingPost = false;
    notifyListeners();
    return true;
  } catch (e) {
    _setError(e.toString());
    _isCreatingPost = false;
    notifyListeners();
    return false;
  }
}
  // Aprobar una publicación (para moderadores)
  Future<bool> approvePost(String postId) async {
    _setLoading(true);
    
    try {
      await _postRepository.approvePost(postId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  // Ocultar una publicación (para moderadores)
  Future<bool> hidePost(String postId) async {
    _setLoading(true);
    
    try {
      await _postRepository.hidePost(postId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  // Mostrar una publicación oculta (para moderadores)
  Future<bool> unhidePost(String postId) async {
    _setLoading(true);
    
    try {
      await _postRepository.unhidePost(postId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  // Reportar una publicación
  Future<bool> reportPost(String postId, String userId) async {
    try {
      await _postRepository.reportPost(postId, userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }
  
  // Dar like a una publicación
  Future<bool> likePost(String postId, String userId) async {
    try {
      await _postRepository.reactToPost(postId, userId, true);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Dar like a un comentario
  Future<bool> likeComment(String postId, String userId) async {
    try {
      await _postRepository.reactToPost(postId, userId, true);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }
  
  // Dar dislike a un comentario
  Future<bool> dislikeComment(String postId, String userId) async {
    try {
      await _postRepository.reactToPost(postId, userId, true);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }
  
  // Dar dislike a una publicación
  Future<bool> dislikePost(String postId, String userId) async {
    try {
      await _postRepository.reactToPost(postId, userId, false);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }
  
  // Eliminar reacción a una publicación
  Future<bool> removeReaction(String postId, String userId) async {
    try {
      await _postRepository.removeReactionFromPost(postId, userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }
  
  // Crear un comentario
  Future<bool> createComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    _setLoading(true);
    
    try {
      await _postRepository.createComment(
        postId: postId,
        userId: userId,
        content: content,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  // Reportar un comentario
  Future<bool> reportComment(String commentId, String userId) async {
    try {
      await _postRepository.reportComment(commentId, userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }
  
  // Ocultar un comentario (para moderadores)
  Future<bool> hideComment(String commentId) async {
    try {
      await _postRepository.hideComment(commentId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }
  
  // Buscar publicaciones
  Future<void> searchPosts(String query) async {
    if (query.isEmpty) {
      _isSearching = false;
      _searchQuery = '';
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    _isSearching = true;
    _searchQuery = query;
    _setLoading(true);
    notifyListeners();
    
    try {
      // Primero intentar buscar por etiqueta
      if (query.startsWith('#')) {
        final tag = query.substring(1);
        _searchResults = await _postRepository.searchPostsByTag(tag);
      } else {
        // Buscar por contenido
        _searchResults = await _postRepository.searchPostsByContent(query);
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
    }
  }
  
  // Cancelar búsqueda
  void cancelSearch() {
    _isSearching = false;
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
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