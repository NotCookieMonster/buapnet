import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorUsername;
  final String authorAvatarBase64;
  final String content;
  final List<String> mediaBase64;
  final List<String> tags;
  final int likesCount;
  final int dislikesCount;
  final List<String> likedBy;
  final List<String> dislikedBy;
  final int commentsCount;
  final int reportsCount;
  final List<String> reportedBy;
  final bool isApproved;
  final bool isHidden;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  PostModel({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.authorAvatarBase64,
    required this.content,
    this.mediaBase64 = const [],
    this.tags = const [],
    this.likesCount = 0,
    this.dislikesCount = 0,
    this.likedBy = const [],
    this.dislikedBy = const [],
    this.commentsCount = 0,
    this.reportsCount = 0,
    this.reportedBy = const [],
    this.isApproved = false,
    this.isHidden = false,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Método para convertir un documento de Firestore a PostModel
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorUsername: data['authorUsername'] ?? '',
      authorAvatarBase64: data['authorAvatarBase64'] ?? '',
      content: data['content'] ?? '',
      mediaBase64: List<String>.from(data['mediaBase64'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      likesCount: data['likesCount'] ?? 0,
      dislikesCount: data['dislikesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      dislikedBy: List<String>.from(data['dislikedBy'] ?? []),
      commentsCount: data['commentsCount'] ?? 0,
      reportsCount: data['reportsCount'] ?? 0,
      reportedBy: List<String>.from(data['reportedBy'] ?? []),
      isApproved: data['isApproved'] ?? false,
      isHidden: data['isHidden'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  // Método para convertir PostModel a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorAvatarBase64': authorAvatarBase64,
      'content': content,
      'mediaBase64': mediaBase64,
      'tags': tags,
      'likesCount': likesCount,
      'dislikesCount': dislikesCount,
      'likedBy': likedBy,
      'dislikedBy': dislikedBy,
      'commentsCount': commentsCount,
      'reportsCount': reportsCount,
      'reportedBy': reportedBy,
      'isApproved': isApproved,
      'isHidden': isHidden,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  // Método para marcar como aprobado
  PostModel copyWithApproved({
    bool approved = true,
  }) {
    return PostModel(
      id: this.id,
      authorId: this.authorId,
      authorUsername: this.authorUsername,
      authorAvatarBase64: this.authorAvatarBase64,
      content: this.content,
      mediaBase64: this.mediaBase64,
      tags: this.tags,
      likesCount: this.likesCount,
      dislikesCount: this.dislikesCount,
      likedBy: this.likedBy,
      dislikedBy: this.dislikedBy,
      commentsCount: this.commentsCount,
      reportsCount: this.reportsCount,
      reportedBy: this.reportedBy,
      isApproved: approved,
      isHidden: this.isHidden,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
  
  // Método para ocultar/mostrar la publicación
  PostModel copyWithVisibility({
    required bool hidden,
  }) {
    return PostModel(
      id: this.id,
      authorId: this.authorId,
      authorUsername: this.authorUsername,
      authorAvatarBase64: this.authorAvatarBase64,
      content: this.content,
      mediaBase64: this.mediaBase64,
      tags: this.tags,
      likesCount: this.likesCount,
      dislikesCount: this.dislikesCount,
      likedBy: this.likedBy,
      dislikedBy: this.dislikedBy,
      commentsCount: this.commentsCount,
      reportsCount: this.reportsCount,
      reportedBy: this.reportedBy,
      isApproved: this.isApproved,
      isHidden: hidden,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
  
  // Método para actualizar likes/dislikes
  PostModel copyWithReaction({
    String? userId,
    bool? isLike,
  }) {
    if (userId == null || isLike == null) {
      return this;
    }
    
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
    
    return PostModel(
      id: this.id,
      authorId: this.authorId,
      authorUsername: this.authorUsername,
      authorAvatarBase64: this.authorAvatarBase64,
      content: this.content,
      mediaBase64: this.mediaBase64,
      tags: this.tags,
      likesCount: newLikedBy.length,
      dislikesCount: newDislikedBy.length,
      likedBy: newLikedBy,
      dislikedBy: newDislikedBy,
      commentsCount: this.commentsCount,
      reportsCount: this.reportsCount,
      reportedBy: this.reportedBy,
      isApproved: this.isApproved,
      isHidden: this.isHidden,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
  
  // Método para registrar un reporte
  PostModel copyWithReport({
    required String userId,
  }) {
    List<String> newReportedBy = List.from(reportedBy);
    
    // Verificar si el usuario ya ha reportado
    if (!newReportedBy.contains(userId)) {
      newReportedBy.add(userId);
    }
    
    final newReportsCount = newReportedBy.length;
    final newIsHidden = newReportsCount >= 20 ? true : this.isHidden;
    
    return PostModel(
      id: this.id,
      authorId: this.authorId,
      authorUsername: this.authorUsername,
      authorAvatarBase64: this.authorAvatarBase64,
      content: this.content,
      mediaBase64: this.mediaBase64,
      tags: this.tags,
      likesCount: this.likesCount,
      dislikesCount: this.dislikesCount,
      likedBy: this.likedBy,
      dislikedBy: this.dislikedBy,
      commentsCount: this.commentsCount,
      reportsCount: newReportsCount,
      reportedBy: newReportedBy,
      isApproved: this.isApproved,
      isHidden: newIsHidden,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
  
  // Para depuración
  @override
  String toString() {
    return 'PostModel(id: $id, author: $authorUsername, likes: $likesCount, dislikes: $dislikesCount, comments: $commentsCount, reports: $reportsCount)';
  }
}