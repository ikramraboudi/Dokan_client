/// ============================================================================
/// RÔLE DU FICHIER : Modèle de données immuable représentant la position en direct
/// d'un livreur publiée dans Firebase Realtime Database (`deliverers_live/{delivererId}`).
/// Parsing ultra-défensif (ne plante jamais même si des valeurs sont nulles ou mal typées).
/// ============================================================================
library;

import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Position géographique et télémétrie en temps réel d'un livreur.
class DelivererLocation {
  final String delivererId;
  final String delivererName;
  final double latitude;
  final double longitude;
  final double heading;
  final double speed; // En m/s selon le contrat de l'app Livreur
  final int timestamp; // Millisecondes serveur
  final bool isOnline;
  final String? currentOrderId;
  final Map<String, dynamic>? vehicle;

  const DelivererLocation({
    required this.delivererId,
    this.delivererName = 'Livreur',
    required this.latitude,
    required this.longitude,
    this.heading = 0.0,
    this.speed = 0.0,
    this.timestamp = 0,
    this.isOnline = true,
    this.currentOrderId,
    this.vehicle,
  });

  /// Conversion de la vitesse en kilomètres par heure (km/h)
  double get speedKmh => (speed * 3.6).clamp(0.0, 200.0);

  /// Immatriculation du véhicule officiel assigné (si présent)
  String? get vehiclePlate {
    if (vehicle == null) return null;
    final plate = vehicle!['plate'] ??
        vehicle!['matricule'] ??
        vehicle!['assignedVehiclePlate'];
    return plate?.toString();
  }

  /// Type de véhicule (camion, voiture)
  String? get vehicleType {
    if (vehicle == null) return null;
    final type = vehicle!['type'] ?? vehicle!['vehicleType'];
    return type?.toString();
  }

  /// Représentation sous forme d'objet LatLng pour flutter_map
  LatLng get latLng => LatLng(latitude, longitude);

  /// Vérifie la fraîcheur de la position en comparant l'horodatage au temps serveur.
  /// Le livreur est considéré en ligne si `isOnline == true` ET l'âge de la position <= maxAgeSeconds (défaut 300 s / 5 min).
  bool isFresh({required int serverNowMillis, int maxAgeSeconds = 300}) {
    if (!isOnline) return false;
    if (timestamp <= 0) return true; // Horodatage non fourni mais livreur en ligne
    final ageMillis = (serverNowMillis - timestamp).abs();
    return ageMillis <= (maxAgeSeconds * 1000);
  }

  /// Calcule l'âge de la position en secondes par rapport à l'horodatage serveur
  int ageSeconds(int serverNowMillis) {
    final diff = serverNowMillis - timestamp;
    return (diff / 1000).round().clamp(0, 999999);
  }

  /// Calcule la distance orthodromique (formule de Haversine) en mètres jusqu'à une cible.
  double distanceTo(double targetLat, double targetLon) {
    const double earthRadius = 6371000.0; // Rayon en mètres
    final dLat = _degToRad(targetLat - latitude);
    final dLon = _degToRad(targetLon - longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(latitude)) *
            math.cos(_degToRad(targetLat)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Désérialisation ultra-tolérante depuis une Map (Realtime Database DataSnapshot).
  factory DelivererLocation.fromMap(
    String id,
    Map<dynamic, dynamic>? map,
  ) {
    if (map == null) {
      return DelivererLocation(
        delivererId: id,
        latitude: 0.0,
        longitude: 0.0,
        timestamp: 0,
        isOnline: false,
      );
    }

    final rawName = map['delivererName'] ?? map['name'];
    final name = (rawName is String && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : 'Livreur';

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    final lat = parseDouble(map['latitude'] ?? map['lat']);
    final lon = parseDouble(map['longitude'] ?? map['lon'] ?? map['lng']);
    final heading = parseDouble(map['heading']);
    final speed = parseDouble(map['speed']);
    var timestamp = parseInt(map['timestamp']);
    // Conversion automatique si l'horodatage a été écrit en secondes (format UNIX 10 chiffres)
    if (timestamp > 0 && timestamp < 10000000000) {
      timestamp *= 1000;
    }
    final isOnline = map['isOnline'] as bool? ?? true;
    final currentOrderId = map['currentOrderId'] as String?;

    Map<String, dynamic>? vehicleMap;
    if (map['vehicle'] is Map) {
      vehicleMap = Map<String, dynamic>.from(map['vehicle'] as Map);
    }

    return DelivererLocation(
      delivererId: id,
      delivererName: name,
      latitude: lat,
      longitude: lon,
      heading: heading,
      speed: speed,
      timestamp: timestamp,
      isOnline: isOnline,
      currentOrderId: currentOrderId,
      vehicle: vehicleMap,
    );
  }

  Map<String, dynamic> toMap() => {
        'delivererId': delivererId,
        'delivererName': delivererName,
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
        'timestamp': timestamp,
        'isOnline': isOnline,
        if (currentOrderId != null) 'currentOrderId': currentOrderId,
        if (vehicle != null) 'vehicle': vehicle,
      };
}
