// lib/presentation/providers/user_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:uuid/uuid.dart';
import 'package:buapnet/data/models/user_model.dart';
import 'package:buapnet/services/image_service.dart';

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageService _imageService = ImageService();
  final Uuid _uuid = const Uuid();
  
  UserModel? _userProfile;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Obtener perfil de un usuario
  Future<void> getUserProfile(String userId) async {
    _setLoading(true);
    _error = null;
    
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      
      if (docSnapshot.exists) {
        _userProfile = UserModel.fromFirestore(docSnapshot);
      } else {
        _setError('Usuario no encontrado');
      }
      
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }
  
  // Procesar y subir imagen de avatar
  Future<String?> processAndUpdateAvatar(File imageFile, String userId) async {
    _setLoading(true);
    _error = null;
    
    try {
      // Convertir a Base64 con compresión optimizada para avatares
      final base64Avatar = await _imageService.encodeImageToBase64(
        imageFile,
        quality: 60, // Mayor compresión para avatares
        maxWidth: 300,
        maxHeight: 300,
        format: 'jpeg', // JPEG ofrece mejor compresión
      );
      
      // Actualizar en Firestore directamente
      await _firestore.collection('users').doc(userId).update({
        'avatarBase64': base64Avatar,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Si el usuario actual es el que se está actualizando, actualizar modelo local
      if (_userProfile != null && _userProfile!.uid == userId) {
        _userProfile = _userProfile!.copyWith(avatarBase64: base64Avatar);
      }
      
      _setLoading(false);
      notifyListeners();
      return base64Avatar;
    } catch (e) {
      _setError('Error al procesar avatar: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }
  
  // Seleccionar y procesar avatar desde galería o cámara
  Future<String?> selectAndProcessAvatar(ImageSource source, String userId) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile == null) return null;
      
      // Recortar imagen para asegurar que sea cuadrada (ideal para avatares)
      final croppedFile = await _cropImage(File(pickedFile.path));
      
      if (croppedFile == null) return null;
      
      // Procesar y actualizar avatar
      return await processAndUpdateAvatar(croppedFile, userId);
    } catch (e) {
      _setError('Error al seleccionar imagen: ${e.toString()}');
      return null;
    }
  }
  
  // Recortar imagen para avatar (cuadrada)
  Future<File?> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 70, // Compresión inicial durante recorte
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar imagen',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Recortar imagen',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      
      return croppedFile != null ? File(croppedFile.path) : null;
    } catch (e) {
      _setError('Error al recortar imagen: ${e.toString()}');
      return null;
    }
  }
  
  // Eliminar avatar (establecer a vacío)
  Future<bool> removeAvatar(String userId) async {
    _setLoading(true);
    _error = null;
    
    try {
      // Actualizar en Firestore
      await _firestore.collection('users').doc(userId).update({
        'avatarBase64': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Actualizar modelo local si es el usuario actual
      if (_userProfile != null && _userProfile!.uid == userId) {
        _userProfile = _userProfile!.copyWith(avatarBase64: '');
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar avatar: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
  
  // Verificar disponibilidad de username
  Future<bool> isUsernameAvailable(String username, String currentUserId) async {
    _setLoading(true);
    _error = null;
    
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      
      // Si no hay documentos, el username está disponible
      if (querySnapshot.docs.isEmpty) {
        _setLoading(false);
        return true;
      }
      
      // Si hay documentos, verificar que no sea el usuario actual
      for (var doc in querySnapshot.docs) {
        if (doc.id != currentUserId) {
          _setLoading(false);
          return false;
        }
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  // Buscar usuarios por username
  Future<List<UserModel>> searchUsers(String query) async {
    _setLoading(true);
    _error = null;
    
    try {
      // Obtener usuarios cuyo username comienza con la consulta
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();
      
      final users = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      
      _setLoading(false);
      return users;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return [];
    }
  }
  
  // Obtener lista de moderadores
  Future<List<UserModel>> getModerators() async {
    _setLoading(true);
    _error = null;
    
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('isModerator', isEqualTo: true)
          .get();
      
      final moderators = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
      
      _setLoading(false);
      return moderators;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return [];
    }
  }
  
  // Helpers para actualizar estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}