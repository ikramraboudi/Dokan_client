/// ============================================================================
/// RÔLE DU FICHIER : Suivi détaillé du colis avec chronologie verticale horodatée, carte chauffeur et annulation en transaction atomique.
/// INTERAGIT AVEC : singleOrderStreamProvider, cancelOrder(), OrderStatus.
/// POUR L'ORAL : « Cette page trace la chronologie complète du colis, affiche les coordonnées du coursier et permet l'annulation si la commande est en attente. »
/// ============================================================================
/// ============================================================================
/// RÔLE DU FICHIER :
/// Écran « Détail et suivi de commande » (Tracking & Timeline en direct).
/// Écoute en flux continu (Stream) l'état de la commande dans Firestore,
/// affiche la chronologie verticale, les coordonnées du livreur (si assigné),
/// le récapitulatif financier et permet l'annulation si le statut est encore « pending ».
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche feature/orders/ (Interface Utilisateur / Suivi Commande).
///
/// RELATIONS ET DÉPENDANCES :
/// - Déclenché par : MyOrdersScreen ou OrderConfirmationScreen.
/// - Dépend de : singleOrderStreamProvider, ordersRepositoryProvider,
///   order_model.dart, order_status.dart, app_colors.dart, app_dimens.dart.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_top_bar.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/loading_state.dart';
import '../../data/mock/mock_cart_repository.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_status.dart';
import '../../data/repositories/firestore_catalog_repository.dart';
import '../../data/repositories/firestore_orders_repository.dart';
import '../../services/local_order_tracker_service.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocalOrderTrackerService.currentlyViewedOrderId = widget.orderId;
    });
  }

  @override
  void dispose() {
    if (LocalOrderTrackerService.currentlyViewedOrderId == widget.orderId) {
      LocalOrderTrackerService.currentlyViewedOrderId = null;
    }
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    final hours = dt.hour.toString().padLeft(2, '0');
    final minutes = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} à $hours:$minutes';
  }

  void _confirmCancelOrder(BuildContext context, OrderUiModel order) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler cette commande ?'),
        content: Text(
          'Êtes-vous sûr de vouloir annuler la commande ${order.displayNumber} ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Non, garder'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnDark,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              setState(() => _isCancelling = true);
              try {
                // Enregistrement immédiat dans l'état local pour ne pas auto-notifier le client
                await ref
                    .read(localOrderTrackerServiceProvider)
                    .markOrderCancelledByClient(order.id);
                await ref
                    .read(ordersRepositoryProvider)
                    .cancelOrder(order.id);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Votre commande a bien été annulée.'),
                    backgroundColor: AppColors.statusCancelled,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Impossible d\'annuler : $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              } finally {
                if (mounted) setState(() => _isCancelling = false);
              }
            },
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _reorderItems(BuildContext context, OrderUiModel order) async {
    final messenger = ScaffoldMessenger.of(context);
    final catalogRepo = ref.read(firestoreCatalogRepositoryProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    int addedCount = 0;

    for (final item in order.items) {
      final product = await catalogRepo.getProductById(item.productId);
      if (product != null && product.isInStock) {
        await cartNotifier.addProduct(
          product,
          quantity: item.quantity,
          variant: item.variantLabel,
        );
        addedCount++;
      }
    }

    if (addedCount > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$addedCount article(s) ajouté(s) à votre panier.'),
          action: SnackBarAction(
            label: 'Voir le panier',
            onPressed: () => context.go(AppRoutes.cart),
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Les articles de cette commande ne sont plus disponibles.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(singleOrderStreamProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(
        title: 'Suivi de commande',
        showBackButton: true,
      ),
      body: orderAsync.when(
        loading: () => const LoadingState(message: 'Chargement des détails...'),
        error: (err, stack) => ErrorState(
          message: 'Impossible de charger les détails de cette commande.',
          onRetry: () => ref.refresh(singleOrderStreamProvider(widget.orderId)),
        ),
        data: (order) {
          if (order == null) {
            return const ErrorState(message: 'Commande introuvable.');
          }

          final createdDate = order.createdAt.toDate();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. GRANDE CARTE DE STATUT ACTUEL ────────────────────────
                _buildStatusBanner(order),
                const SizedBox(height: AppDimens.space16),

                // ── 2. CARTOUCHE D'IDENTIFIANT & DATE ───────────────────────
                _buildOrderInfoCard(order, createdDate),
                const SizedBox(height: AppDimens.space16),

                // ── 3. CHRONOLOGIE DÉTAILLÉE (TIMELINE VERTICALE) ───────────
                _buildTimelineCard(order),
                const SizedBox(height: AppDimens.space16),

                // ── 4. INFORMATIONS DU LIVREUR ET VÉHICULE OFFICIEL ─────────
                if (order.hasDriverOrVehicle) ...[
                  _buildDriverCard(order),
                  const SizedBox(height: AppDimens.space16),
                ],

                // ── 5. ARTICLES DE LA COMMANDE ──────────────────────────────
                _buildItemsCard(order),
                const SizedBox(height: AppDimens.space16),

                // ── 6. ADRESSE DE LIVRAISON & PAIEMENT ──────────────────────
                _buildDeliveryAndPaymentCard(order),
                const SizedBox(height: AppDimens.space16),

                // ── 7. RÉCAPITULATIF FINANCIER ──────────────────────────────
                _buildPriceSummaryCard(order),
                const SizedBox(height: AppDimens.space24),

                // ── 8. ACTIONS : ANNULER OU COMMANDER À NOUVEAU ─────────────
                if (order.status.canBeCancelledByCustomer) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: _isCancelling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.error,
                            ),
                          )
                        : const Icon(Icons.cancel_outlined),
                    label: const Text('Annuler cette commande'),
                    onPressed: _isCancelling
                        ? null
                        : () => _confirmCancelOrder(context, order),
                  ),
                  const SizedBox(height: AppDimens.space12),
                ],

                ElevatedButton.icon(
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Commander à nouveau les articles'),
                  onPressed: () => _reorderItems(context, order),
                ),
                const SizedBox(height: AppDimens.space32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(OrderUiModel order) {
    final status = order.status;
    final message = switch (status) {
      OrderStatus.pending =>
        'Votre commande a bien été reçue et sera confirmée sous peu.',
      OrderStatus.confirmed =>
        'Votre commande est confirmée par notre équipe.',
      OrderStatus.preparing =>
        'Votre colis est en cours de préparation dans nos entrepôts.',
      OrderStatus.outForDelivery =>
        'Votre colis est entre les mains du livreur, en route vers vous !',
      OrderStatus.delivered =>
        'Votre commande a été livrée avec succès.',
      OrderStatus.failed =>
        'La livraison a échoué. Notre service client va vous contacter.',
      OrderStatus.refused =>
        'Le colis a été refusé à la livraison.',
      OrderStatus.cancelled =>
        'Cette commande a été annulée.',
    };

    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: status.softColor,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: status.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.space8),
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
            child: Icon(status.icon, color: AppColors.textOnDark, size: 22),
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: status.color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppDimens.space4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(OrderUiModel order, DateTime createdDate) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Numéro de commande',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              SelectableText(
                order.displayNumber,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Divider(height: AppDimens.space20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Date de création',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _formatDateTime(createdDate),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (order.estimatedDelivery != null) ...[
            const Divider(height: AppDimens.space20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Livraison estimée',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDateTime(order.estimatedDelivery!.toDate()),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineCard(OrderUiModel order) {
    final history = order.statusHistory;

    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: AppDimens.space8),
              Text(
                'Historique du statut (Temps réel)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),

          if (history.isEmpty)
            const Text(
              'En attente de prise en charge...',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )
          else
            ...List.generate(history.length, (index) {
              final entry = history[index];
              final isLast = index == history.length - 1;
              final isCurrent = index == history.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? entry.status.color
                                : AppColors.primaryLight,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2.5,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: AppColors.border,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppDimens.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.status.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isCurrent
                                    ? entry.status.color
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDateTime(entry.at.toDate()),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDriverCard(OrderUiModel order) {
    final driver = order.driver;
    final plate = order.effectiveVehiclePlate;
    final driverName = driver != null && driver.name.trim().isNotEmpty
        ? driver.name.trim()
        : 'Livreur Dokan';
    final driverPhone = driver != null && driver.phone.trim().isNotEmpty
        ? driver.phone.trim()
        : null;

    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.space10),
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  order.vehicleIcon,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Véhicule officiel Dokan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      driverName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (driverPhone != null)
                      Text(
                        driverPhone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (driverPhone != null)
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.textOnDark,
                  ),
                  icon: const Icon(Icons.phone_rounded),
                  tooltip: 'Appeler le livreur',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: driverPhone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Numéro copié : $driverPhone'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: AppDimens.space12),
          const Divider(height: 1),
          const SizedBox(height: AppDimens.space12),
          // Badges : Type de véhicule + Matricule officiel
          Wrap(
            spacing: AppDimens.space8,
            runSpacing: AppDimens.space8,
            children: [
              // Badge Type : Camion 🚚 ou Voiture 🚗
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space10,
                  vertical: AppDimens.space6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppDimens.radius8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      order.vehicleEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: AppDimens.space6),
                    Text(
                      order.vehicleLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge Matricule
              if (plate != null && plate.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space10,
                    vertical: AppDimens.space6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppDimens.radius8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.pin_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppDimens.space4),
                      Text(
                        'Matricule : $plate',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(OrderUiModel order) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Articles commandés (${order.itemCount})',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Divider(height: AppDimens.space20),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.space6),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radius8),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: AppColors.surfaceAlt,
                      child: item.imageUrl.isNotEmpty
                          ? Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.image_outlined,
                                color: AppColors.textHint,
                              ),
                            )
                          : const Icon(
                              Icons.image_outlined,
                              color: AppColors.textHint,
                            ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (item.variantLabel != null)
                          Text(
                            'Variante : ${item.variantLabel}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        Text(
                          '${item.quantity} × ${item.unitPrice.toStringAsFixed(3)} DT',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.lineTotal.toStringAsFixed(3)} DT',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDeliveryAndPaymentCard(OrderUiModel order) {
    final addr = order.deliveryAddress;

    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: AppDimens.space8),
              Text(
                'Adresse de livraison',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space10,
              vertical: AppDimens.space4,
            ),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppDimens.radius8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Région ${order.regionId.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Text(
                  ' • ',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  order.city,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            addr.recipientName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Text(addr.summary, style: const TextStyle(fontSize: 13)),
          Text('Tél : ${addr.phone}', style: const TextStyle(fontSize: 13)),
          if (addr.deliveryInstructions != null &&
              addr.deliveryInstructions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppDimens.space4),
              child: Text(
                'Instructions : ${addr.deliveryInstructions}',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          const Divider(height: AppDimens.space24),
          Row(
            children: const [
              Icon(Icons.payment_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: AppDimens.space8),
              Text(
                'Paiement',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space6),
          const Text(
            'Paiement à la livraison — à régler en espèces à la réception.',
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummaryCard(OrderUiModel order) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Détail des montants',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Divider(height: AppDimens.space20),
          _buildAmountRow('Sous-total', '${order.subtotal.toStringAsFixed(3)} DT'),
          // Les promotions sont gérées par l'app Admin ; le Client n'écrit jamais de code promo.
          // On affiche la ligne de remise uniquement si une promotion a été appliquée par l'Admin.
          if (order.discount > 0) ...[
            const SizedBox(height: AppDimens.space6),
            _buildAmountRow(
              'Remise${order.promoCode != null ? ' (${order.promoCode})' : ''}',
              '-${order.discount.toStringAsFixed(3)} DT',
              color: AppColors.success,
            ),
          ],
          const SizedBox(height: AppDimens.space6),
          _buildAmountRow(
            'Frais de livraison',
            order.deliveryFee == 0
                ? 'Gratuit'
                : '${order.deliveryFee.toStringAsFixed(3)} DT',
          ),
          const Divider(height: AppDimens.space20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total TTC',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${order.total.toStringAsFixed(3)} DT',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
