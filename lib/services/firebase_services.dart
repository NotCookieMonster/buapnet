import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buapnet/services/notification_service.dart';

/// Clase para inicializar y gestionar servicios de Firebase.
/// Implementa el patrón Singleton para garantizar una sola instancia.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  
  // Instancias de Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  
  FirebaseService._internal();
  
  /// Inicializa configuraciones de Firebase
  Future<void> initialize() async {
    // Habilitar persistencia offline para Firestore
    await _firestore.enablePersistence(
      const PersistenceSettings(
        synchronizeTabs: true,
      ),
    ).catchError((e) {
      // Manejar errores de persistencia, como múltiples pestañas en web
      print('Error al habilitar persistencia: $e');
    });
    
    // Configurar el tamaño máximo de caché para Firestore (50MB)
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 50000000,
    );
    

    // Inicializar servicio de notificaciones
    await _notificationService.initialize();
  }
  
  /// Configura un listener para cambios en la autenticación
  void setupAuthListener(Function(User?) onAuthStateChanged) {
    _auth.authStateChanges().listen(onAuthStateChanged);
  }
  
  /// Obtiene el usuario actualmente autenticado
  User? get currentUser => _auth.currentUser;
  
  /// Configura el modo sin conexión (útil cuando se sabe que la conexión será limitada)
  Future<void> setupOfflineMode(bool enableOfflineMode) async {
    if (enableOfflineMode) {
      // Configurar modo sin conexión agresivo que prioriza caché
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 100000000, // 100MB
      );
      
      // Pre-cargar colecciones frecuentemente accedidas
      await _preloadFrequentCollections();
    } else {
      // Restaurar configuración normal
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 50000000, // 50MB
      );
    }
  }
  
  /// Pre-carga colecciones frecuentemente accedidas para mejorar experiencia offline
  Future<void> _preloadFrequentCollections() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      // Pre-cargar perfil del usuario
      await _firestore.collection('users').doc(userId).get();
      
      // Pre-cargar feed principal (últimas 20 publicaciones)
      await _firestore
          .collection('posts')
          .where('isHidden', isEqualTo: false)
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      
      // Pre-cargar chats del usuario (últimos 10)
      await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .limit(10)
          .get();
      
      print('Pre-carga de colecciones completada para modo offline');
    } catch (e) {
      print('Error durante la pre-carga: $e');
    }
  }
  
  /// Monitorea el estado de conectividad con Firestore
  Stream<bool> get firestoreConnectionState {
    return Stream<bool>.periodic(const Duration(seconds: 5))
        .asyncMap((_) async {
      try {
        // Intentar obtener un documento pequeño para probar conectividad
        await _firestore
            .collection('system')
            .doc('status')
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 10));
        return true;
      } catch (e) {
        return false;
      }
    });
  }
}