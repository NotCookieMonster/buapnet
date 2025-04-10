import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:buapnet/data/models/user_model.dart';
import 'package:buapnet/services/image_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageService _imageService = ImageService();
  
  // Referencia a la colección de usuarios
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
  
  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;
  
  // Stream del estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Verificar si el correo es institucional
  bool isInstitutionalEmail(String email) {
    // Verificar que termine con @alumno.buap.mx
    return email.endsWith('@alumno.buap.mx');
  }
  
  // Verificar si un username ya está en uso
  Future<bool> isUsernameAvailable(String username) async {
    final querySnapshot = await usersCollection
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    
    return querySnapshot.docs.isEmpty;
  }
  
  // Registro con email institucional y contraseña
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
    required String faculty,
    required String studentId,
  }) async {
    // Verificar que el correo sea institucional
    if (!isInstitutionalEmail(email)) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Debes usar un correo institucional (@alumno.buap.mx).',
      );
    }
    
    // Verificar que el username esté disponible
    final isAvailable = await isUsernameAvailable(username);
    if (!isAvailable) {
      throw FirebaseAuthException(
        code: 'username-already-in-use',
        message: 'Este nombre de usuario ya está en uso.',
      );
    }
    
    try {
      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'No se pudo crear el usuario.',
        );
      }
      
      final user = userCredential.user!;
      
      // Crear modelo de usuario
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        username: username,
        firstName: firstName,
        lastName: lastName,
        faculty: faculty,
        studentId: studentId,
        avatarBase64: '',
        isModerator: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Guardar datos del usuario en Firestore
      await usersCollection.doc(user.uid).set(userModel.toMap());
      
      // Enviar email de verificación
      await user.sendEmailVerification();
      
      return userModel;
    } on FirebaseAuthException catch (e) {
      // Manejar errores específicos
      if (e.code == 'email-already-in-use') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Este correo ya está registrado.',
        );
      } else if (e.code == 'weak-password') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'La contraseña es demasiado débil.',
        );
      }
      // Re-lanzar el error original si no es uno de los casos anteriores
      rethrow;
    } catch (e) {
      // Si ocurre un error diferente
      rethrow;
    }
  }
  
  // Iniciar sesión con email y contraseña
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Verificar que el correo sea institucional
      if (!isInstitutionalEmail(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Debes usar un correo institucional (@alumno.buap.mx).',
        );
      }
      
      // Autenticar usuario
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'No se pudo iniciar sesión.',
        );
      }
      
      // Obtener datos del usuario desde Firestore
      final userDoc = await usersCollection.doc(userCredential.user!.uid).get();
      
      if (!userDoc.exists) {
        // Si no existe el documento, crear uno básico
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          username: email.split('@')[0], // Username temporal basado en el correo
          firstName: '',
          lastName: '',
          faculty: '',
          studentId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await usersCollection.doc(userCredential.user!.uid).set(newUser.toMap());
        return newUser;
      }
      
      return UserModel.fromFirestore(userDoc);
    } on FirebaseAuthException catch (e) {
      // Manejar errores específicos
      if (e.code == 'user-not-found') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'No existe una cuenta con este correo.',
        );
      } else if (e.code == 'wrong-password') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Contraseña incorrecta.',
        );
      }
      // Re-lanzar el error original si no es uno de los casos anteriores
      rethrow;
    } catch (e) {
      // Si ocurre un error diferente
      rethrow;
    }
  }
  
  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Restablecer contraseña
  Future<void> resetPassword(String email) async {
    // Verificar que el correo sea institucional
    if (!isInstitutionalEmail(email)) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Debes usar un correo institucional (@alumno.buap.mx).',
      );
    }
    
    await _auth.sendPasswordResetEmail(email: email);
  }
  
  // Actualizar datos del usuario
  Future<UserModel> updateUserProfile({
    required String uid,
    String? username,
    String? firstName,
    String? lastName,
    String? faculty,
    String? avatarBase64,
  }) async {
    try {
      // Verificar si el username está disponible (si se va a actualizar)
      if (username != null) {
        // Obtener el usuario actual para comparar
        final currentUserDoc = await usersCollection.doc(uid).get();
        final currentUser = UserModel.fromFirestore(currentUserDoc);
        
        // Solo verificar disponibilidad si el username es diferente al actual
        if (username != currentUser.username) {
          final isAvailable = await isUsernameAvailable(username);
          if (!isAvailable) {
            throw FirebaseAuthException(
              code: 'username-already-in-use',
              message: 'Este nombre de usuario ya está en uso.',
            );
          }
        }
      }
      
      // Preparar datos a actualizar
      final Map<String, dynamic> dataToUpdate = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (username != null) dataToUpdate['username'] = username;
      if (firstName != null) dataToUpdate['firstName'] = firstName;
      if (lastName != null) dataToUpdate['lastName'] = lastName;
      if (faculty != null) dataToUpdate['faculty'] = faculty;
      if (avatarBase64 != null) dataToUpdate['avatarBase64'] = avatarBase64;
      
      // Actualizar en Firestore
      await usersCollection.doc(uid).update(dataToUpdate);
      
      // Obtener y retornar el usuario actualizado
      final updatedUserDoc = await usersCollection.doc(uid).get();
      return UserModel.fromFirestore(updatedUserDoc);
    } catch (e) {
      rethrow;
    }
  }
}