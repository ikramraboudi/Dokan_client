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
  final TextEditingController _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _onCheckoutPressed() {
    final session = ref.read(sessionProvider);
    if (session.isGuest) {
      // Visiteur : invite de connexion avec texte exact
      AuthRequiredDialog.show(
        context,
        ref,
        message: 'Connectez-vous pour continuer votre commande.',
        pendingAction: () {
          // Reprise après authentification
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cette fonctionnalité sera disponible prochainement.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      );
    } else {
      // Client connecté : hors périmètre
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette fonctionnalité sera disponible prochainement.'),
          duration: Duration(seconds: 2),
        ),
      );
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

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    final success = await ref.read(cartProvider.notifier).applyPromoCode(code);
    if (success && mounted) {
      _promoController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code promo appliqué avec succès (-10 %) !'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
                      const SizedBox(height: AppDimens.space16),

                      // Section Code Promo
                      _buildPromoSection(cartState),
                      const SizedBox(height: AppDimens.space20),

                      // Récapitulatif des prix
                      PriceSummary(
                        subtotal: cartState.subtotal,
                        discountAmount: cartState.discountAmount,
                        promoCode: cartState.appliedPromoCode,
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

  Widget _buildPromoSection(CartState cartState) {
    if (cartState.appliedPromoCode != null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space12,
        ),
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius: BorderRadius.circular(AppDimens.radius12),
          border: Border.all(color: AppColors.success),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_offer_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: AppDimens.space8),
                Text(
                  'Code promo : ${cartState.appliedPromoCode} (-10 %)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.success,
              tooltip: 'Retirer le code promo',
              onPressed: () {
                ref.read(cartProvider.notifier).removePromoCode();
              },
            ),
          ],
        ),
      );
    }

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
          const Text(
            'Code promotionnel',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _promoController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Ex. Dokan10',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppDimens.space12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.space12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 48),
                ),
                onPressed: cartState.isApplyingPromo ? null : _applyPromo,
                child: cartState.isApplyingPromo
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Text('Appliquer'),
              ),
            ],
          ),
          if (cartState.promoError != null) ...[
            const SizedBox(height: AppDimens.space8),
            Text(
              cartState.promoError!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
