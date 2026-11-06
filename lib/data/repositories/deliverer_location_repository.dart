/// ============================================================================
/// RÔLE DU FICHIER : Repository abstrait et implémentations (Firebase RTDB + Mock)
/// pour la lecture en streaming de la position en direct des livreurs (`deliverers_live/{id}`).
/// RÈGLE DE SÉCURITÉ : Lecture seule absolue (le client n'écrit jamais dans RTDB).
/// ============================================================================
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deliverer_location.dart';

/// URL officielle de l'instance Realtime Database du projet Dokan (ee-comeerce)
const String kDokanRtdbUrl = 'https://ee-comeerce-default-rtdb.firebaseio.com';

/// Interface du repository de localisation du livreur.
abstract class DelivererLocationRepository {
  /// Flux en temps réel observant la position du livreur.
  Stream<DelivererLocation?> watchDelivererLocation(String delivererId);

  /// Récupère le décalage temporel avec le serveur Firebase (en millisecondes).
  Future<int> getServerTimeOffset();

  /// Libère les écoutes actives.
  void dispose();
}

/// Implémentation réelle connectée à Firebase Realtime Database.
class FirebaseDelivererLocationRepository implements DelivererLocationRepository {
  final FirebaseDatabase _database;
  int _serverTimeOffset = 0;
  StreamSubscription<DatabaseEvent>? _offsetSubscription;

  FirebaseDelivererLocationRepository({FirebaseDatabase? database})
      : _database = database ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: kDokanRtdbUrl,
            ) {
    _listenToServerTimeOffset();
  }

  void _listenToServerTimeOffset() {
    try {
      final offsetRef = _database.ref('.info/serverTimeOffset');
      _offsetSubscription = offsetRef.onValue.listen(
        (event) {
          final val = event.snapshot.value;
          if (val is num) {
            _serverTimeOffset = val.toInt();
          }
        },
        onError: (e) {
          debugPrint('FirebaseDelivererLocationRepository: offset error ($e)');
        },
      );
    } catch (_) {}
  }

  @override
  Stream<DelivererLocation?> watchDelivererLocation(String delivererId) {
    if (delivererId.trim().isEmpty) {
      return Stream.value(null);
    }

    final ref = _database.ref('deliverers_live/$delivererId');
    return ref.onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return null;
      if (value is Map) {
        return DelivererLocation.fromMap(delivererId, value);
      }
      return null;
    }).handleError((error) {
      debugPrint('FirebaseDelivererLocationRepository: watch error ($error)');
      return null;
    });
  }

  @override
  Future<int> getServerTimeOffset() async => _serverTimeOffset;

  @override
  void dispose() {
    _offsetSubscription?.cancel();
  }
}

/// Implémentation Mock (mode démo / tests) simulant un livreur en mouvement continu.
class MockDelivererLocationRepository implements DelivererLocationRepository {
  final double initialLat;
  final double initialLon;
  final double destinationLat;
  final double destinationLon;

  Timer? _timer;
  final StreamController<DelivererLocation?> _controller =
      StreamController<DelivererLocation?>.broadcast();

  double _currentLat = 36.8065;
  double _currentLon = 10.1815;
  double _currentHeading = 45.0;
  final double _currentSpeed = 8.5; // ~30 km/h
  double _progress = 0.0;
  bool _isOnline = true;

  MockDelivererLocationRepository({
    this.initialLat = 36.8010,
    this.initialLon = 10.1750,
    this.destinationLat = 36.8150,
    this.destinationLon = 10.1900,
  }) {
    _currentLat = initialLat;
    _currentLon = initialLon;
  }

  void setOnline(bool online) {
    _isOnline = online;
    _emitLocation('MOCK_DRIVER');
  }

  void _emitLocation(String delivererId) {
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final loc = DelivererLocation(
      delivererId: delivererId,
      delivererName: 'Mourad Trabelsi (Simulé)',
      latitude: _currentLat,
      longitude: _currentLon,
      heading: _currentHeading,
      speed: _currentSpeed,
      timestamp: nowMillis,
      isOnline: _isOnline,
      currentOrderId: 'ord_mock_123',
      vehicle: const {
        'matricule': '215 TN 8877',
        'type': 'voiture',
      },
    );
    if (!_controller.isClosed) {
      _controller.add(loc);
    }
  }

  @override
  Stream<DelivererLocation?> watchDelivererLocation(String delivererId) {
    _timer?.cancel();
    _progress = 0.0;
    _currentLat = initialLat;
    _currentLon = initialLon;

    // Émission immédiate
    _emitLocation(delivererId);

    // Mouvement continu toutes les 2 secondes
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _progress += 0.04;
      if (_progress >= 1.0) {
        _progress = 0.0; // Boucle
      }

      // Trajet interpolé avec petite ondulation
      final lat = initialLat + (destinationLat - initialLat) * _progress;
      final lon = initialLon +
          (destinationLon - initialLon) * _progress +
          math.sin(_progress * math.pi * 4) * 0.001;

      // Calcul du heading
      final dLat = lat - _currentLat;
      final dLon = lon - _currentLon;
      final angle = math.atan2(dLon, dLat) * (180 / math.pi);
      _currentHeading = (angle + 360) % 360;

      _currentLat = lat;
      _currentLon = lon;
      _emitLocation(delivererId);
    });

    return _controller.stream;
  }

  @override
  Future<int> getServerTimeOffset() async => 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

/// Provider singleton du repository de localisation.
final delivererLocationRepositoryProvider =
    Provider<DelivererLocationRepository>((ref) {
  try {
    if (Firebase.apps.isNotEmpty) {
      final repo = FirebaseDelivererLocationRepository();
      ref.onDispose(() => repo.dispose());
      return repo;
    }
  } catch (e) {
    debugPrint('delivererLocationRepositoryProvider fallback mock ($e)');
  }
  final mockRepo = MockDelivererLocationRepository();
  ref.onDispose(() => mockRepo.dispose());
  return mockRepo;
});

/// StreamProvider pour écouter en temps réel un livreur spécifique.
final delivererLocationStreamProvider =
    StreamProvider.autoDispose.family<DelivererLocation?, String>((ref, delivererId) {
  final repo = ref.watch(delivererLocationRepositoryProvider);
  return repo.watchDelivererLocation(delivererId);
});
