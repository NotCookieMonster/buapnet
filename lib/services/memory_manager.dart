// lib/services/memory_manager.dart

import 'package:flutter/material.dart';
import 'package:buapnet/services/image_service.dart';

class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();
  
  final ImageService _imageService = ImageService();
  
  // Llamar periódicamente para gestionar memoria
  void manageMemory(BuildContext context) {
    // Obtener información sobre el uso de memoria del dispositivo
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final pixelRatio = mediaQuery.devicePixelRatio;
    
    // Calcular memoria aproximada disponible (heurística)
    final screenPixels = screenWidth * screenHeight * pixelRatio * pixelRatio;
    final isHighEndDevice = screenPixels > 2000000; // Aproximadamente 2MP
    
    // Ajustar caché según dispositivo
    final maxCacheEntries = isHighEndDevice ? 50 : 20;
    _imageService.resizeCache(maxCacheEntries);
    
    // Limpiar caché de imágenes no utilizadas
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      _imageService.clearCache();
    }
  }
}