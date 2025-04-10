import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class ImageUtility {
  // Convierte un archivo de imagen a Base64 con compresión
  static Future<String> imageFileToBase64(File file, {int quality = 70, int maxWidth = 800, int maxHeight = 800}) async {
    try {
      // Comprimir imagen para reducir el tamaño
      final Uint8List? compressedImage = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
      );
      
      if (compressedImage == null) {
        throw Exception('Error al comprimir la imagen');
      }
      
      // Validar tamaño (Firestore tiene un límite de 1MB por documento)
      final int sizeInKB = compressedImage.length ~/ 1024;
      if (sizeInKB > 750) { // Mantenemos margen para otros datos
        throw Exception('La imagen es demasiado grande (${sizeInKB}KB). El máximo recomendado es 750KB.');
      }
      
      // Convertir a base64
      final String base64String = base64Encode(compressedImage);
      return base64String;
    } catch (e) {
      debugPrint('Error al procesar la imagen: $e');
      rethrow;
    }
  }

  static final Map<String, ImageProvider> _imageCache = {};
  
  // Convertir base64 a formato de imagen utilizable por widgets
  static ImageProvider? base64ToImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }
    final String cacheKey = base64String.hashCode.toString();

    if (_imageCache.containsKey(cacheKey)) {
    return _imageCache[cacheKey];
  }
    try {
      final Uint8List bytes = base64Decode(base64String);
      final ImageProvider imageProvider = MemoryImage(bytes);
      _imageCache[cacheKey] = imageProvider;

      return imageProvider;
    } catch (e) {
      debugPrint('Error al decodificar imagen base64: $e');
      return null;
    }
  }
  
  // Obtener imagen desde la cámara o galería y convertir a base64
  static Future<String?> pickImageAsBase64(ImageSource source, {int quality = 70}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: quality,
      );
      
      if (pickedFile == null) {
        return null;
      }
      
      final File file = File(pickedFile.path);
      return await imageFileToBase64(file);
    } catch (e) {
      debugPrint('Error al seleccionar imagen: $e');
      return null;
    }
  }
// Método para limpiar caché (llamar cuando sea necesario liberar memoria)
static void clearImageCache() {
  _imageCache.clear();
}

}

