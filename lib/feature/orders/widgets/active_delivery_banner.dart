/// ============================================================================
/// RÔLE DU FICHIER : Bandeau interactif sur l'écran d'accueil détectant automatiquement
///                   une commande en cours d'acheminement et invitant le client à
///                   confirmer la réception en scannant le QR code du livreur.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_status.dart';
import '../../../data/repositories/firestore_orders_repository.dart';

class ActiveDeliveryBanner extends ConsumerWidget {
  const ActiveDeliveryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersStreamProvider);

    return ordersAsync.when(
      data: (orders) {
        // Recherche de la première commande en cours d'acheminement (En livraison ou En cours avec livreur)
        final activeOrder = orders.cast<OrderUiModel?>().firstWhere(
              (o) =>
                  o != null &&
                  (o.status == OrderStatus.outForDelivery ||
                      (o.status == OrderStatus.confirmed && o.driver != null)),
              orElse: () => null,
            );

        if (activeOrder == null) {
          return const SizedBox.shrink();
        }

        final driverName = activeOrder.driver?.name.trim();
        final effectiveDriver = (driverName != null && driverName.isNotEmpty)
            ? driverName
            : 'Votre livreur Dokan';

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space16,
            vertical: AppDimens.space8,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDimens.radius20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppDimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4ADE80),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'LIVRAISON EN COURS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4ADE80),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeOrder.displayNumber,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$effectiveDriver arrive à votre adresse.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.space14),

                // Bouton bien visible pour lancer le scanner de confirmation
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F766E),
                    minimumSize: const Size.fromHeight(46),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radius12),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                  label: const Text(
                    'Confirmer la réception (Scanner QR Livreur)',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  onPressed: () {
                    context.push(
                      '${AppRoutes.myOrders}/${activeOrder.id}/scan-qr',
                      extra: activeOrder,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
