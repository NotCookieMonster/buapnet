// lib/services/image_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';

class ImageService {
  // Singleton pattern
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  // Cache optimization
  final Map<String, ImageProvider> _imageCache = {};
  
  /// Converts a File to Base64 with optimization
  Future<String> encodeImageToBase64(File file, {
    int quality = 70,
    int maxWidth = 800,
    int maxHeight = 800,
    String format = 'jpeg', // 'jpeg', 'png', 'webp'
  }) async {
    try {
      // Calculate initial size for logging/debugging
      final initialSizeKB = file.lengthSync() ~/ 1024;
      
      // Apply compression
      final Uint8List? compressedImage = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: format == 'png' 
            ? CompressFormat.png 
            : (format == 'webp' ? CompressFormat.webp : CompressFormat.jpeg),
      );
      
      if (compressedImage == null) {
        throw Exception('Image compression failed');
      }
      
      // Validate size for Firestore limitations (1MB per document)
      final compressedSizeKB = compressedImage.length ~/ 1024;
      
      // Log compression results for debugging
      debugPrint('Image compression: $initialSizeKB KB -> $compressedSizeKB KB');
      
      if (compressedSizeKB > 750) { 
        // Further compress if still too large
        return _applyAdaptiveCompression(compressedImage, format);
      }
      
      // Convert to base64
      final String base64String = base64Encode(compressedImage);
      return base64String;
    } catch (e) {
      debugPrint('Error processing image: $e');
      rethrow;
    }
  }
  
  /// Applies progressive compression to ensure size limits
  Future<String> _applyAdaptiveCompression(Uint8List imageData, String format) async {
    Uint8List result = imageData;
    int quality = 60; // Start with lower quality
    
    while (result.length > 750 * 1024 && quality > 10) {
      // Create in-memory compressed version
      final compressed = await FlutterImageCompress.compressWithList(
        result,
        quality: quality,
        format: format == 'png' 
            ? CompressFormat.png 
            : (format == 'webp' ? CompressFormat.webp : CompressFormat.jpeg),
      );
      
      // No need to check for null as compressWithList does not return null
      
      result = compressed;
      quality -= 10; // Reduce quality progressively
    }
    
    return base64Encode(result);
  }

  /// Decodes Base64 to ImageProvider with caching
  ImageProvider? decodeBase64Image(String? base64String, {String cacheKey = ''}) {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }
    
    // Use cache key or generate from data hash
    final String key = cacheKey.isNotEmpty 
        ? cacheKey 
        : base64String.hashCode.toString();
    
    // Return cached version if available
    if (_imageCache.containsKey(key)) {
      return _imageCache[key];
    }
    
    try {
      final Uint8List bytes = base64Decode(base64String);
      final ImageProvider imageProvider = MemoryImage(bytes);
      
      // Store in cache
      _imageCache[key] = imageProvider;
      
      return imageProvider;
    } catch (e) {
      debugPrint('Error decoding Base64 image: $e');
      return null;
    }
  }
  
  /// Clears image cache to free memory
  void clearCache() {
    _imageCache.clear();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
  
  /// Resizes cache to specified size
  void resizeCache(int maxEntries) {
    if (_imageCache.length > maxEntries) {
      final keysToRemove = _imageCache.keys.toList().sublist(0, _imageCache.length - maxEntries);
      for (final key in keysToRemove) {
        _imageCache.remove(key);
      }
    }
  }
}