/// ============================================================================
/// RÔLE DU FICHIER : Écran interactif de suivi GPS en temps réel du livreur Dokan
/// (`/orders/:orderId/tracking`). Carte FlutterMap (OpenStreetMap), itinéraire OSRM,
/// interpolation fluide du marqueur orienté selon le cap (`heading`), calcul d'ETA,
/// gestion des 8 états métier et arrêt automatique des ressources à la livraison.
/// INTERAGIT AVEC : deliverer_location_repository.dart, osrm_routing_service.dart,
/// firestore_orders_repository.dart, AppColors, go_router.
/// ============================================================================
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_top_bar.dart';
import '../../data/models/deliverer_location.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_status.dart';
import '../../data/repositories/deliverer_location_repository.dart';
import '../../services/osrm_routing_service.dart';

/// Mode d'état de l'écran de suivi
enum TrackingUiState {
  waitingForDriver,
  driverOffline,
  enRoute,
  driverArrived,
  delivered,
  cancelled,
  error,
}

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final OsrmRoutingService _routingService = OsrmRoutingService();

  // Abonnements et contrôleurs
  StreamSubscription<DocumentSnapshot>? _orderSubscription;
  StreamSubscription<DelivererLocation?>? _locationSubscription;

  // Données de commande
  OrderUiModel? _order;
  bool _isLoadingOrder = true;
  String? _orderError;

  // Localisation livreur
  DelivererLocation? _currentLocation;
  int _serverTimeOffset = 0;
  bool _isRtdbError = false;

  // Itinéraire OSRM
  RouteResult? _routeResult;
  bool _isCalculatingRoute = false;

  // Contrôle de caméra et auto-suivi
  bool _isAutoTracking = true;
  bool _initialFitDone = false;

  // Animation fluide d'interpolation du marqueur
  late final AnimationController _markerAnimController;
  late Animation<double> _latAnim;
  late Animation<double> _lonAnim;
  late Animation<double> _headingAnim;

  // Position courante interpolée affichée sur la carte
  LatLng? _interpolatedPos;
  double _interpolatedHeading = 0.0;

  @override
  void initState() {
    super.initState();

    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _markerAnimController.addListener(() {
      if (mounted) {
        setState(() {
          if (_latAnim.value != 0 && _lonAnim.value != 0) {
            _interpolatedPos = LatLng(_latAnim.value, _lonAnim.value);
            _interpolatedHeading = _headingAnim.value;
          }
        });
      }
    });

    _listenToOrder();
  }

  @override
  void dispose() {
    _markerAnimController.dispose();
    _orderSubscription?.cancel();
    _locationSubscription?.cancel();
    _routingService.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// 1. Écoute temps réel de la commande Firestore `orders/{orderId}`
  void _listenToOrder() {
    setState(() {
      _isLoadingOrder = true;
      _orderError = null;
    });

    try {
      final docRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);
      _orderSubscription = docRef.snapshots().listen(
        (snapshot) {
          if (!snapshot.exists) {
            if (mounted) {
              setState(() {
                _isLoadingOrder = false;
                _orderError = 'Commande introuvable.';
              });
            }
            return;
          }

          final order = OrderUiModel.fromFirestore(snapshot);
          final previousDelivererId = _order?.delivererId;

          if (mounted) {
            setState(() {
              _order = order;
              _isLoadingOrder = false;
            });
          }

          // Si la commande est livrée ou annulée : arrêt immédiat de l'écoute GPS
          if (order.status == OrderStatus.delivered ||
              order.status == OrderStatus.cancelled) {
            _stopTracking();
            return;
          }

          // Démarrage ou changement de livreur
          final delivererId = order.delivererId;
          if (delivererId != null &&
              delivererId.isNotEmpty &&
              delivererId != previousDelivererId) {
            _startDelivererTracking(delivererId);
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _isLoadingOrder = false;
              _orderError = 'Impossible de charger la commande : $err';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOrder = false;
          _orderError = 'Erreur initialisation : $e';
        });
      }
    }
  }

  /// 2. Écoute de la position en direct dans Realtime Database
  Future<void> _startDelivererTracking(String delivererId) async {
    await _locationSubscription?.cancel();

    final repo = ref.read(delivererLocationRepositoryProvider);
    _serverTimeOffset = await repo.getServerTimeOffset();

    _locationSubscription = repo.watchDelivererLocation(delivererId).listen(
      (location) {
        if (!mounted) return;

        setState(() {
          _isRtdbError = false;
          _currentLocation = location;
        });

        if (location != null && location.latitude != 0.0 && location.longitude != 0.0) {
          _animateMarkerTo(location);
          _updateRouteIfNeeded(location);

          // Si l'auto-suivi est actif, recentrage animé de la caméra
          if (_isAutoTracking) {
            _mapController.move(location.latLng, _mapController.camera.zoom);
          }

          // Au tout premier point reçu, cadrage d'ensemble livreur + destination
          if (!_initialFitDone) {
            _fitMapBounds(location.latLng);
            _initialFitDone = true;
          }
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isRtdbError = true;
          });
        }
      },
    );
  }

  void _stopTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  /// Animation fluide de transition entre la position précédente et la nouvelle
  void _animateMarkerTo(DelivererLocation newLoc) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final startPos = _interpolatedPos ?? newLoc.latLng;
    final startHeading = _interpolatedHeading;

    if (disableAnimations) {
      _interpolatedPos = newLoc.latLng;
      _interpolatedHeading = newLoc.heading;
      return;
    }

    // Gestion du virage le plus court pour l'angle (0 à 360°)
    double targetHeading = newLoc.heading;
    double diff = targetHeading - startHeading;
    while (diff < -180) {
      diff += 360;
    }
    while (diff > 180) {
      diff -= 360;
    }
    targetHeading = startHeading + diff;

    _latAnim = Tween<double>(begin: startPos.latitude, end: newLoc.latitude).animate(
      CurvedAnimation(parent: _markerAnimController, curve: Curves.easeInOut),
    );
    _lonAnim = Tween<double>(begin: startPos.longitude, end: newLoc.longitude).animate(
      CurvedAnimation(parent: _markerAnimController, curve: Curves.easeInOut),
    );
    _headingAnim = Tween<double>(begin: startHeading, end: targetHeading).animate(
      CurvedAnimation(parent: _markerAnimController, curve: Curves.easeInOut),
    );

    _markerAnimController.forward(from: 0.0);
  }

  /// Calcul et mise à jour de l'itinéraire OSRM vers la destination
  Future<void> _updateRouteIfNeeded(DelivererLocation location) async {
    final destination = _getDestinationLatLng();
    if (destination == null || _isCalculatingRoute) return;

    _isCalculatingRoute = true;
    try {
      final res = await _routingService.getRoute(
        origin: location.latLng,
        destination: destination,
      );
      if (mounted) {
        setState(() {
          _routeResult = res;
        });
      }
    } catch (_) {
    } finally {
      _isCalculatingRoute = false;
    }
  }

  LatLng? _getDestinationLatLng() {
    final addr = _order?.deliveryAddress;
    if (addr != null && addr.hasCoordinates) {
      return LatLng(addr.latitude!, addr.longitude!);
    }
    return null;
  }

  /// Cadre la caméra pour voir à la fois le livreur et l'adresse de destination
  void _fitMapBounds(LatLng driverPos) {
    final dest = _getDestinationLatLng();
    if (dest != null) {
      final bounds = LatLngBounds.fromPoints([driverPos, dest]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50.0),
        ),
      );
    } else {
      _mapController.move(driverPos, 15.0);
    }
  }

  /// Détermine l'état courant selon les règles métier
  TrackingUiState _resolveUiState() {
    if (_isRtdbError) return TrackingUiState.error;
    if (_order == null) return TrackingUiState.waitingForDriver;

    // Statuts de terminaison
    if (_order!.status == OrderStatus.delivered) {
      return TrackingUiState.delivered;
    }
    if (_order!.status == OrderStatus.cancelled) {
      return TrackingUiState.cancelled;
    }

    // Pas encore en livraison ou pas de livreur assigné
    if (_order!.status != OrderStatus.outForDelivery ||
        _order!.delivererId == null ||
        _currentLocation == null) {
      return TrackingUiState.waitingForDriver;
    }

    // Détection arrivée du livreur
    final dest = _getDestinationLatLng();
    final hasDriverArrivedAtTimestamp = _order!.driverArrivedAt != null;
    final isWithin100Meters = dest != null &&
        _currentLocation!.distanceTo(dest.latitude, dest.longitude) <= 100.0;

    if (hasDriverArrivedAtTimestamp || isWithin100Meters) {
      return TrackingUiState.driverArrived;
    }

    // Fraîcheur du livreur (isOnline et âge <= 60s)
    final nowServer = DateTime.now().millisecondsSinceEpoch + _serverTimeOffset;
    final isFresh = _currentLocation!.isFresh(serverNowMillis: nowServer);

    if (!isFresh) {
      return TrackingUiState.driverOffline;
    }

    return TrackingUiState.enRoute;
  }

  Future<void> _callDriver(String phone) async {
    final clean = phone.replaceAll(' ', '').trim();
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingOrder) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppTopBar(title: 'Suivi de livraison', showBackButton: true),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_orderError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AppTopBar(title: 'Suivi de livraison', showBackButton: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
                const SizedBox(height: AppDimens.space16),
                Text(
                  _orderError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppDimens.space16),
                ElevatedButton(
                  onPressed: _listenToOrder,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final uiState = _resolveUiState();
    final destination = _getDestinationLatLng();
    final driverPos = _interpolatedPos ?? _currentLocation?.latLng;
    final initialCenter = driverPos ?? destination ?? const LatLng(36.8065, 10.1815);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Suivi de livraison',
        showBackButton: true,
        actions: [
          // Bouton Mode Démo (pour tester sans app Livreur)
          IconButton(
            tooltip: 'Mode Test Simulé',
            icon: const Icon(Icons.science_outlined, color: AppColors.primary),
            onPressed: () {
              ref
                  .read(delivererLocationRepositoryProvider)
                  .watchDelivererLocation('DEMO_DRIVER');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mode simulation activé : déplacement automatique du livreur.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── 1. CARTE FLUTTERMAP OPENSTREETMAP ──────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 15.0,
              onPositionChanged: (camera, hasGesture) {
                // Si l'utilisateur touche la carte, désactiver le suivi auto
                if (hasGesture && _isAutoTracking) {
                  setState(() => _isAutoTracking = false);
                }
              },
            ),
            children: [
              // Couche de tuiles OpenStreetMap avec userAgent officiel Dokan
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.Dokan.Dokan_client',
              ),

              // Tracé de l'itinéraire OSRM (Polyligne)
              if (_routeResult != null && _routeResult!.points.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routeResult!.points,
                      color: _routeResult!.isEstimated
                          ? AppColors.accent
                          : AppColors.primary,
                      strokeWidth: 4.5,
                      pattern: _routeResult!.isEstimated
                          ? const StrokePattern.dotted()
                          : const StrokePattern.solid(),
                    ),
                  ],
                ),

              // Marqueurs : Livreur + Destination
              MarkerLayer(
                markers: [
                  // Marqueur de Destination (Maison / Adresse de livraison)
                  if (destination != null)
                    Marker(
                      point: destination,
                      width: 48,
                      height: 48,
                      child: Semantics(
                        label: 'Votre adresse de livraison',
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.home_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),

                  // Marqueur du Livreur orienté selon son cap (heading)
                  if (driverPos != null)
                    Marker(
                      point: driverPos,
                      width: 54,
                      height: 54,
                      child: Semantics(
                        label: 'Position en direct de votre livreur',
                        child: _buildDriverMarker(uiState),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── 2. ATTRIBUTION OPENSTREETMAP ──────────────────────────────────
          Positioned(
            left: 8,
            bottom: 220,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          ),

          // ── 3. BOUTON FLOTTANT RECENTRER / AUTO-SUIVI (≥ 48 DP) ────────────
          Positioned(
            right: AppDimens.space16,
            bottom: 230,
            child: Semantics(
              button: true,
              label: _isAutoTracking
                  ? 'Suivi automatique activé'
                  : 'Recentrer la carte sur le livreur',
              child: SizedBox(
                width: 48,
                height: 48,
                child: FloatingActionButton(
                  heroTag: 'recenter_btn',
                  backgroundColor:
                      _isAutoTracking ? AppColors.primary : AppColors.surface,
                  foregroundColor:
                      _isAutoTracking ? AppColors.onPrimary : AppColors.primary,
                  elevation: 4,
                  onPressed: () {
                    setState(() => _isAutoTracking = true);
                    if (driverPos != null) {
                      _mapController.move(driverPos, 16.0);
                    }
                  },
                  child: Icon(
                    _isAutoTracking
                        ? Icons.gps_fixed_rounded
                        : Icons.gps_not_fixed_rounded,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // ── 4. BANDEAU HAUT EN CAS DE LIVREUR ARRIVÉ OU HORS LIGNE ─────────
          if (uiState == TrackingUiState.driverArrived)
            Positioned(
              top: AppDimens.space12,
              left: AppDimens.space16,
              right: AppDimens.space16,
              child: _buildBanner(
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                title: 'Le livreur est arrivé 📍',
                subtitle: 'Il vous attend devant votre domicile. Préparez le paiement en espèces.',
              ),
            )
          else if (uiState == TrackingUiState.driverOffline)
            Positioned(
              top: AppDimens.space12,
              left: AppDimens.space16,
              right: AppDimens.space16,
              child: _buildBanner(
                icon: Icons.wifi_off_rounded,
                color: AppColors.accent,
                title: 'Livreur hors ligne 📡',
                subtitle: _getOfflineSubtitle(),
              ),
            ),

          // ── 5. CARTE D'INFORMATIONS DU BAS (BOTTOM SHEET ARRONDI) ──────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomInfoCard(uiState, destination),
          ),
        ],
      ),
    );
  }

  /// Visuel dynamique du marqueur du livreur
  Widget _buildDriverMarker(TrackingUiState uiState) {
    final isOffline = uiState == TrackingUiState.driverOffline;
    final vehicleIcon = _order?.vehicleIcon ?? Icons.directions_car_rounded;
    final angleRad = (_interpolatedHeading * (3.141592653589793 / 180.0));

    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo pulsant
        if (!isOffline)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
        // Disque principal orienté
        Transform.rotate(
          angle: angleRad,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isOffline ? Colors.grey.shade400 : AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              vehicleIcon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  /// Bandeau d'alerte en haut de la carte
  Widget _buildBanner({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius12),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getOfflineSubtitle() {
    if (_currentLocation == null) {
      return 'En attente de signal...';
    }
    final nowServer = DateTime.now().millisecondsSinceEpoch + _serverTimeOffset;
    final ageMin = (_currentLocation!.ageSeconds(nowServer) / 60).round();
    if (ageMin <= 1) {
      return 'Dernière position connue il y a 1 min.';
    }
    return 'Dernière position connue il y a $ageMin minutes.';
  }

  /// ── CARTE D'INFORMATIONS INFÉRIEURE (BOTTOM SHEET ARRONDI) ───────────────
  Widget _buildBottomInfoCard(TrackingUiState uiState, LatLng? destination) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.space20,
        AppDimens.space16,
        AppDimens.space20,
        AppDimens.space24,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.radius24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de préhension décorative
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppDimens.space12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Contenu selon l'état métier
            _buildStateContent(uiState, destination),
          ],
        ),
      ),
    );
  }

  Widget _buildStateContent(TrackingUiState uiState, LatLng? destination) {
    switch (uiState) {
      // ÉTAT 1 : En attente du livreur
      case TrackingUiState.waitingForDriver:
        return _buildStatusTile(
          emoji: '⏳',
          title: 'Votre livreur n\'est pas encore en route',
          subtitle:
              'Dès que la commande sera prise en charge par le livreur, sa position en direct s\'affichera ici.',
        );

      // ÉTAT 5 : Livraison terminée
      case TrackingUiState.delivered:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusTile(
              emoji: '🎉',
              title: 'Commande livrée avec succès !',
              subtitle: 'Merci d\'avoir fait vos achats chez Dokan.',
            ),
            const SizedBox(height: AppDimens.space16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Voir ma commande'),
            ),
          ],
        );

      // ÉTAT 6 : Commande annulée
      case TrackingUiState.cancelled:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusTile(
              emoji: '❌',
              title: 'Cette commande a été annulée',
              subtitle: 'Le suivi GPS a été désactivé pour cette livraison.',
            ),
            const SizedBox(height: AppDimens.space16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Retour à la commande'),
            ),
          ],
        );

      // ÉTAT 8 : Erreur de connexion / accès RTDB
      case TrackingUiState.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusTile(
              emoji: '⚠️',
              title: 'Suivi indisponible pour le moment',
              subtitle: 'Impossible de joindre le service de localisation en direct.',
            ),
            const SizedBox(height: AppDimens.space12),
            ElevatedButton(
              onPressed: () {
                final id = _order?.delivererId;
                if (id != null) _startDelivererTracking(id);
              },
              child: const Text('Réessayer'),
            ),
          ],
        );

      // ÉTATS 2, 3, 4 (Livreur actif ou hors ligne)
      default:
        return _buildActiveDriverDetails(destination);
    }
  }

  Widget _buildActiveDriverDetails(LatLng? destination) {
    final driverName = _currentLocation?.delivererName ??
        _order?.driver?.name ??
        'Livreur Dokan';
    final vehiclePlate = _order?.effectiveVehiclePlate;
    final vehicleLabel = _order?.vehicleLabel ?? 'Véhicule officiel';
    final driverPhone = _order?.driver?.phone;
    final isDifferentOrder = _currentLocation?.currentOrderId != null &&
        _currentLocation!.currentOrderId!.isNotEmpty &&
        _currentLocation!.currentOrderId != widget.orderId;

    final distanceStr = _routeResult?.formattedDistance ?? '--';
    final etaStr = _routeResult?.formattedEta() ?? '--:--';
    final speedKmh = _currentLocation?.speedKmh ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne livreur + Téléphone
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                _order?.vehicleEmoji ?? '🚚',
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    vehiclePlate != null
                        ? '$vehicleLabel • Matricule $vehiclePlate'
                        : vehicleLabel,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (driverPhone != null && driverPhone.trim().isNotEmpty)
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.onPrimary,
                  minimumSize: const Size(48, 48),
                ),
                tooltip: 'Appeler le livreur',
                icon: const Icon(Icons.phone_rounded),
                onPressed: () => _callDriver(driverPhone),
              ),
          ],
        ),

        const SizedBox(height: AppDimens.space16),

        // Carte métriques : Distance, Arrivée estimée (ETA), Vitesse
        Row(
          children: [
            Expanded(
              child: _buildMetricBox(
                icon: Icons.timelapse_rounded,
                label: 'Arrivée estimée',
                value: etaStr != '--:--' ? 'Vers $etaStr' : '--',
              ),
            ),
            const SizedBox(width: AppDimens.space10),
            Expanded(
              child: _buildMetricBox(
                icon: Icons.straighten_rounded,
                label: 'Distance restante',
                value: distanceStr,
              ),
            ),
            const SizedBox(width: AppDimens.space10),
            Expanded(
              child: _buildMetricBox(
                icon: Icons.speed_rounded,
                label: 'Vitesse',
                value: '${speedKmh.round()} km/h',
              ),
            ),
          ],
        ),

        // Note discrète si adresse sans coordonnées
        if (destination == null) ...[
          const SizedBox(height: AppDimens.space10),
          Row(
            children: const [
              Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
              SizedBox(width: AppDimens.space6),
              Expanded(
                child: Text(
                  'Position de livraison non précisée sur la carte.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Note si le livreur a une autre livraison en cours avant
        if (isDifferentOrder) ...[
          const SizedBox(height: AppDimens.space8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppDimens.radius8),
            ),
            child: Row(
              children: const [
                Text('📦', style: TextStyle(fontSize: 14)),
                SizedBox(width: AppDimens.space8),
                Expanded(
                  child: Text(
                    'Le livreur termine une autre livraison avant la vôtre.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppDimens.radius12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTile({
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(width: AppDimens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
