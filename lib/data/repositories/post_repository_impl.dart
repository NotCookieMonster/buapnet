import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:buapnet/data/models/post_model.dart';
import 'package:buapnet/data/models/comment_model.dart';
import 'package:buapnet/data/models/user_model.dart';
import 'package:buapnet/services/image_service.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageService _imageService = ImageService();
  final Uuid _uuid = const Uuid();
  
  // Referencias a colecciones
  CollectionReference get _postsCollection => _firestore.collection('posts');
  CollectionReference get _commentsCollection => _firestore.collection('comments');
  CollectionReference get _usersCollection => _firestore.collection('users');
  
  // Crear una nueva publicación
  Future<PostModel> createPost({
    required String userId,
    required String content,
    List<File>? mediaFiles,
    List<String>? tags,
  }) async {
    try {
      // Obtener datos del usuario
      final userDoc = await _usersCollection.doc(userId).get();
      final user = UserModel.fromFirestore(userDoc);
      
      // Convertir imágenes a base64 si existen
      List<String> mediaBase64 = [];
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        // Limitar a máximo 3 imágenes para evitar exceder el límite de 1MB
        final filesToProcess = mediaFiles.length > 3 
            ? mediaFiles.sublist(0, 3) 
            : mediaFiles;
        
        for (final file in filesToProcess) {
          final base64String = await _imageService.encodeImageToBase64(
            file,
            quality: 50, // Mayor compresión para fotos de post
            format: 'jpeg', // Usar JPEG para mejor compresión
          );
          mediaBase64.add(base64String);
        }
      }
      
      // Determinar si la publicación requiere aprobación
      bool requiresApproval = mediaBase64.isNotEmpty;
      
      // Crear documento de la publicación
      final postId = _uuid.v4();
      final post = PostModel(
        id: postId,
        authorId: userId,
        authorUsername: user.username,
        authorAvatarBase64: user.avatarBase64,
        content: content,
        mediaBase64: mediaBase64,
        tags: tags ?? [],
        isApproved: !requiresApproval, // Auto-aprobar si no contiene media
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Guardar en Firestore
      await _postsCollection.doc(postId).set(post.toMap());
      
      return post;
    } catch (e) {
      rethrow;
    }
  }
  
  // Obtener feed de publicaciones (más recientes primero)
  Stream<List<PostModel>> getPostsFeed() {
    return _postsCollection
        .where('isHidden', isEqualTo: false) // Solo publicaciones no ocultas
        .where('isApproved', isEqualTo: true) // Solo publicaciones aprobadas
        .orderBy('createdAt', descending: true) // Más recientes primero
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
        });
  }
  
  // Obtener publicaciones pendientes de aprobación (para moderadores)
  Stream<List<PostModel>> getPendingApprovalPosts() {
    return _postsCollection
        .where('isApproved', isEqualTo: false)
        .where('isHidden', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
        });
  }
  
  // Obtener publicaciones reportadas (para moderadores)
  Stream<List<PostModel>> getReportedPosts() {
    return _postsCollection
        .where('reportsCount', isGreaterThan: 0)
        .orderBy('reportsCount', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
        });
  }
  
  // Buscar publicaciones por tag
  Future<List<PostModel>> searchPostsByTag(String tag) async {
    final querySnapshot = await _postsCollection
        .where('tags', arrayContains: tag)
        .where('isHidden', isEqualTo: false)
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
    
    return querySnapshot.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .toList();
  }
  
  // Buscar publicaciones por contenido
  Future<List<PostModel>> searchPostsByContent(String query) async {
    // Firestore no soporta búsqueda de texto completo nativa
    // Esta es una implementación simple que busca coincidencias exactas
    // En una app de producción, se recomienda usar Algolia o similar
    final querySnapshot = await _postsCollection
        .where('isHidden', isEqualTo: false)
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
    
    final queryLower = query.toLowerCase();
    return querySnapshot.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .where((post) => 
            post.content.toLowerCase().contains(queryLower) || 
            post.tags.any((tag) => tag.toLowerCase().contains(queryLower)))
        .toList();
  }
  
  // Aprobar una publicación (para moderadores)
  Future<void> approvePost(String postId) async {
    await _postsCollection.doc(postId).update({
      'isApproved': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Ocultar una publicación (para moderadores)
  Future<void> hidePost(String postId) async {
    await _postsCollection.doc(postId).update({
      'isHidden': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Mostrar una publicación oculta (para moderadores)
  Future<void> unhidePost(String postId) async {
    await _postsCollection.doc(postId).update({
      'isHidden': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Reportar una publicación
  Future<void> reportPost(String postId, String userId) async {
    final postDoc = await _postsCollection.doc(postId).get();
    final post = PostModel.fromFirestore(postDoc);
    
    final updatedPost = post.copyWithReport(userId: userId);
    
    await _postsCollection.doc(postId).update({
      'reportsCount': updatedPost.reportsCount,
      'reportedBy': updatedPost.reportedBy,
      'isHidden': updatedPost.isHidden,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Dar like/dislike a una publicación
  Future<void> reactToPost(String postId, String userId, bool isLike) async {
    final postDoc = await _postsCollection.doc(postId).get();
    final post = PostModel.fromFirestore(postDoc);
    
    final updatedPost = post.copyWithReaction(
      userId: userId, 
      isLike: isLike,
    );
    
    await _postsCollection.doc(postId).update({
      'likesCount': updatedPost.likesCount,
      'dislikesCount': updatedPost.dislikesCount,
      'likedBy': updatedPost.likedBy,
      'dislikedBy': updatedPost.dislikedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Eliminar reacción a una publicación
  Future<void> removeReactionFromPost(String postId, String userId) async {
    final postDoc = await _postsCollection.doc(postId).get();
    final post = PostModel.fromFirestore(postDoc);
    
    List<String> newLikedBy = List.from(post.likedBy);
    List<String> newDislikedBy = List.from(post.dislikedBy);
    
    newLikedBy.remove(userId);
    newDislikedBy.remove(userId);
    
    await _postsCollection.doc(postId).update({
      'likesCount': newLikedBy.length,
      'dislikesCount': newDislikedBy.length,
      'likedBy': newLikedBy,
      'dislikedBy': newDislikedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Crear un comentario en una publicación
  Future<CommentModel> createComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      // Obtener datos del usuario
      final userDoc = await _usersCollection.doc(userId).get();
      final user = UserModel.fromFirestore(userDoc);
      
      // Crear documento del comentario
      final commentId = _uuid.v4();
      final comment = CommentModel(
        id: commentId,
        postId: postId,
        authorId: userId,
        authorUsername: user.username,
        authorAvatarBase64: user.avatarBase64,
        content: content,
        createdAt: DateTime.now(),
      );
      
      // Guardar en Firestore
      await _commentsCollection.doc(commentId).set(comment.toMap());
      
      // Actualizar contador de comentarios en el post
      await _postsCollection.doc(postId).update({
        'commentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return comment;
    } catch (e) {
      rethrow;
    }
  }
  
  // Obtener comentarios de una publicación
  Stream<List<CommentModel>> getPostComments(String postId) {
    return _commentsCollection
        .where('postId', isEqualTo: postId)
        .where('isHidden', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList();
        });
  }
  
  // Reportar un comentario
  Future<void> reportComment(String commentId, String userId) async {
    final commentDoc = await _commentsCollection.doc(commentId).get();
    final comment = CommentModel.fromFirestore(commentDoc);
    
    final updatedComment = comment.copyWithReport(userId: userId);
    
    await _commentsCollection.doc(commentId).update({
      'reportsCount': updatedComment.reportsCount,
      'reportedBy': updatedComment.reportedBy,
      'isHidden': updatedComment.isHidden,
    });
  }
  
  // Ocultar un comentario (para moderadores)
  Future<void> hideComment(String commentId) async {
    await _commentsCollection.doc(commentId).update({
      'isHidden': true,
    });
  }
  
  // Dar like/dislike a un comentario
  Future<void> reactToComment(String commentId, String userId, bool isLike) async {
    final commentDoc = await _commentsCollection.doc(commentId).get();
    final comment = CommentModel.fromFirestore(commentDoc);
    
    final updatedComment = comment.copyWithReaction(
      userId: userId, 
      isLike: isLike,
    );
    
    await _commentsCollection.doc(commentId).update({
      'likesCount': updatedComment.likesCount,
      'dislikesCount': updatedComment.dislikesCount,
      'likedBy': updatedComment.likedBy,
      'dislikedBy': updatedComment.dislikedBy,
    });
  }
  
  // Obtener publicaciones de un usuario específico
  Stream<List<PostModel>> getUserPosts(String userId) {
    return _postsCollection
        .where('authorId', isEqualTo: userId)
        .where('isHidden', isEqualTo: false)
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
        });
  }
}