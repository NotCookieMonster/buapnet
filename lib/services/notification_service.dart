import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  NotificationService._internal();
  
  /// Inicializar configuración de notificaciones
  Future<void> initialize() async {
    // Solicitar permisos para iOS
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    
    // Configurar canal para Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'Notificaciones importantes',
        description: 'Canal para notificaciones importantes de BUAPnet',
        importance: Importance.high,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
    
    // Inicializar plugin de notificaciones locales
    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );
    
    // Manejar mensajes en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Obtener token FCM y guardarlo
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }
    
    // Escuchar cambios de token
    _messaging.onTokenRefresh.listen(_saveTokenToDatabase);
  }
  
  // Manejar notificación seleccionada
  void _onSelectNotification(NotificationResponse response) {
    if (response.payload != null) {
      final payload = json.decode(response.payload!);
      
      // Aquí se puede implementar la navegación a la pantalla correspondiente
      debugPrint('Notificación seleccionada: $payload');
    }
  }
  
  // Manejar mensajes en primer plano
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;
    
    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Notificaciones importantes',
            icon: android.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: json.encode(message.data),
      );
    }
  }
  
  // Guardar token FCM en Firestore
  Future<void> _saveTokenToDatabase(String token) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    }
  }
  
  // Suscribirse a tópicos (ej: para moderadores)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }
  
  // Desuscribirse de tópicos
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}