import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:buapnet/data/models/post_model.dart';
import 'package:buapnet/presentation/providers/post_provider.dart';
import 'package:buapnet/presentation/widgets/user_avatar_widget.dart';
import 'package:buapnet/presentation/widgets/base64_image_widget.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final VoidCallback onTap;
  final bool showFullContent;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onTap,
    this.showFullContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    // Verificar si el usuario actual ha dado like o dislike
    final bool hasLiked = post.likedBy.contains(currentUserId);
    final bool hasDisliked = post.dislikedBy.contains(currentUserId);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con avatar y nombre de usuario
              Row(
                children: [
                  // Avatar
                  UserAvatarWidget(
                    username: post.authorUsername,
                    base64Image: post.authorAvatarBase64,
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  
                  // Información del autor y timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorUsername,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          timeago.format(post.createdAt, locale: 'es'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Menú de opciones
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'report') {
                        _showReportDialog(context, postProvider);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag, size: 20),
                            SizedBox(width: 8),
                            Text('Reportar'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Contenido del post
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  post.content,
                  style: theme.textTheme.bodyLarge,
                  maxLines: showFullContent ? null : 5,
                  overflow: showFullContent ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              ),
              
              // Tags
              if (post.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: post.tags.map((tag) {
                    return Chip(
                      label: Text('#$tag'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    );
                  }).toList(),
                ),
              
              // Imágenes
              if (post.mediaBase64.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildMediaGrid(post.mediaBase64, context),
              ],
              
              const Divider(),
              
              // Barra de interacciones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Like
                  _buildInteractionButton(
                    icon: hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    label: '${post.likesCount}',
                    color: hasLiked ? theme.colorScheme.primary : null,
                    onTap: () {
                      if (hasLiked) {
                        postProvider.removeReaction(post.id, currentUserId);
                      } else {
                        postProvider.likePost(post.id, currentUserId);
                      }
                    },
                  ),
                  
                  // Dislike
                  _buildInteractionButton(
                    icon: hasDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                    label: '${post.dislikesCount}',
                    color: hasDisliked ? theme.colorScheme.error : null,
                    onTap: () {
                      if (hasDisliked) {
                        postProvider.removeReaction(post.id, currentUserId);
                      } else {
                        postProvider.dislikePost(post.id, currentUserId);
                      }
                    },
                  ),
                  
                  // Comentarios
                  _buildInteractionButton(
                    icon: Icons.chat_bubble_outline,
                    label: '${post.commentsCount}',
                    onTap: onTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Construir un botón de interacción (like, dislike, comentario)
  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
  
  // Construir grid de imágenes
  Widget _buildMediaGrid(List<String> mediaBase64List, BuildContext context) {
    if (mediaBase64List.isEmpty) return const SizedBox();
    
    // Si hay una sola imagen
    if (mediaBase64List.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Base64ImageWidget(
          base64String: mediaBase64List.first,
          cacheKey: 'post_${post.id}_image_0',
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    }
    
    // Si hay múltiples imágenes, usar un grid
    return StaggeredGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: mediaBase64List.take(4).map((base64String) {
        // Indicar si hay más imágenes no mostradas
        final bool isLastVisible = base64String == mediaBase64List[3] && mediaBase64List.length > 4;
        final int remainingCount = mediaBase64List.length - 4;
        
        return StaggeredGridTile.count(
          crossAxisCellCount: 1,
          mainAxisCellCount: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Imagen base64
                Base64ImageWidget(
                  base64String: base64String,
                  cacheKey: 'post_${post.id}_image_${mediaBase64List.indexOf(base64String)}',
                  fit: BoxFit.cover,
                ),
                
                // Overlay para imágenes adicionales
                if (isLastVisible)
                  Container(
                    color: Colors.black.withOpacity(0.6),
                    child: Center(
                      child: Text(
                        '+$remainingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  // Mostrar diálogo de confirmación para reportar
  void _showReportDialog(BuildContext context, PostProvider postProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reportar publicación'),
          content: const Text(
            '¿Estás seguro que deseas reportar esta publicación? Un moderador la revisará para determinar si viola las normas de la comunidad.',
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
                postProvider.reportPost(post.id, currentUserId).then((success) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Publicación reportada correctamente'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          postProvider.error ?? 'Error al reportar publicación',
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