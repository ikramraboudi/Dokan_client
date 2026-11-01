/// ============================================================================
/// RÔLE DU FICHIER :
/// Écran « Mes commandes » (historique et suivi en direct des colis).
/// Inspiré du design de suivi de colis moderne avec rubans diagonaux,
/// barre d'étapes à 4 jalons avec camion animé, filtres par statut avec compteurs
/// et recherche en local par numéro ou nom d'article.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche feature/orders/ (Interface Utilisateur / Commandes).
///
/// RELATIONS ET DÉPENDANCES :
/// - Déclenché par : ProfileScreen, OrderConfirmationScreen, routes.dart.
/// - Dépend de : myOrdersStreamProvider, order_model.dart, order_status.dart,
///   app_colors.dart, app_dimens.dart, routes.dart.
/// ============================================================================
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_status.dart';
import '../../data/repositories/firestore_orders_repository.dart';
import '../../services/auth_service.dart';

enum OrderFilterTab {
  all('Toutes'),
  pending('En attente'),
  preparing('En préparation'),
  outForDelivery('En livraison'),
  delivered('Livrées'),
  cancelled('Annulées');

  final String label;
  const OrderFilterTab(this.label);
}

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  OrderFilterTab _selectedFilter = OrderFilterTab.all;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _searchQuery = value.trim().toLowerCase());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final authService = AuthService();
    final firebaseUser = authService.currentUser;

    if (session.isGuest || firebaseUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mes commandes'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Connexion requise',
          message: 'Connectez-vous pour consulter et suivre vos commandes en temps réel.',
          buttonText: 'Se connecter',
          onAction: () => context.push(AppRoutes.login),
        ),
      );
    }

    final ordersAsync = ref.watch(myOrdersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. EN-TÊTE DÉGRADÉ DOUX + RECHERCHE ─────────────────────────
            _buildHeader(context),

            // ── 2. CONTENU PRINCIPAL AVEC PULL-TO-REFRESH ───────────────────
            Expanded(
              child: ordersAsync.when(
                loading: () => _buildShimmerLoading(),
                error: (error, stack) => ErrorState(
                  message: 'Erreur lors du chargement des commandes.',
                  onRetry: () => ref.refresh(myOrdersStreamProvider),
                ),
                data: (allOrders) {
                  // Calcul des compteurs par statut
                  final countAll = allOrders.length;
                  final countPending = allOrders
                      .where((o) => o.status == OrderStatus.pending)
                      .length;
                  final countPreparing = allOrders
                      .where((o) =>
                          o.status == OrderStatus.confirmed ||
                          o.status == OrderStatus.preparing)
                      .length;
                  final countOutForDelivery = allOrders
                      .where((o) => o.status == OrderStatus.outForDelivery)
                      .length;
                  final countDelivered = allOrders
                      .where((o) => o.status == OrderStatus.delivered)
                      .length;
                  final countCancelled = allOrders
                      .where((o) => o.status == OrderStatus.cancelled)
                      .length;

                  // Filtrage selon l'onglet
                  var filtered = allOrders.where((order) {
                    return switch (_selectedFilter) {
                      OrderFilterTab.all => true,
                      OrderFilterTab.pending =>
                        order.status == OrderStatus.pending,
                      OrderFilterTab.preparing =>
                        order.status == OrderStatus.confirmed ||
                            order.status == OrderStatus.preparing,
                      OrderFilterTab.outForDelivery =>
                        order.status == OrderStatus.outForDelivery,
                      OrderFilterTab.delivered =>
                        order.status == OrderStatus.delivered,
                      OrderFilterTab.cancelled =>
                        order.status == OrderStatus.cancelled,
                    };
                  }).toList();

                  // Filtrage par texte de recherche
                  if (_searchQuery.isNotEmpty) {
                    filtered = filtered.where((o) {
                      final matchNumber =
                          o.displayNumber.toLowerCase().contains(_searchQuery);
                      final matchItem = o.items.any((i) =>
                          i.name.toLowerCase().contains(_searchQuery));
                      return matchNumber || matchItem;
                    }).toList();
                  }

                  return Column(
                    children: [
                      // Puces de filtres horizontales avec compteurs
                      _buildFilterChips(
                        countAll: countAll,
                        countPending: countPending,
                        countPreparing: countPreparing,
                        countOutForDelivery: countOutForDelivery,
                        countDelivered: countDelivered,
                        countCancelled: countCancelled,
                      ),
                      const SizedBox(height: AppDimens.space8),

                      // Liste des commandes
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async {
                            ref.invalidate(myOrdersStreamProvider);
                          },
                          child: filtered.isEmpty
                              ? _buildEmptyOrNoResultView(allOrders.isEmpty)
                              : ListView.separated(
                                  padding: const EdgeInsets.only(
                                    left: AppDimens.space16,
                                    right: AppDimens.space16,
                                    top: AppDimens.space8,
                                    bottom: AppDimens.space32,
                                  ),
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: AppDimens.space16),
                                  itemBuilder: (context, index) {
                                    return _OrderCard(order: filtered[index]);
                                  },
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.space16,
        AppDimens.space12,
        AppDimens.space16,
        AppDimens.space16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primarySoft,
            AppColors.background,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Retour',
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: AppDimens.space4),
              const Expanded(
                child: Text(
                  'Mes commandes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Actualiser',
                icon: Container(
                  padding: const EdgeInsets.all(AppDimens.space6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                onPressed: () => ref.refresh(myOrdersStreamProvider),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space12),

          // Barre de recherche arrondie
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radius24),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher une commande (numéro, produit)...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space16,
                  vertical: AppDimens.space12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips({
    required int countAll,
    required int countPending,
    required int countPreparing,
    required int countOutForDelivery,
    required int countDelivered,
    required int countCancelled,
  }) {
    final chips = [
      (OrderFilterTab.all, 'Toutes', countAll),
      (OrderFilterTab.pending, 'En attente', countPending),
      (OrderFilterTab.preparing, 'En préparation', countPreparing),
      (OrderFilterTab.outForDelivery, 'En livraison', countOutForDelivery),
      (OrderFilterTab.delivered, 'Livrées', countDelivered),
      (OrderFilterTab.cancelled, 'Annulées', countCancelled),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
      child: Row(
        children: chips.map((entry) {
          final isSelected = _selectedFilter == entry.$1;
          return Padding(
            padding: const EdgeInsets.only(right: AppDimens.space8),
            child: InkWell(
              onTap: () => setState(() => _selectedFilter = entry.$1),
              borderRadius: BorderRadius.circular(AppDimens.radius20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space14,
                  vertical: AppDimens.space8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.textPrimary : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radius20),
                  border: Border.all(
                    color: isSelected ? AppColors.textPrimary : AppColors.border,
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Text(
                      entry.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? AppColors.textOnDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.surface.withValues(alpha: 0.25)
                            : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppDimens.radius12),
                      ),
                      child: Text(
                        '${entry.$3}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.textOnDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyOrNoResultView(bool hasNoOrdersAtAll) {
    if (hasNoOrdersAtAll) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Vous n\'avez pas encore de commande.',
        message: 'Découvrez nos nouveautés et promotions pour passer votre première commande !',
        buttonText: 'Découvrir les produits',
        onAction: () => context.go(AppRoutes.home),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 54, color: AppColors.textHint),
            const SizedBox(height: AppDimens.space12),
            const Text(
              'Aucune commande trouvée',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimens.space4),
            const Text(
              'Essayez de modifier votre filtre ou votre recherche.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimens.space16),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = OrderFilterTab.all;
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              child: const Text('Réinitialiser les filtres'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.space16),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: AppDimens.space16),
      itemBuilder: (context, index) => Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radius20),
          border: Border.all(color: AppColors.border),
        ),
      ),
    );
  }
}

/// Carte représentant une commande dans la liste.
class _OrderCard extends StatelessWidget {
  final OrderUiModel order;

  const _OrderCard({required this.order});

  String _formatDate(DateTime dt) {
    const months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final otherItemsCount = order.items.length - 1;
    final createdDate = order.createdAt.toDate();

    return InkWell(
      onTap: () {
        context.push('${AppRoutes.myOrders}/${order.id}');
      },
      borderRadius: BorderRadius.circular(AppDimens.radius20),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radius20),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── LIGNE DU HAUT : MINIATURE + TITRE + NUMÉRO ────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Miniature du premier produit avec Hero
                      Hero(
                        tag: 'order_hero_${order.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimens.radius12),
                          child: Container(
                            width: 58,
                            height: 58,
                            color: AppColors.surfaceAlt,
                            child: (firstItem != null && firstItem.imageUrl.isNotEmpty)
                                ? Image.network(
                                    firstItem.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.image_outlined,
                                      color: AppColors.textHint,
                                    ),
                                  )
                                : const Icon(
                                    Icons.inventory_2_outlined,
                                    color: AppColors.textHint,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimens.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ID : ${order.displayNumber}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: AppDimens.space4),
                            Text(
                              firstItem?.name ?? 'Commande Dokan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (otherItemsCount > 0)
                              Text(
                                '+ $otherItemsCount autre${otherItemsCount > 1 ? 's' : ''} article${otherItemsCount > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Espace réservé pour éviter le chevauchement avec le ruban
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space16),

                  // ── BARRE DE PROGRESSION EN 4 ÉTAPES ──────────────────────
                  _OrderProgressBar(status: order.status),
                  const SizedBox(height: AppDimens.space16),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: AppDimens.space12),

                  // ── LIGNE DU BAS : DE / VERS / TOTAL ──────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'DE : ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Dokan • ${_formatDate(createdDate)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimens.space2),
                            Row(
                              children: [
                                const Text(
                                  'VERS : ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    order.deliveryAddress.city,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (order.estimatedDelivery != null) ...[
                              const SizedBox(height: AppDimens.space2),
                              Text(
                                'Livraison estimée : ${_formatDate(order.estimatedDelivery!.toDate())}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'TOTAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${order.total.toStringAsFixed(3)} DT',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── RUBAN DIAGONAL DANS LE COIN SUPÉRIEUR DROIT ──────────────────
            Positioned(
              top: 14,
              right: -28,
              child: Transform.rotate(
                angle: 0.785398, // 45 degrés
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  color: order.status.color,
                  alignment: Alignment.center,
                  child: Text(
                    order.status.label.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barre de progression en 4 étapes avec camion et pointillés.
class _OrderProgressBar extends StatelessWidget {
  final OrderStatus status;

  const _OrderProgressBar({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space12,
          vertical: AppDimens.space8,
        ),
        decoration: BoxDecoration(
          color: AppColors.statusCancelledSoft,
          borderRadius: BorderRadius.circular(AppDimens.radius8),
        ),
        child: Row(
          children: const [
            Icon(Icons.cancel_outlined, size: 16, color: AppColors.statusCancelled),
            SizedBox(width: AppDimens.space8),
            Text(
              'Commande annulée',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.statusCancelled,
              ),
            ),
          ],
        ),
      );
    }

    final currentStep = status.progressStep; // 0, 1, 2, 3
    final stepLabels = ['Reçue', 'Préparation', 'En livraison', 'Livrée'];

    return Column(
      children: [
        // Ligne avec les points et les pointillés
        Row(
          children: List.generate(7, (index) {
            // Indices pairs = Jalons (0, 2, 4, 6 -> Jalons 0, 1, 2, 3)
            if (index.isEven) {
              final stepIndex = index ~/ 2;
              final isPassed = stepIndex <= currentStep;
              final isCurrent = stepIndex == currentStep;

              return Container(
                width: isCurrent ? 28 : 16,
                height: isCurrent ? 28 : 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? status.color
                      : (isPassed ? AppColors.primary : AppColors.surfaceAlt),
                  border: Border.all(
                    color: isPassed ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: status.color.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isCurrent
                    ? const Icon(
                        Icons.local_shipping_rounded,
                        size: 15,
                        color: AppColors.textOnDark,
                      )
                    : (isPassed
                        ? const Icon(
                            Icons.check,
                            size: 10,
                            color: AppColors.textOnDark,
                          )
                        : null),
              );
            } else {
              // Indices impairs = Ligne pointillée
              final lineBeforeStep = index ~/ 2;
              final isPassed = lineBeforeStep < currentStep;

              return Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final dotCount = (constraints.maxWidth / 6).floor().clamp(2, 20);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        dotCount,
                        (_) => Container(
                          width: 3,
                          height: 2,
                          decoration: BoxDecoration(
                            color: isPassed
                                ? AppColors.primary
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }
          }),
        ),
        const SizedBox(height: AppDimens.space6),

        // Libellés sous chaque jalon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            final isCurrent = index == currentStep;
            return Expanded(
              child: Text(
                stepLabels[index],
                textAlign: index == 0
                    ? TextAlign.left
                    : (index == 3 ? TextAlign.right : TextAlign.center),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent ? status.color : AppColors.textSecondary,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
