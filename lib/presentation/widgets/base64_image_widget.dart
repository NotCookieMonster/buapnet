// lib/presentation/widgets/base64_image_widget.dart

import 'package:flutter/material.dart';
import 'package:buapnet/services/image_service.dart';

class Base64ImageWidget extends StatelessWidget {
  final String? base64String;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String cacheKey;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  const Base64ImageWidget({
    Key? key,
    required this.base64String,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheKey = '',
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final imageService = ImageService();
    
    if (base64String == null || base64String!.isEmpty) {
      return _buildErrorWidget();
    }
    
    final imageProvider = imageService.decodeBase64Image(
      base64String,
      cacheKey: cacheKey,
    );
    
    if (imageProvider == null) {
      return _buildErrorWidget();
    }
    
    return Image(
      image: imageProvider,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return _buildPlaceholderWidget();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading image: $error');
        return _buildErrorWidget();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildPlaceholderWidget();
      },
    );
  }
  
  Widget _buildPlaceholderWidget() {
    if (placeholder != null) return placeholder!;
    
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    if (errorWidget != null) return errorWidget!;
    
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}