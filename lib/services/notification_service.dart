/// ============================================================================
/// RÔLE DU FICHIER : Service de gestion des notifications push FCM et locales
/// pour le suivi de commande et l'arrivée du coursier.
/// INTERAGIT AVEC : FirebaseMessaging, FlutterLocalNotificationsPlugin, Cloud Firestore,
/// session_provider.dart, app_router.dart, SettingsAndHelpScreen.
/// ============================================================================
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';

/// Handler d'arrière-plan top-level pour Firebase Messaging (app fermée ou en arrière-plan).
/// Requis par le plugin FirebaseMessaging sur Android.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // S'assure que Firebase est initialisé pour le background isolate
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Déjà initialisé ou indisponible
  }
}

/// Interface abstraite pour découpler le service de notification (permet le Mock en test).
abstract class NotificationService {
  /// Initialise les canaux locaux et écouteurs FCM.
  Future<void> initialize({void Function(String orderId)? onNavigateToOrder});

  /// Demande la permission d'envoi de notification (Android 13+ POST_NOTIFICATIONS).
  Future<bool> requestPermission();

  /// Vérifie si la permission est actuellement accordée.
  Future<bool> isPermissionGranted();

  /// Enregistre le token FCM du téléphone dans Firestore (users/{uid}/devices/{token}).
  Future<void> registerDeviceToken(String userId);

  /// Écoute le renouvellement du token et met à jour Firestore.
  void setupTokenRefreshListener(String userId);

  /// Supprime le token de Firestore et appelle deleteToken() à la déconnexion.
  Future<void> unregisterDeviceToken(String userId);

  /// Affiche une notification locale au premier plan.
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  /// Libère les ressources et écouteurs.
  void dispose();
}

/// Implémentation réelle basée sur Firebase Cloud Messaging et FlutterLocalNotifications.
class FirebaseNotificationService implements NotificationService {
  FirebaseMessaging? _fcmInstance;
  FirebaseFirestore? _firestoreInstance;
  final FlutterLocalNotificationsPlugin _localNotifications;

  FirebaseMessaging? get _fcm {
    if (_fcmInstance != null) return _fcmInstance;
    try {
      if (Firebase.apps.isNotEmpty) {
        _fcmInstance = FirebaseMessaging.instance;
      }
    } catch (_) {}
    return _fcmInstance;
  }

  FirebaseFirestore? get _firestore {
    if (_firestoreInstance != null) return _firestoreInstance;
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestoreInstance = FirebaseFirestore.instance;
      }
    } catch (_) {}
    return _firestoreInstance;
  }

  void Function(String orderId)? _onNavigateToOrder;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;

  bool _initialized = false;
  String? _currentToken;

  /// Identifiant du canal de notification pour les commandes.
  static const String channelId = 'orders';
  static const String channelName = 'Suivi de commande';
  static const String channelDescription =
      'Alertes en temps réel sur le statut de vos commandes et l\'arrivée du livreur.';

  FirebaseNotificationService({
    FirebaseMessaging? fcm,
    FirebaseFirestore? firestore,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _fcmInstance = fcm,
        _firestoreInstance = firestore,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize({
    void Function(String orderId)? onNavigateToOrder,
  }) async {
    if (_initialized) {
      _onNavigateToOrder = onNavigateToOrder;
      return;
    }

    _onNavigateToOrder = onNavigateToOrder;

    try {
      // 1. Initialisation du plugin de notifications locales
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _handleNotificationNavigation(payload);
          }
        },
      );

      // 2. Création explicite du canal de notification Android avec priorité maximale (Heads-Up)
      final androidChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // 3. Enregistrement du handler d'arrière-plan FCM
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 4. Écoute des messages quand l'app est au premier plan (Foreground)
      _foregroundMessageSubscription =
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 5. Clic sur notification quand l'app était en arrière-plan
      _messageOpenedAppSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final orderId = message.data['orderId'] as String?;
        if (orderId != null && orderId.isNotEmpty) {
          _handleNotificationNavigation(orderId);
        }
      });

      // 6. Clic sur notification ayant ouvert l'app depuis un état fermé (Terminated)
      final initialMessage = await _fcm?.getInitialMessage();
      if (initialMessage != null) {
        final orderId = initialMessage.data['orderId'] as String?;
        if (orderId != null && orderId.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleNotificationNavigation(orderId);
          });
        }
      }

      _initialized = true;
    } catch (e) {
      debugPrint('FirebaseNotificationService.initialize: ignoré en environnement de test/sans play services ($e)');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    final orderId = data['orderId'] as String?;

    final title = notification?.title ?? 'Suivi Dokan';
    final body = notification?.body ?? 'Votre commande a été mise à jour.';

    // En premier plan, FCM n'affiche rien nativement sur Android :
    // On déclenche donc une notification locale sur le canal 'orders'.
    showLocalNotification(
      id: message.hashCode,
      title: title,
      body: body,
      payload: orderId,
    );
  }

  void _handleNotificationNavigation(String orderId) {
    if (_onNavigateToOrder != null) {
      _onNavigateToOrder!(orderId);
    }
  }

  @override
  Future<bool> requestPermission() async {
    bool localGranted = true;
    try {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final res = await androidPlugin?.requestNotificationsPermission();
      if (res != null) localGranted = res;
    } catch (e) {
      debugPrint('NotificationService: erreur requestNotificationsPermission ($e)');
    }

    try {
      final fcm = _fcm;
      if (fcm != null) {
        final settings = await fcm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        final fcmGranted =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
                settings.authorizationStatus == AuthorizationStatus.provisional;
        return localGranted && fcmGranted;
      }
    } catch (_) {}

    return localGranted;
  }

  @override
  Future<bool> isPermissionGranted() async {
    try {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await androidPlugin?.areNotificationsEnabled();
      if (enabled != null && !enabled) return false;
    } catch (_) {}

    try {
      final fcm = _fcm;
      if (fcm == null) return true;
      final settings = await fcm.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> registerDeviceToken(String userId) async {
    if (userId.trim().isEmpty) return;

    try {
      final fcm = _fcm;
      final firestore = _firestore;
      if (fcm == null || firestore == null) return;

      final token = await fcm.getToken();
      if (token == null || token.isEmpty) return;

      _currentToken = token;

      // Enregistrement idempotente dans Firestore : users/{uid}/devices/{token}
      await firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(token)
          .set({
        'platform': 'android',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Écoute du renouvellement automatique du token
      setupTokenRefreshListener(userId);
    } catch (e) {
      debugPrint('NotificationService: erreur registerDeviceToken ($e)');
    }
  }

  @override
  void setupTokenRefreshListener(String userId) {
    _tokenRefreshSubscription?.cancel();
    final fcm = _fcm;
    final firestore = _firestore;
    if (fcm == null || firestore == null) return;

    _tokenRefreshSubscription = fcm.onTokenRefresh.listen((newToken) async {
      try {
        _currentToken = newToken;
        await firestore
            .collection('users')
            .doc(userId)
            .collection('devices')
            .doc(newToken)
            .set({
          'platform': 'android',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('NotificationService: erreur onTokenRefresh ($e)');
      }
    });
  }

  @override
  Future<void> unregisterDeviceToken(String userId) async {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    if (userId.trim().isEmpty) return;

    try {
      final fcm = _fcm;
      final firestore = _firestore;
      final token = _currentToken ?? await fcm?.getToken();

      if (token != null && token.isNotEmpty && firestore != null) {
        // Suppression du document dans Firestore
        await firestore
            .collection('users')
            .doc(userId)
            .collection('devices')
            .doc(token)
            .delete();
      }

      // Révocation du token FCM pour que ce terminal ne reçoive plus les notifications
      await fcm?.deleteToken();
      _currentToken = null;
    } catch (e) {
      debugPrint('NotificationService: erreur unregisterDeviceToken ($e)');
    }
  }

  @override
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      color: AppColors.primary,
      icon: '@mipmap/ic_launcher',
      channelShowBadge: true,
      playSound: true,
      enableVibration: true,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _messageOpenedAppSubscription?.cancel();
  }
}

/// Implémentation Mock en mémoire pour les tests unitaires et le mode démo sans Firebase.
class MockNotificationService implements NotificationService {
  bool permissionGranted = false;
  final Set<String> registeredTokens = {};
  String? registeredUserId;
  void Function(String orderId)? onNavigateToOrder;
  final List<Map<String, dynamic>> shownNotifications = [];

  @override
  Future<void> initialize({void Function(String orderId)? onNavigateToOrder}) async {
    this.onNavigateToOrder = onNavigateToOrder;
  }

  @override
  Future<bool> requestPermission() async {
    permissionGranted = true;
    return true;
  }

  @override
  Future<bool> isPermissionGranted() async {
    return permissionGranted;
  }

  @override
  Future<void> registerDeviceToken(String userId) async {
    registeredUserId = userId;
    registeredTokens.add('mock_token_$userId');
  }

  @override
  void setupTokenRefreshListener(String userId) {
    registeredUserId = userId;
  }

  @override
  Future<void> unregisterDeviceToken(String userId) async {
    registeredTokens.remove('mock_token_$userId');
    if (registeredUserId == userId) {
      registeredUserId = null;
    }
  }

  @override
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    shownNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
    });
  }

  @override
  void dispose() {
    shownNotifications.clear();
  }
}

/// Provider Riverpod global pour le service de notifications.
/// Si Firebase n'est pas encore initialisé (comme lors des tests unitaires),
/// bascule automatiquement sur MockNotificationService pour une sécurité totale.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  try {
    if (Firebase.apps.isNotEmpty) {
      final service = FirebaseNotificationService();
      ref.onDispose(service.dispose);
      return service;
    }
  } catch (_) {}
  return MockNotificationService();
});
