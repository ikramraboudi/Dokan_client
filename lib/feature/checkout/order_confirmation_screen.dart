/// ============================================================================
/// RÔLE DU FICHIER : Écran de confirmation avec animation de rebond de la coche verte, numéro lisible et blocage du retour arrière.
/// INTERAGIT AVEC : singleOrderStreamProvider, MyOrdersScreen, HomeScreen.
/// POUR L'ORAL : « Cet écran rassure l'acheteur avec une animation de succès, affiche son numéro DK-AAMMJJ-XXXX et bloque le retour arrière via PopScope. »
/// ============================================================================
/// ============================================================================
/// RÔLE DU FICHIER :
/// Écran « Confirmation de commande » après création réussie dans Firestore.
/// Comprend une animation de succès fluide, le numéro lisible de commande,
/// un résumé succinct et les options pour suivre la commande ou revenir à l'accueil.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche feature/checkout/ (Interface Utilisateur / Succès Commande).
///
/// RELATIONS ET DÉPENDANCES :
/// - Déclenché par : CheckoutScreen après confirmation Firestore.
/// - Dépend de : singleOrderStreamProvider, app_colors.dart, routes.dart.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/repositories/firestore_orders_repository.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  final String orderId;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(singleOrderStreamProvider(orderId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.space24),
              child: orderAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 72, color: AppColors.success),
                    const SizedBox(height: AppDimens.space16),
                    const Text('Commande enregistrée !'),
                    const SizedBox(height: AppDimens.space16),
                    ElevatedButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: const Text('Retour à l\'accueil'),
                    ),
                  ],
                ),
                data: (order) {
                  final displayNumber = order?.displayNumber ?? orderId;
                  final itemCount = order?.itemCount ?? 0;
                  final total = order?.total ?? 0.0;
                  final city = order?.deliveryAddress.city ?? '';

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── ANIMATION DE SUCCÈS LÉGÈRE (~600 ms) ───────────────
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: AppColors.successSoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.success,
                                  width: 2.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.shadow,
                                    blurRadius: 16,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 54,
                                color: AppColors.success,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppDimens.space24),

                      Text(
                        'Commande enregistrée !',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: AppDimens.space8),
                      const Text(
                        'Votre commande a bien été enregistrée et transmise à notre équipe pour préparation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space24),

                      // ── CARTOUCHE DU NUMÉRO DE COMMANDE ────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.space20,
                          vertical: AppDimens.space16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDimens.radius16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'NUMÉRO DE COMMANDE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppDimens.space6),
                            SelectableText(
                              displayNumber,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Divider(height: AppDimens.space24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem(
                                  label: 'Articles',
                                  value: '$itemCount',
                                ),
                                _buildSummaryItem(
                                  label: 'Total',
                                  value: '${total.toStringAsFixed(3)} DT',
                                ),
                                _buildSummaryItem(
                                  label: 'Destination',
                                  value: city.isNotEmpty ? city : 'Tunisie',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.space32),

                      // ── BOUTONS D'ACTION ───────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.receipt_long_rounded),
                          label: const Text('Voir ma commande'),
                          onPressed: () {
                            context.push('${AppRoutes.myOrders}/$orderId');
                          },
                        ),
                      ),
                      const SizedBox(height: AppDimens.space12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.home_outlined),
                          label: const Text('Retour à l\'accueil'),
                          onPressed: () => context.go(AppRoutes.home),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimens.space4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
