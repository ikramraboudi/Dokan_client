import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:Dokan_client/data/models/address_ui_model.dart';
import 'package:Dokan_client/data/models/deliverer_location.dart';
import 'package:Dokan_client/data/models/order_model.dart';
import 'package:Dokan_client/data/repositories/deliverer_location_repository.dart';
import 'package:Dokan_client/services/osrm_routing_service.dart';

void main() {
  group('1. DelivererLocation - Modèle et robustesse de désérialisation', () {
    test('Désérialisation d\'un document complet RTDB', () {
      final map = {
        'delivererId': 'deliv_123',
        'delivererName': 'Karim Ben Ali',
        'latitude': 36.8065,
        'longitude': 10.1815,
        'heading': 180.5,
        'speed': 8.33, // ~30 km/h
        'timestamp': 1700000000000,
        'isOnline': true,
        'currentOrderId': 'order_abc',
        'vehicle': {'plate': '215 TN 4321', 'type': 'voiture'},
      };

      final loc = DelivererLocation.fromMap('deliv_123', map);

      expect(loc.delivererId, 'deliv_123');
      expect(loc.delivererName, 'Karim Ben Ali');
      expect(loc.latitude, 36.8065);
      expect(loc.longitude, 10.1815);
      expect(loc.heading, 180.5);
      expect(loc.speed, 8.33);
      expect(loc.speedKmh.round(), 30);
      expect(loc.timestamp, 1700000000000);
      expect(loc.isOnline, true);
      expect(loc.currentOrderId, 'order_abc');
      expect(loc.vehiclePlate, '215 TN 4321');
      expect(loc.vehicleType, 'voiture');
    });

    test('Résilience face aux données incomplètes ou variantes de noms de champs', () {
      // Données partielles avec variantes lat/lon et nombres sous forme de chaînes
      final map = {
        'id': 'drv_alt_99',
        'lat': '36.8123',
        'lon': '10.1789',
        'speed': '12.5',
      };

      final loc = DelivererLocation.fromMap('fallback_99', map);

      expect(loc.delivererId, 'fallback_99');
      expect(loc.delivererName, 'Livreur');
      expect(loc.latitude, 36.8123);
      expect(loc.longitude, 10.1789);
      expect(loc.speed, 12.5);
      expect(loc.heading, 0.0);
      expect(loc.isOnline, true); // true par défaut si non spécifié
      expect(loc.currentOrderId, isNull);
    });

    test('Désérialisation avec map vide ou corrompue ne plante jamais', () {
      final loc = DelivererLocation.fromMap('safe_id', null);

      expect(loc.delivererId, 'safe_id');
      expect(loc.latitude, 0.0);
      expect(loc.longitude, 0.0);
      expect(loc.delivererName, 'Livreur');
      expect(loc.isOnline, false);
    });
  });

  group('2. DelivererLocation - Règle de fraîcheur (Freshness)', () {
    const int nowMillis = 1700000100000;

    test('Position fraîche : <= 60 secondes et livreur en ligne', () {
      final loc = DelivererLocation(
        delivererId: 'd1',
        latitude: 36.8,
        longitude: 10.1,
        timestamp: nowMillis - 30000, // 30 secondes d'ancienneté
        isOnline: true,
      );

      expect(loc.isFresh(serverNowMillis: nowMillis, maxAgeSeconds: 60), isTrue);
      expect(loc.ageSeconds(nowMillis), 30);
    });

    test('Position périmée : > 60 secondes même si isOnline == true', () {
      final loc = DelivererLocation(
        delivererId: 'd1',
        latitude: 36.8,
        longitude: 10.1,
        timestamp: nowMillis - 65000, // 65 secondes d'ancienneté (> 60s)
        isOnline: true,
      );

      expect(loc.isFresh(serverNowMillis: nowMillis, maxAgeSeconds: 60), isFalse);
      expect(loc.ageSeconds(nowMillis), 65);
    });

    test('Position périmée : isOnline == false même si mise à jour il y a 5s', () {
      final loc = DelivererLocation(
        delivererId: 'd1',
        latitude: 36.8,
        longitude: 10.1,
        timestamp: nowMillis - 5000, // 5 secondes
        isOnline: false,
      );

      expect(loc.isFresh(serverNowMillis: nowMillis, maxAgeSeconds: 60), isFalse);
    });
  });

  group('3. DelivererLocation - Calcul de distance Haversine', () {
    test('Calcul de distance entre Tunis et Nabeul (~67 km)', () {
      const tunis = DelivererLocation(
        delivererId: 'tunis',
        latitude: 36.8065,
        longitude: 10.1815,
      );

      final distanceMeters = tunis.distanceTo(36.4561, 10.7376); // Nabeul
      final distanceKm = distanceMeters / 1000.0;

      expect(distanceKm, greaterThan(60.0));
      expect(distanceKm, lessThan(75.0));
    });
  });

  group('4. RouteResult - Formatage distance et heure d\'arrivée (ETA)', () {
    test('Formatage des courtes distances (< 1000 m)', () {
      const res = RouteResult(
        points: [],
        distanceMeters: 450.4,
        durationSeconds: 120,
      );
      expect(res.formattedDistance, '450 m');
    });

    test('Formatage des longues distances (>= 1000 m avec virgule)', () {
      const res = RouteResult(
        points: [],
        distanceMeters: 3420.0,
        durationSeconds: 600,
      );
      expect(res.formattedDistance, '3,4 km');
    });

    test('Formatage de l\'ETA prévisible', () {
      final base = DateTime(2026, 11, 6, 14, 20, 0);
      const res = RouteResult(
        points: [],
        distanceMeters: 2000,
        durationSeconds: 900, // +15 minutes -> 14:35
      );
      expect(res.formattedEta(baseTime: base), '14:35');
    });
  });

  group('5. OsrmRoutingService - Stratégie de routage et repli de secours', () {
    test('Repli vol d\'oiseau immédiat (fallbackCrowFliesRoute) à 25 km/h', () {
      final origin = LatLng(36.8065, 10.1815);
      final dest = LatLng(36.8165, 10.1915);

      final fallback = OsrmRoutingService.fallbackCrowFliesRoute(origin, dest);

      expect(fallback.isEstimated, isTrue);
      expect(fallback.points.length, 2);
      expect(fallback.points.first, origin);
      expect(fallback.points.last, dest);
      expect(fallback.distanceMeters, greaterThan(0));
      expect(fallback.durationSeconds, greaterThan(0));
    });

    test('Succès de l\'API OSRM avec mock client', () async {
      final mockClient = MockClient((request) async {
        final mockResponse = {
          'code': 'Ok',
          'routes': [
            {
              'distance': 1500.0,
              'duration': 240.0,
              'geometry': {
                'coordinates': [
                  [10.1815, 36.8065],
                  [10.1850, 36.8100],
                  [10.1915, 36.8165],
                ],
              },
            }
          ]
        };
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final service = OsrmRoutingService(httpClient: mockClient);
      final origin = LatLng(36.8065, 10.1815);
      final dest = LatLng(36.8165, 10.1915);

      final route = await service.getRoute(
        origin: origin,
        destination: dest,
        forceNetwork: true,
      );

      expect(route.isEstimated, isFalse);
      expect(route.distanceMeters, 1500.0);
      expect(route.durationSeconds, 240.0);
      expect(route.points.length, 3);
      expect(route.points.first.latitude, 36.8065);
    });

    test('Échec réseau HTTP (ex: 500 ou timeout) bascule sans planter sur le vol d\'oiseau', () async {
      final failingClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = OsrmRoutingService(httpClient: failingClient);
      final origin = LatLng(36.8065, 10.1815);
      final dest = LatLng(36.8165, 10.1915);

      final route = await service.getRoute(
        origin: origin,
        destination: dest,
        forceNetwork: true,
      );

      // Doit réussir grâce au repli vol d'oiseau
      expect(route.isEstimated, isTrue);
      expect(route.points.length, 2);
    });

    test('Raccourcissement local sans appel réseau quand écart <= 100m et délai < 15s', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        final mockResponse = {
          'code': 'Ok',
          'routes': [
            {
              'distance': 1000.0,
              'duration': 150.0,
              'geometry': {
                'coordinates': [
                  [10.0000, 36.0000],
                  [10.0050, 36.0050],
                  [10.0100, 36.0100],
                ],
              },
            }
          ]
        };
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final service = OsrmRoutingService(httpClient: mockClient);
      final origin1 = LatLng(36.0000, 10.0000);
      final dest = LatLng(36.0100, 10.0100);

      // 1er appel -> appel réseau
      final route1 = await service.getRoute(
        origin: origin1,
        destination: dest,
        forceNetwork: true,
      );
      expect(requestCount, 1);
      expect(route1.points.length, 3);

      // 2e appel : livreur s'est déplacé très proche du tracé (< 100m, délai < 15s)
      final origin2 = LatLng(36.0001, 10.0001);
      final route2 = await service.getRoute(
        origin: origin2,
        destination: dest,
        forceNetwork: false,
      );

      // Aucun nouvel appel HTTP ne doit être fait !
      expect(requestCount, 1);
      expect(route2.points.isNotEmpty, isTrue);
    });
  });

  group('6. AddressUiModel & OrderDeliveryAddress - Persistance des coordonnées GPS', () {
    test('AddressUiModel sérialise latitude et longitude vers Firestore', () {
      const address = AddressUiModel(
        id: 'addr_1',
        recipientName: 'Sami',
        phone: '98123456',
        addressLine: 'Avenue Habib Bourguiba',
        city: 'Nabeul',
        latitude: 36.4561,
        longitude: 10.7376,
      );

      expect(address.hasCoordinates, isTrue);

      final firestoreMap = address.toFirestore();
      expect(firestoreMap['latitude'], 36.4561);
      expect(firestoreMap['longitude'], 10.7376);
    });

    test('AddressUiModel sans coordonnées conserve hasCoordinates == false', () {
      const address = AddressUiModel(
        id: 'addr_2',
        recipientName: 'Sami',
        phone: '98123456',
        addressLine: 'Zone industrielle',
        city: 'Tunis',
      );

      expect(address.hasCoordinates, isFalse);
      expect(address.latitude, isNull);
      expect(address.longitude, isNull);

      final firestoreMap = address.toFirestore();
      expect(firestoreMap.containsKey('latitude'), isFalse);
      expect(firestoreMap.containsKey('longitude'), isFalse);
    });

    test('OrderDeliveryAddress sérialise et désérialise latitude et longitude', () {
      const orderAddr = OrderDeliveryAddress(
        recipientName: 'Ali',
        phone: '98765432',
        addressLine: 'Rue de la République',
        city: 'Sousse',
        latitude: 35.8256,
        longitude: 10.6084,
      );

      expect(orderAddr.hasCoordinates, isTrue);

      final map = orderAddr.toMap();
      expect(map['latitude'], 35.8256);
      expect(map['longitude'], 10.6084);

      final restored = OrderDeliveryAddress.fromMap(map);
      expect(restored.latitude, 35.8256);
      expect(restored.longitude, 10.6084);
      expect(restored.hasCoordinates, isTrue);
    });
  });

  group('7. MockDelivererLocationRepository - Flux simulé pour test autonome', () {
    test('Émet un flux continu de positions le long d\'une boucle', () async {
      final repo = MockDelivererLocationRepository();
      final stream = repo.watchDelivererLocation('mock_driver');

      final firstEvent = await stream.first;

      expect(firstEvent, isNotNull);
      expect(firstEvent!.delivererId, 'mock_driver');
      expect(firstEvent.delivererName, 'Mourad Trabelsi (Simulé)');
      expect(firstEvent.isOnline, isTrue);
      expect(firstEvent.latitude, greaterThan(36.0));
      expect(firstEvent.longitude, greaterThan(10.0));
      expect(firstEvent.vehiclePlate, isNotNull);
    });
  });
}
