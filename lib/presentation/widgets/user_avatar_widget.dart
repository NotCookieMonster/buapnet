// lib/presentation/widgets/user_avatar_widget.dart

import 'package:flutter/material.dart';
import 'package:buapnet/services/image_service.dart';

class UserAvatarWidget extends StatelessWidget {
  final String? base64Image;
  final String username;
  final double radius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  
  const UserAvatarWidget({
    Key? key,
    required this.username,
    this.base64Image,
    this.radius = 24.0,
    this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color bgColor = backgroundColor ?? theme.colorScheme.primary.withOpacity(0.2);
    
    // Verificar si tenemos una imagen válida en Base64
    final imageService = ImageService();
    final String cacheKey = '${username}_avatar';
    final ImageProvider? imageProvider = (base64Image != null && base64Image!.isNotEmpty)
        ? imageService.decodeBase64Image(base64Image, cacheKey: cacheKey)
        : null;
    
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: imageProvider,
      onBackgroundImageError: imageProvider != null
          ? (exception, stackTrace) {
              debugPrint('Error loading avatar image: $exception');
            }
          : null,
      child: imageProvider == null
          ? Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            )
          : null,
    );
    
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }
    
    return avatar;
  }
}