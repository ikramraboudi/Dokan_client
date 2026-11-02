/// ============================================================================
/// RÔLE DU FICHIER : Écran Panier réactif avec gestion des quantités, suppression avec annulation et redirection sécurisée.
/// INTERAGIT AVEC : cartProvider, sessionProvider, CheckoutScreen, PriceSummary.
/// POUR L'ORAL : « Le panier permet la modification instantanée des quantités, la suppression avec annulation et invite le visiteur à se connecter. »
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/navigation/routes.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_top_bar.dart';
import '../../core/ui/auth_required_dialog.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/price_summary.dart';
import '../../core/ui/quantity_selector.dart';
import '../../data/mock/mock_cart_repository.dart';
import '../../data/models/cart_item_ui_model.dart';


///  Dokan — ÉCRAN DU PANIER COMPLET

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  void _onCheckoutPressed() {
    final session = ref.read(sessionProvider);
    if (session.isGuest) {
      // Visiteur : invite de connexion avec reprise automatique vers le passage de commande
      AuthRequiredDialog.show(
        context,
        ref,
        message: 'Connectez-vous pour continuer votre commande.',
        pendingAction: () {
          context.push(AppRoutes.checkout);
        },
      );
    } else {
      // Client connecté : transition vers le passage de commande
      context.push(AppRoutes.checkout);
    }
  }

  void _removeCartItem(CartItemUiModel item, int index) {
    final removed = ref.read(cartProvider.notifier).removeItem(item.id);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} retiré du panier.'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Annuler',
          textColor: AppColors.accent,
          onPressed: () {
            if (removed != null) {
              ref.read(cartProvider.notifier).restoreItem(removed, index);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppTopBar(
        title: 'Mon panier',
        actions: [
          if (cartState.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
              },
              child: const Text('Vider'),
            ),
        ],
      ),
      body: cartState.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Votre panier est vide',
              message: 'Votre panier est vide pour le moment.',
              buttonText: 'Découvrir les produits',
              onAction: () => context.go(AppRoutes.home),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppDimens.space16),
                    children: [
                      // Liste des articles
                      ...List.generate(cartState.items.length, (index) {
                        final item = cartState.items[index];
                        return _buildCartItemCard(item, index);
                      }),
                      const SizedBox(height: AppDimens.space20),

                      // Récapitulatif des prix
                      PriceSummary(
                        subtotal: cartState.subtotal,
                        deliveryFee: cartState.deliveryFee,
                        total: cartState.total,
                      ),
                      const SizedBox(height: AppDimens.space24),
                    ],
                  ),
                ),

                // Barre fixe inférieure avec bouton Continuer
                _buildBottomCheckoutBar(cartState),
              ],
            ),
    );
  }

  Widget _buildCartItemCard(CartItemUiModel item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space12),
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image produit
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radius12),
            child: Container(
              width: 80,
              height: 80,
              color: AppColors.surfaceAlt,
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    )
                  : const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(width: AppDimens.space12),

          // Détails
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // Bouton supprimer avec Semantics
                    Semantics(
                      label: 'Supprimer ${item.name} du panier',
                      button: true,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        color: AppColors.textSecondary,
                        tooltip: 'Supprimer',
                        onPressed: () => _removeCartItem(item, index),
                      ),
                    ),
                  ],
                ),

                if (item.variantLabel != null) ...[
                  const SizedBox(height: AppDimens.space4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppDimens.radius8),
                    ),
                    child: Text(
                      'Option : ${item.variantLabel}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppDimens.space8),

                // Prix et sélecteur de quantité
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppConfig.formatPrice(item.unitPrice),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    QuantitySelector(
                      quantity: item.quantity,
                      min: 1,
                      max: 10,
                      enabled: item.isInStock,
                      onChanged: (newQty) {
                        ref.read(cartProvider.notifier).updateQuantity(item.id, newQty);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCheckoutBar(CartState cartState) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total à régler',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  AppConfig.formatPrice(cartState.total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppDimens.space16),
            Expanded(
              child: ElevatedButton(
                onPressed: _onCheckoutPressed,
                child: const Text('Continuer la commande'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
