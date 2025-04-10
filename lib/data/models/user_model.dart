// lib/data/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String faculty;
  final String studentId;
  final String avatarBase64;  // Antes era avatarUrl
  final bool isModerator;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.faculty,
    required this.studentId,
    this.avatarBase64 = '',  // Cambiado de avatarUrl
    this.isModerator = false,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Método para convertir un documento de Firestore a UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      faculty: data['faculty'] ?? '',
      studentId: data['studentId'] ?? '',
      avatarBase64: data['avatarBase64'] ?? '',  // Cambiado de avatarUrl
      isModerator: data['isModerator'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  // Método para convertir UserModel a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'faculty': faculty,
      'studentId': studentId,
      'avatarBase64': avatarBase64,  // Cambiado de avatarUrl
      'isModerator': isModerator,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  // Método para actualizar un UserModel
  UserModel copyWith({
    String? username,
    String? firstName,
    String? lastName,
    String? faculty,
    String? studentId,
    String? avatarBase64,  // Cambiado de avatarUrl
    bool? isModerator,
  }) {
    return UserModel(
      uid: this.uid,
      email: this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      faculty: faculty ?? this.faculty,
      studentId: studentId ?? this.studentId,
      avatarBase64: avatarBase64 ?? this.avatarBase64,  // Cambiado
      isModerator: isModerator ?? this.isModerator,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }
  
  // Accesores para datos relevantes públicamente (que pueden ver otros usuarios)
  Map<String, dynamic> get publicProfile {
    return {
      'uid': uid,
      'username': username,
      'avatarBase64': avatarBase64,  // Cambiado de avatarUrl
    };
  }
  
  // Para depuración
  @override
  String toString() {
    return 'UserModel(uid: $uid, username: $username, isModerator: $isModerator)';
  }
}