import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorUsername;
  final String authorAvatarBase64;
  final String content;
  final int likesCount;
  final int dislikesCount;
  final List<String> likedBy;
  final List<String> dislikedBy;
  final int reportsCount;
  final List<String> reportedBy;
  final bool isHidden;
  final DateTime createdAt;
  
  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorUsername,
    required this.authorAvatarBase64,
    required this.content,
    this.likesCount = 0,
    this.dislikesCount = 0,
    this.likedBy = const [],
    this.dislikedBy = const [],
    this.reportsCount = 0,
    this.reportedBy = const [],
    this.isHidden = false,
    required this.createdAt,
  });
  
  // Método para convertir un documento de Firestore a CommentModel
  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CommentModel(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorUsername: data['authorUsername'] ?? '',
      authorAvatarBase64: data['authorAvatarBase64'] ?? '',
      content: data['content'] ?? '',
      likesCount: data['likesCount'] ?? 0,
      dislikesCount: data['dislikesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      dislikedBy: List<String>.from(data['dislikedBy'] ?? []),
      reportsCount: data['reportsCount'] ?? 0,
      reportedBy: List<String>.from(data['reportedBy'] ?? []),
      isHidden: data['isHidden'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
  
  // Método para convertir CommentModel a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorAvatarBase64': authorAvatarBase64,
      'content': content,
      'likesCount': likesCount,
      'dislikesCount': dislikesCount,
      'likedBy': likedBy,
      'dislikedBy': dislikedBy,
      'reportsCount': reportsCount,
      'reportedBy': reportedBy,
      'isHidden': isHidden,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
  
  // Método para actualizar likes/dislikes
  CommentModel copyWithReaction({
    required String userId,
    required bool isLike,
  }) {
    List<String> newLikedBy = List.from(likedBy);
    List<String> newDislikedBy = List.from(dislikedBy);
    
    // Remover el usuario de ambas listas primero
    newLikedBy.remove(userId);
    newDislikedBy.remove(userId);
    
    // Agregar a la lista correspondiente
    if (isLike) {
      newLikedBy.add(userId);
    } else {
      newDislikedBy.add(userId);
    }
    
    return CommentModel(
      id: this.id,
      postId: this.postId,
      authorId: this.authorId,
      authorUsername: this.authorUsername,
      authorAvatarBase64: this.authorAvatarBase64,
      content: this.content,
      likesCount: newLikedBy.length,
      dislikesCount: newDislikedBy.length,
      likedBy: newLikedBy,
      dislikedBy: newDislikedBy,
      reportsCount: this.reportsCount,
      reportedBy: this.reportedBy,
      isHidden: this.isHidden,
      createdAt: this.createdAt,
    );
  }
  
  // Método para registrar un reporte
  CommentModel copyWithReport({
    required String userId,
  }) {
    List<String> newReportedBy = List.from(reportedBy);
    
    // Verificar si el usuario ya ha reportado
    if (!newReportedBy.contains(userId)) {
      newReportedBy.add(userId);
    }
    
    final newReportsCount = newReportedBy.length;
    final newIsHidden = newReportsCount >= 20 ? true : this.isHidden;
    
    return CommentModel(
      id: this.id,
      postId: this.postId,
      authorId: this.authorId,
      authorUsername: this.authorUsername,
      authorAvatarBase64: this.authorAvatarBase64,
      content: this.content,
      likesCount: this.likesCount,
      dislikesCount: this.dislikesCount,
      likedBy: this.likedBy,
      dislikedBy: this.dislikedBy,
      reportsCount: newReportsCount,
      reportedBy: newReportedBy,
      isHidden: newIsHidden,
      createdAt: this.createdAt,
    );
  }
  
  // Método para ocultar/mostrar el comentario
  CommentModel copyWithVisibility({
    required bool hidden,
  }) {
    return CommentModel(
      id: this.id,
      postId: this.postId,
      authorId: this.authorId,
      authorUsername: this.authorUsername,
      authorAvatarBase64: this.authorAvatarBase64,
      content: this.content,
      likesCount: this.likesCount,
      dislikesCount: this.dislikesCount,
      likedBy: this.likedBy,
      dislikedBy: this.dislikedBy,
      reportsCount: this.reportsCount,
      reportedBy: this.reportedBy,
      isHidden: hidden,
      createdAt: this.createdAt,
    );
  }
  
  // Para depuración
  @override
  String toString() {
    return 'CommentModel(id: $id, postId: $postId, author: $authorUsername, likes: $likesCount, dislikes: $dislikesCount)';
  }
}