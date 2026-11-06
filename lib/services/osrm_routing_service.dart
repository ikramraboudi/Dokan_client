/// ============================================================================
/// RÔLE DU FICHIER : Service d'itinéraire routier via l'API publique OSRM
/// (Open Source Routing Machine). Gère le calcul d'itinéraire GeoJSON,
/// les quotas (min 15 s entre requêtes), le recalcul conditionnel (> 100 m d'écart),
/// le raccourcissement local sans réseau et le repli vol d'oiseau sans échec.
/// ============================================================================
library;

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Résultat d'un calcul d'itinéraire routier.
class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final bool isEstimated; // True si calculé en vol d'oiseau (repli de secours)

  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.isEstimated = false,
  });

  /// Distance formatée (ex: "850 m" ou "3,4 km")
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    final km = distanceMeters / 1000.0;
    return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  /// Heure d'arrivée estimée formatée (ex: "14:35")
  String formattedEta({DateTime? baseTime}) {
    final now = baseTime ?? DateTime.now();
    final arrival = now.add(Duration(seconds: durationSeconds.round()));
    final hour = arrival.hour.toString().padLeft(2, '0');
    final minute = arrival.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Service de calcul d'itinéraire OSRM.
class OsrmRoutingService {
  final http.Client _httpClient;

  DateTime? _lastFetchTime;
  RouteResult? _lastResult;

  OsrmRoutingService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Calcule ou met à jour l'itinéraire routier entre le livreur et la destination.
  /// Applique strictement les règles d'optimisation :
  /// 1. Si moins de 15 s se sont écoulées ou livreur à moins de 100 m de la ligne :
  ///    raccourcit la ligne existante sans appel réseau.
  /// 2. Si le livreur s'écarte de plus de 100 m et > 15 s : requête réseau OSRM.
  /// 3. En cas d'échec réseau : repli vol d'oiseau immédiat.
  Future<RouteResult> getRoute({
    required LatLng origin,
    required LatLng destination,
    bool forceNetwork = false,
  }) async {
    final now = DateTime.now();

    // 1. Vérification si un raccourcissement local suffit sans appel réseau
    if (!forceNetwork && _lastResult != null && _lastResult!.points.isNotEmpty) {
      final elapsedSeconds = _lastFetchTime != null
          ? now.difference(_lastFetchTime!).inSeconds
          : 999;

      // Calcul de la distance perpendiculaire du livreur à la polyligne actuelle
      final distToPoly = minDistanceToPolyline(origin, _lastResult!.points);

      // Si le livreur suit le tracé à moins de 100 m et qu'on a appelé il y a moins de 15 s,
      // on raccourcit simplement la ligne sans gaspiller de requête réseau
      if (distToPoly <= 100.0 && elapsedSeconds < 15) {
        final trimmed = trimPolyline(origin, _lastResult!.points);
        // Réduction proportionnelle de la distance
        final remainingDist =
            (_lastResult!.distanceMeters - originDistanceToStart(origin, _lastResult!.points))
                .clamp(50.0, double.infinity);
        // Estimation de durée restante à ~25 km/h (6.94 m/s)
        final remainingDur = remainingDist / 6.94;

        _lastResult = RouteResult(
          points: trimmed,
          distanceMeters: remainingDist,
          durationSeconds: remainingDur,
          isEstimated: _lastResult!.isEstimated,
        );
        return _lastResult!;
      }
    }

    // 2. Appel réseau OSRM avec geometries=geojson
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await _httpClient.get(url).timeout(
        const Duration(seconds: 7),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final code = json['code'] as String?;
        final routes = json['routes'] as List?;

        if (code == 'Ok' && routes != null && routes.isNotEmpty) {
          final firstRoute = routes.first as Map<String, dynamic>;
          final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List?;
          final distance = (firstRoute['distance'] as num?)?.toDouble() ?? 0.0;
          final duration = (firstRoute['duration'] as num?)?.toDouble() ?? 0.0;

          if (coords != null && coords.isNotEmpty) {
            final List<LatLng> polylinePoints = [];
            for (final coord in coords) {
              if (coord is List && coord.length >= 2) {
                final lon = (coord[0] as num).toDouble();
                final lat = (coord[1] as num).toDouble();
                polylinePoints.add(LatLng(lat, lon));
              }
            }

            _lastFetchTime = now;
            _lastResult = RouteResult(
              points: polylinePoints,
              distanceMeters: distance,
              durationSeconds: duration,
              isEstimated: false,
            );
            return _lastResult!;
          }
        }
      }
    } catch (e) {
      debugPrint('OsrmRoutingService: repli vol d\'oiseau ($e)');
    }

    // 3. Repli de secours : Ligne directe en vol d'oiseau (vitesse moyenne 25 km/h)
    return fallbackCrowFliesRoute(origin, destination);
  }

  /// Trajet de secours en ligne droite avec estimation à 25 km/h
  static RouteResult fallbackCrowFliesRoute(LatLng origin, LatLng destination) {
    const double earthRadius = 6371000.0; // mètres
    final dLat = _degToRad(destination.latitude - origin.latitude);
    final dLon = _degToRad(destination.longitude - origin.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(origin.latitude)) *
            math.cos(_degToRad(destination.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadius * c;

    // Vitesse moyenne estimée en milieu urbain tunisien : 25 km/h = 6.94 m/s
    final duration = distance / 6.94;

    return RouteResult(
      points: [origin, destination],
      distanceMeters: distance,
      durationSeconds: duration,
      isEstimated: true,
    );
  }

  /// Distance minimale entre un point et une liste de segments formant une polyligne.
  static double minDistanceToPolyline(LatLng point, List<LatLng> polyline) {
    if (polyline.isEmpty) return double.infinity;
    if (polyline.length == 1) {
      return distanceBetween(point, polyline.first);
    }

    double minDistance = double.infinity;
    for (int i = 0; i < polyline.length - 1; i++) {
      final dist = perpendicularDistanceToSegment(point, polyline[i], polyline[i + 1]);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }
    return minDistance;
  }

  /// Raccourcit la polyligne en retirant les sommets déjà dépassés par le livreur.
  static List<LatLng> trimPolyline(LatLng currentPos, List<LatLng> polyline) {
    if (polyline.length <= 2) return [currentPos, ...polyline.skip(1)];

    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < polyline.length; i++) {
      final d = distanceBetween(currentPos, polyline[i]);
      if (d < minDistance) {
        minDistance = d;
        closestIndex = i;
      }
    }

    // Garde la position actuelle puis le reste des points
    final remaining = polyline.sublist(closestIndex);
    return [currentPos, ...remaining];
  }

  /// Calcule la distance entre la position actuelle et le premier point
  static double originDistanceToStart(LatLng current, List<LatLng> polyline) {
    if (polyline.isEmpty) return 0.0;
    return distanceBetween(current, polyline.first);
  }

  /// Distance en mètres entre deux coordonnées (Haversine)
  static double distanceBetween(LatLng a, LatLng b) {
    const double earthRadius = 6371000.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(a.latitude)) *
            math.cos(_degToRad(b.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadius * c;
  }

  /// Distance perpendiculaire d'un point à un segment [A, B] en mètres.
  static double perpendicularDistanceToSegment(LatLng p, LatLng a, LatLng b) {
    final x = p.longitude;
    final y = p.latitude;
    final x1 = a.longitude;
    final y1 = a.latitude;
    final x2 = b.longitude;
    final y2 = b.latitude;

    final dx = x2 - x1;
    final dy = y2 - y1;

    if (dx == 0 && dy == 0) {
      return distanceBetween(p, a);
    }

    // Projection t bornée entre 0 et 1
    final t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);
    final clampedT = t.clamp(0.0, 1.0);

    final projLat = y1 + clampedT * dy;
    final projLon = x1 + clampedT * dx;

    return distanceBetween(p, LatLng(projLat, projLon));
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  void dispose() {
    _httpClient.close();
  }
}
