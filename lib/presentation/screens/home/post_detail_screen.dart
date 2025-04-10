import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:buapnet/data/models/post_model.dart';
import 'package:buapnet/data/models/comment_model.dart';
import 'package:buapnet/presentation/providers/auth_provider.dart';
import 'package:buapnet/presentation/providers/post_provider.dart';
import 'package:buapnet/presentation/widgets/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  PostModel? _post;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Iniciar carga de comentarios
      Provider.of<PostProvider>(context, listen: false)
          .initPostComments(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Encontrar el post actual en el feed
  void _findCurrentPost() {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    // Buscar el post en las diferentes listas
    _post = postProvider.posts.firstWhere(
      (post) => post.id == widget.postId,
      orElse: () => postProvider.userPosts.firstWhere(
        (post) => post.id == widget.postId,
        orElse: () => postProvider.searchResults.firstWhere(
          (post) => post.id == widget.postId,
          orElse: () => _post ?? PostModel(
            id: widget.postId,
            authorId: '',
            authorUsername: '',
            authorAvatarBase64: '',
            content: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ),
    );
  }

  // Enviar un comentario
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    final success = await postProvider.createComment(
      postId: widget.postId,
      userId: userId,
      content: _commentController.text.trim(),
    );

    setState(() {
      _isSubmittingComment = false;
    });

    if (success && mounted) {
      _commentController.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(postProvider.error ?? 'Error al enviar el comentario'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final theme = Theme.of(context);
    
    // Encontrar el post actual
    _findCurrentPost();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicación'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Publicación
          if (_post != null)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  // Mostrar la publicación con contenido completo
                  PostCard(
                    post: _post!,
                    currentUserId: authProvider.user?.uid ?? '',
                    onTap: () {},
                    showFullContent: true,
                  ),
                  
                  // Sección de comentarios
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Comentarios (${_post!.commentsCount})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Lista de comentarios
                  if (postProvider.isLoading && postProvider.comments.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (postProvider.comments.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No hay comentarios. ¡Sé el primero en comentar!'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: postProvider.comments.length,
                      itemBuilder: (context, index) {
                        return _buildCommentItem(
                          postProvider.comments[index],
                          authProvider.user?.uid ?? '',
                          postProvider,
                        );
                      },
                    ),
                ],
              ),
            )
          else if (postProvider.isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  'No se encontró la publicación',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          
          // Campo para comentar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  backgroundImage: authProvider.user?.avatarBase64 != null && 
                                  authProvider.user!.avatarBase64.isNotEmpty
                      ? NetworkImage(authProvider.user!.avatarBase64)
                      : null,
                  child: authProvider.user?.avatarBase64 == null || 
                         authProvider.user!.avatarBase64.isEmpty
                      ? Text(
                          authProvider.user?.username != null && 
                          authProvider.user!.username.isNotEmpty
                              ? authProvider.user!.username[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                IconButton(
                  icon: _isSubmittingComment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isSubmittingComment ? null : _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construir un item de comentario
  Widget _buildCommentItem(
    CommentModel comment,
    String currentUserId,
    PostProvider postProvider,
  ) {
    final theme = Theme.of(context);
    final bool hasLiked = comment.likedBy.contains(currentUserId);
    final bool hasDisliked = comment.dislikedBy.contains(currentUserId);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            backgroundImage: comment.authorAvatarBase64.isNotEmpty
                ? CachedNetworkImageProvider(comment.authorAvatarBase64)
                : null,
            child: comment.authorAvatarBase64.isEmpty
                ? Text(
                    comment.authorUsername.isNotEmpty
                        ? comment.authorUsername[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          
          // Contenido del comentario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado del comentario
                Row(
                  children: [
                    Text(
                      comment.authorUsername,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        timeago.format(comment.createdAt, locale: 'es'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Menú de opciones
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      onSelected: (value) {
                        if (value == 'report') {
                          _showReportCommentDialog(context, comment.id, currentUserId, postProvider);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag, size: 18),
                              SizedBox(width: 8),
                              Text('Reportar'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Contenido
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(comment.content),
                ),
                
                // Barra de interacciones
                Row(
                  children: [
                    // Like
                    InkWell(
                      onTap: () {
                        if (hasLiked) {
                          // TODO: Implementar quitar like
                        } else {
                          postProvider.likeComment(comment.id, currentUserId);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            Icon(
                              hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                              size: 14,
                              color: hasLiked ? theme.colorScheme.primary : null,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${comment.likesCount}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Dislike
                    InkWell(
                      onTap: () {
                        if (hasDisliked) {
                          // TODO: Implementar quitar dislike
                        } else {
                          postProvider.dislikeComment(comment.id, currentUserId);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            Icon(
                              hasDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                              size: 14,
                              color: hasDisliked ? theme.colorScheme.error : null,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${comment.dislikesCount}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Mostrar diálogo de confirmación para reportar comentario
  void _showReportCommentDialog(
    BuildContext context,
    String commentId,
    String userId,
    PostProvider postProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reportar comentario'),
          content: const Text(
            '¿Estás seguro que deseas reportar este comentario? Un moderador lo revisará para determinar si viola las normas de la comunidad.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                postProvider.reportComment(commentId, userId).then((success) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Comentario reportado correctamente'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          postProvider.error ?? 'Error al reportar comentario',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                });
              },
              child: const Text('Reportar'),
            ),
          ],
        );
      },
    );
  }
}