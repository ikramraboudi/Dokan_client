/// ============================================================================
/// RÔLE DU FICHIER : Service de suivi et notifications des commandes 100% gratuit (sans plan Blaze).
/// Gère deux mécanismes complémentaires :
/// 1) App ouverte ou en arrière-plan actif : écoute Firestore temps réel.
/// 2) App fermée : vérification périodique WorkManager (15 min) avec réseau connecté.
/// INTERAGIT AVEC : sessionProvider, OrderNotificationResolver, NotificationService, OrderDetailScreen.
/// POUR L'ORAL : « LocalOrderTrackerService permet à l'app Client d'alerter l'utilisateur sur les changements
/// de statut et l'arrivée du livreur en temps réel sans serveur payant Cloud Functions. »
/// ============================================================================
library;

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../core/config/app_config.dart';
import '../feature/orders/order_notification_resolver.dart';
import 'notification_service.dart';

/// Constantes pour la configuration de la tâche périodique WorkManager.
const String kDokanPeriodicOrderTaskName = 'com.dokan.client.order_periodic_check';
const String kDokanPeriodicOrderUniqueName = 'dokan_order_tracker_periodic_task';

/// Point d'entrée de premier niveau (Isolate d'arrière-plan Android) pour WorkManager.
/// Doit impérativement être annoté avec `@pragma('vm:entry-point')`.
@pragma('vm:entry-point')
void dokanWorkmanagerCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == kDokanPeriodicOrderTaskName ||
        taskName == Workmanager.iOSBackgroundTask) {
      try {
        await executeBackgroundOrderCheck();
      } catch (e) {
        debugPrint('Dokan WorkManager executeBackgroundOrderCheck erreur: $e');
      }
    }
    return Future.value(true);
  });
}

/// Exécution de la vérification d'arrière-plan quand l'application est fermée (Terminated).
/// Réalise une requête unique (one-shot get()) sans boucle ni écoute permanente.
Future<void> executeBackgroundOrderCheck() async {
  // 1. Si le mode serveur payant est activé, ce mécanisme autonome reste inactif
  if (AppConfig.useServerPush) return;

  // 2. Initialisation minimale de l'isolate
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  // 3. Vérification de la session utilisateur persistante
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null || currentUser.uid.isEmpty) {
    debugPrint('Dokan WorkManager: aucun utilisateur connecté, fin de la tâche.');
    return;
  }
  final userId = currentUser.uid;

  // 4. Initialisation du plugin de notifications locales dans cet isolate
  final localNotifications = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await localNotifications.initialize(
    settings: const InitializationSettings(android: androidInit),
  );

  // 5. Requête Firestore unique pour récupérer les commandes du client
  final querySnapshot = await FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: userId)
      .get();

  final prefs = await SharedPreferences.getInstance();
  final storageKey = 'dokan_orders_state_$userId';
  final rawJson = prefs.getString(storageKey);

  final bool isFirstSync = rawJson == null;
  Map<String, dynamic> localMap = {};
  if (rawJson != null && rawJson.isNotEmpty) {
    try {
      localMap = jsonDecode(rawJson) as Map<String, dynamic>;
    } catch (_) {}
  }

  final updatedMap = Map<String, dynamic>.from(localMap);
  final now = DateTime.now();

  for (final doc in querySnapshot.docs) {
    final data = doc.data();
    final orderId = doc.id;
    final displayNumber = data['displayNumber'] as String? ?? orderId;
    final rawStatus = data['status'] as String? ?? '';
    final hasDriverArrived = data['driverArrivedAt'] != null;
    final cancelledBy = data['cancelledBy'] as String?;

    // Ignorer les commandes livrées ou annulées depuis plus de 24h
    final updatedAtTimestamp = data['updatedAt'] as Timestamp?;
    final updatedAt = updatedAtTimestamp?.toDate() ?? now;
    final normStatus = OrderNotificationResolver.normalizeStatus(rawStatus);
    final isFinished = normStatus == 'delivered' || normStatus == 'cancelled';
    if (isFinished && now.difference(updatedAt).inHours > 24) {
      updatedMap.remove(orderId);
      continue;
    }

    final oldStateJson = localMap[orderId] as Map<String, dynamic>?;
    final oldState = oldStateJson != null
        ? OrderNotificationState.fromJson(oldStateJson)
        : null;

    final notif = OrderNotificationResolver.notificationFor(
      oldState: oldState,
      orderId: orderId,
      displayNumber: displayNumber,
      rawStatus: rawStatus,
      hasDriverArrived: hasDriverArrived,
      isFirstSync: isFirstSync,
      isDetailScreenOpen: false,
      cancelledBy: cancelledBy,
    );

    if (notif != null) {
      const androidDetails = AndroidNotificationDetails(
        'orders',
        'Suivi des commandes',
        channelDescription:
            'Alertes en temps réel sur le statut de vos commandes et l\'arrivée du livreur.',
        importance: Importance.high,
        priority: Priority.high,
      );
      await localNotifications.show(
        id: notif.notificationId,
        title: notif.title,
        body: notif.body,
        notificationDetails: const NotificationDetails(android: androidDetails),
        payload: notif.orderId,
      );
    }

    final nextState = OrderNotificationResolver.nextState(
      oldState: oldState,
      rawStatus: rawStatus,
      hasDriverArrived: hasDriverArrived,
      cancelledBy: cancelledBy,
    );
    updatedMap[orderId] = nextState.toJson();
  }

  await prefs.setString(storageKey, jsonEncode(updatedMap));
}

/// Service de suivi local des commandes gérant l'écoute active et la planification WorkManager.
class LocalOrderTrackerService {
  final NotificationService _notificationService;
  final FirebaseFirestore? _firestore;

  /// Retient l'ID de la commande actuellement ouverte à l'écran par l'utilisateur.
  /// Si cette commande reçoit une mise à jour, la notification est supprimée car l'écran s'actualise déjà.
  static String? currentlyViewedOrderId;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSubscription;
  String? _activeUserId;
  bool _isFirstSync = true;

  LocalOrderTrackerService({
    required NotificationService notificationService,
    FirebaseFirestore? firestore,
  })  : _notificationService = notificationService,
        _firestore = firestore;

  /// Démarre le suivi des commandes d'un utilisateur connecté :
  /// - Lance l'écoute temps réel Firestore (Mécanisme 1)
  /// - Enregistre la tâche de fond périodique WorkManager (Mécanisme 2)
  Future<void> startTracking(String userId) async {
    if (AppConfig.useServerPush) return;
    if (userId.trim().isEmpty) return;

    if (_activeUserId == userId && _ordersSubscription != null) {
      debugPrint('LocalOrderTrackerService: déjà actif pour $userId');
      return;
    }

    _activeUserId = userId;
    _isFirstSync = true;
    await _ordersSubscription?.cancel();
    debugPrint('LocalOrderTrackerService: démarrage écoute temps réel des commandes pour $userId');

    // 1. Enregistrement de la tâche périodique WorkManager (toutes les 15 minutes)
    try {
      await Workmanager().registerPeriodicTask(
        kDokanPeriodicOrderUniqueName,
        kDokanPeriodicOrderTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } catch (e) {
      debugPrint('LocalOrderTrackerService: erreur registerPeriodicTask ($e)');
    }

    // 2. Écoute temps réel Firestore (Mécanisme 1 : App ouverte / premier plan)
    try {
      final firestore = _firestore ?? FirebaseFirestore.instance;
      _ordersSubscription = firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen(
        (snapshot) async {
          await _processSnapshot(snapshot.docs, userId);
        },
        onError: (e) {
          debugPrint('LocalOrderTrackerService: erreur stream orders ($e)');
        },
      );
    } catch (e) {
      debugPrint('LocalOrderTrackerService: Firestore indisponible ($e)');
    }
  }

  /// Arrête le suivi des commandes lors de la déconnexion :
  /// - Annule l'abonnement Firestore en direct
  /// - Annule la tâche périodique WorkManager
  /// - Supprime les états locaux enregistrés
  Future<void> stopTracking(String? userId) async {
    await _ordersSubscription?.cancel();
    _ordersSubscription = null;
    _activeUserId = null;
    _isFirstSync = true;

    try {
      await Workmanager().cancelByUniqueName(kDokanPeriodicOrderUniqueName);
    } catch (e) {
      debugPrint('LocalOrderTrackerService: erreur cancelByUniqueName ($e)');
    }

    if (userId != null && userId.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('dokan_orders_state_$userId');
      } catch (_) {}
    }
  }

  /// Traite les documents d'un snapshot Firestore pour détecter les changements.
  Future<void> _processSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String userId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = 'dokan_orders_state_$userId';
      final rawJson = prefs.getString(storageKey);

      Map<String, dynamic> localMap = {};
      if (rawJson != null && rawJson.isNotEmpty) {
        try {
          localMap = jsonDecode(rawJson) as Map<String, dynamic>;
        } catch (_) {}
      }

      final updatedMap = Map<String, dynamic>.from(localMap);
      final now = DateTime.now();

      for (final doc in docs) {
        final data = doc.data();
        final orderId = doc.id;
        final displayNumber = data['displayNumber'] as String? ?? orderId;
        final rawStatus = data['status'] as String? ?? '';
        final hasDriverArrived = data['driverArrivedAt'] != null;
        final cancelledBy = data['cancelledBy'] as String?;

        // Ignorer les commandes livrées ou annulées depuis plus de 24h
        final updatedAtTimestamp = data['updatedAt'] as Timestamp?;
        final updatedAt = updatedAtTimestamp?.toDate() ?? now;
        final normStatus = OrderNotificationResolver.normalizeStatus(rawStatus);
        final isFinished = normStatus == 'delivered' || normStatus == 'cancelled';
        if (isFinished && now.difference(updatedAt).inHours > 24) {
          updatedMap.remove(orderId);
          continue;
        }

        final oldStateJson = localMap[orderId] as Map<String, dynamic>?;
        final oldState = oldStateJson != null
            ? OrderNotificationState.fromJson(oldStateJson)
            : null;

        final isDetailOpen = currentlyViewedOrderId == orderId;

        final notif = OrderNotificationResolver.notificationFor(
          oldState: oldState,
          orderId: orderId,
          displayNumber: displayNumber,
          rawStatus: rawStatus,
          hasDriverArrived: hasDriverArrived,
          isFirstSync: _isFirstSync,
          isDetailScreenOpen: isDetailOpen,
          cancelledBy: cancelledBy,
        );

        debugPrint(
          'LocalOrderTrackerService: commande $orderId statut="$rawStatus" (normalisé="$normStatus", ancien="${oldState?.status}", isFirstSync=$_isFirstSync, isDetailOpen=$isDetailOpen, notif=${notif?.title})',
        );

        if (notif != null) {
          debugPrint('LocalOrderTrackerService: 🔔 Envoi notification locale: "${notif.title}" - "${notif.body}"');
          await _notificationService.showLocalNotification(
            id: notif.notificationId,
            title: notif.title,
            body: notif.body,
            payload: notif.orderId,
          );
        }

        final nextState = OrderNotificationResolver.nextState(
          oldState: oldState,
          rawStatus: rawStatus,
          hasDriverArrived: hasDriverArrived,
          cancelledBy: cancelledBy,
        );
        updatedMap[orderId] = nextState.toJson();
      }

      await prefs.setString(storageKey, jsonEncode(updatedMap));
    } catch (e) {
      debugPrint('LocalOrderTrackerService: erreur _processSnapshot ($e)');
    } finally {
      _isFirstSync = false;
    }
  }

  /// Mémorise immédiatement dans l'état local qu'une commande a été annulée par le client.
  /// Empêche tout déclenchement d'alerte lors de la réception de l'événement Firestore suivant.
  Future<void> markOrderCancelledByClient(String orderId) async {
    final userId = _activeUserId;
    if (userId == null || userId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = 'dokan_orders_state_$userId';
      final rawJson = prefs.getString(storageKey);

      Map<String, dynamic> localMap = {};
      if (rawJson != null && rawJson.isNotEmpty) {
        try {
          localMap = jsonDecode(rawJson) as Map<String, dynamic>;
        } catch (_) {}
      }

      final oldStateJson = localMap[orderId] as Map<String, dynamic>?;
      final oldState = oldStateJson != null
          ? OrderNotificationState.fromJson(oldStateJson)
          : null;

      final updatedState = OrderNotificationState(
        status: 'cancelled',
        driverArrivedNotified: oldState?.driverArrivedNotified ?? false,
        cancelledByClient: true,
      );

      localMap[orderId] = updatedState.toJson();
      await prefs.setString(storageKey, jsonEncode(localMap));
    } catch (e) {
      debugPrint('LocalOrderTrackerService: erreur markOrderCancelledByClient ($e)');
    }
  }
}

/// Provider Riverpod global pour le service de suivi local des commandes.
final localOrderTrackerServiceProvider =
    Provider<LocalOrderTrackerService>((ref) {
  final notifService = ref.watch(notificationServiceProvider);
  FirebaseFirestore? firestore;
  try {
    if (Firebase.apps.isNotEmpty) {
      firestore = FirebaseFirestore.instance;
    }
  } catch (_) {}

  return LocalOrderTrackerService(
    notificationService: notifService,
    firestore: firestore,
  );
});
