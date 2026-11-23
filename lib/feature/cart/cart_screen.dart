/// ============================================================================
/// RÔLE DU FICHIER : Écran Panier réactif avec gestion des quantités, suppression avec annulation, code promo Firestore et redirection sécurisée.
/// INTERAGIT AVEC : cartProvider, sessionProvider, CheckoutScreen, PriceSummary.
/// POUR L'ORAL : « Le panier permet la modification instantanée des quantités, l'application de coupons Firestore en temps réel et invite le visiteur à se connecter. »
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
import '../../core/utils/product_options.dart';
import '../../data/mock/mock_cart_repository.dart';
import '../../data/models/cart_item_ui_model.dart';
import '../../services/auth_service.dart';

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
      AuthRequiredDialog.show(
        context,
        ref,
        message: 'Connectez-vous pour continuer votre commande.',
        pendingAction: () {
          context.push(AppRoutes.checkout);
        },
      );
    } else {
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

  void _applyPromoCode() {
    FocusScope.of(context).unfocus();
    if (ref.read(cartProvider).isApplyingPromo) return;
    final code = _promoController.text.trim();
    if (code.isEmpty) return;
    final currentUserId = AuthService().currentUser?.uid;
    ref.read(cartProvider.notifier).applyPromoCode(
          code,
          userId: currentUserId,
        );
  }

  static const double kFreeDeliveryThreshold = 150.0;

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
                _promoController.clear();
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
                      // Grand titre « Votre panier » avec nombre d'articles en petit dessous
                      _buildCartTitle(cartState),
                      const SizedBox(height: AppDimens.space16),

                      // Carte verte d'avancement vers la livraison offerte (seuil 150 DT)
                      _buildFreeDeliveryCard(cartState),
                      const SizedBox(height: AppDimens.space12),

                      // Bannière d'affectation du véhicule (voiture ou camion)
                      _buildVehicleBanner(cartState),
                      const SizedBox(height: AppDimens.space16),

                      // Liste des articles
                      ...List.generate(cartState.items.length, (index) {
                        final item = cartState.items[index];
                        return _buildAnimatedCartItemCard(item, index);
                      }),
                      const SizedBox(height: AppDimens.space16),

                      // Section Code Promotionnel
                      _buildPromoSection(cartState),
                      const SizedBox(height: AppDimens.space20),

                      // Récapitulatif des prix
                      PriceSummary(
                        subtotal: cartState.subtotal,
                        deliveryFee: cartState.deliveryFee,
                        total: cartState.total,
                        discount: cartState.discountAmount,
                        promoCode: cartState.appliedPromoCode,
                        totalPoids: cartState.totalPoids,
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

  /// Grand titre « Votre panier » avec sous-titre dynamique
  Widget _buildCartTitle(CartState cartState) {
    final count = cartState.totalItemCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Votre panier',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          count == 1 ? '1 article sélectionné' : '$count articles sélectionnés',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Carte verte d'avancement vers la livraison offerte avec jauge animée
  Widget _buildFreeDeliveryCard(CartState cartState) {
    final subtotal = cartState.subtotal;
    final isFree = subtotal >= kFreeDeliveryThreshold;
    final remaining = (kFreeDeliveryThreshold - subtotal).clamp(0.0, kFreeDeliveryThreshold);
    final progress = (subtotal / kFreeDeliveryThreshold).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppDimens.space14),
      decoration: BoxDecoration(
        color: isFree ? AppColors.successSoft : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(
          color: isFree ? AppColors.success : AppColors.primaryLight,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFree ? Icons.check_circle_rounded : Icons.local_shipping_outlined,
                color: isFree ? AppColors.success : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppDimens.space10),
              Expanded(
                child: Text(
                  isFree
                      ? 'Livraison offerte !'
                      : 'Plus que ${AppConfig.formatPrice(remaining)} pour la livraison offerte',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isFree ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isFree ? AppColors.success : AppColors.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Wrapper animé pour chaque ligne d'article
  Widget _buildAnimatedCartItemCard(CartItemUiModel item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + (index * 40)),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: _buildCartItemCard(item, index),
    );
  }

  /// Bannière d'affectation automatique du véhicule de livraison (Voiture vs Camion)
  Widget _buildVehicleBanner(CartState cartState) {
    final isTruck = cartState.requiresTruck;
    final bgColor = isTruck
        ? AppColors.warning.withValues(alpha: 0.12)
        : AppColors.info.withValues(alpha: 0.10);
    final borderColor = isTruck
        ? AppColors.warning.withValues(alpha: 0.6)
        : AppColors.info.withValues(alpha: 0.4);
    final iconColor = isTruck ? const Color(0xFFE65100) : AppColors.info;
    final icon = isTruck ? Icons.local_shipping : Icons.directions_car;
    final message = isTruck
        ? 'Camion requis : Poids lourd (> 50 kg ou article > 30 kg). Livraison assurée par un camion de service.'
        : 'Livraison standard en voiture.';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space12,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radius12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isTruck ? FontWeight.w600 : FontWeight.w500,
                color: isTruck ? const Color(0xFFBF360C) : AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Encadré de gestion des codes promotionnels
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
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 22,
            ),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code ${cartState.appliedPromoCode} appliqué',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Économie : ${AppConfig.formatPrice(cartState.discountAmount)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space8,
                  vertical: AppDimens.space4,
                ),
              ),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text(
                'Retirer',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                ref.read(cartProvider.notifier).removePromoCode();
                _promoController.clear();
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
                      hintText: 'Ex. PROMO70',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppDimens.space12,
                        vertical: 12,
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
                onPressed: cartState.isApplyingPromo ? null : _applyPromoCode,
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

                if (item.selectedColor != null || item.selectedSize != null) ...[
                  ProductVariantIndicator(
                    colorKey: item.selectedColor,
                    size: item.selectedSize,
                  ),
                  const SizedBox(height: AppDimens.space4),
                ],

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

                // Badge de poids unitaire et total ligne
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.scale_outlined,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.poids > 0
                            ? (item.quantity > 1
                                ? '${item.quantity} × ${item.poids.toStringAsFixed(1)} kg = ${item.linePoids.toStringAsFixed(1)} kg'
                                : '${item.poids.toStringAsFixed(1)} kg')
                            : 'Poids non renseigné',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
            ),
            onPressed: _onCheckoutPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Passer la commande',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppConfig.formatPrice(cartState.total),
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
