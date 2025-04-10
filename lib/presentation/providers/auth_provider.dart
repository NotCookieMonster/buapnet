import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buapnet/data/models/user_model.dart';
import 'package:buapnet/data/repositories/auth_repository_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:buapnet/services/image_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageService _imageService = ImageService();
  
  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _user;
  String? _error;
  bool _isLoading = false;
  
  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isModerator => _user?.isModerator ?? false;
  
  AuthProvider() {
    // Inicializar escuchando cambios de autenticación
    _authRepository.authStateChanges.listen(_onAuthStateChanged);
  }
  
  // Manejador de cambios en el estado de autenticación
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    } else {
      try {
        // Obtener el documento del usuario en Firestore
        final userDoc = await _authRepository.usersCollection.doc(firebaseUser.uid).get();
        
        if (userDoc.exists) {
          _user = UserModel.fromFirestore(userDoc);
          _status = AuthStatus.authenticated;
        } else {
          // Si no existe el documento pero sí el usuario en Auth
          _status = AuthStatus.unauthenticated;
          await _authRepository.signOut();
        }
      } catch (e) {
        _status = AuthStatus.unauthenticated;
        _error = e.toString();
      }
    }
    
    notifyListeners();
  }
  
  // Registrarse con email y contraseña
  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
    required String faculty,
    required String studentId,
  }) async {
    _setLoading(true);
    _error = null;
    
    try {
      await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
        username: username,
        firstName: firstName,
        lastName: lastName,
        faculty: faculty,
        studentId: studentId,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  // Iniciar sesión con email y contraseña
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    
    try {
      await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  // Cerrar sesión
  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await _authRepository.signOut();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }
  
  // Restablecer contraseña
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _error = null;
    
    try {
      await _authRepository.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  // Actualizar perfil de usuario
Future<bool> updateUserProfile({
  String? username,
  String? firstName,
  String? lastName,
  String? faculty,
  File? avatarfile,
}) async {
  if (_user == null) return false;
  
  _setLoading(true);
  _error = null;
  
  try {
    String? avatarBase64;
    if (avatarfile != null) {
      avatarBase64 = await _imageService.encodeImageToBase64(
        avatarfile,
        quality: 60,
        maxWidth: 300,
        maxHeight: 300,
      );
    }
     // Preparar datos para actualizar
    final Map<String, dynamic> dataToUpdate = {
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (username != null) dataToUpdate['username'] = username;
    if (firstName != null) dataToUpdate['firstName'] = firstName;
    if (lastName != null) dataToUpdate['lastName'] = lastName;
    if (faculty != null) dataToUpdate['faculty'] = faculty;
    if (avatarBase64 != null) dataToUpdate['avatarBase64'] = avatarBase64;
    
    // Actualizar en Firestore
    await _firestore.collection('users').doc(_user!.uid).update(dataToUpdate);
    
    // Obtener y retornar el usuario actualizado
    final updatedUserDoc = await _firestore.collection('users').doc(_user!.uid).get();
    _user = UserModel.fromFirestore(updatedUserDoc);
    
    _setLoading(false);
    notifyListeners();
    return true;
  } catch (e) {
    _setError(e.toString());
    _setLoading(false);
    return false;
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