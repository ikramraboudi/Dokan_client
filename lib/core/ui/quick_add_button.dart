/// ============================================================================
/// RÔLE DU FICHIER : Bouton d'ajout rapide au panier avec compteur interactif (− N +) et feuille d'options.
/// INTERAGIT AVEC : ProductCard, cartProvider, QuantitySelector, AppColors.
/// POUR L'ORAL : « Ce composant permet d'ajouter un produit directement au panier depuis la carte produit et mute en compteur interactif à 60 FPS sans ouvrir la fiche détaillée. »
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../ui/quantity_selector.dart';
import '../../data/mock/mock_cart_repository.dart';
import '../../data/models/cart_item_ui_model.dart';
import '../../data/models/product_ui_model.dart';

/// Bouton d'action rapide placé en bas à droite de l'image d'un produit.
///
/// 3 ÉTATS POSSIBLES :
/// 1) Produit simple (sans variante) non présent dans le panier :
///    Bouton circulaire blanc translucide avec icône chariot '+'.
/// 2) Produit simple présent dans le panier (N >= 1) :
///    Pastille compacte animée (− N +) permettant d'ajuster ou de retirer l'article.
/// 3) Produit avec variantes (tailles/couleurs) :
///    Bouton d'options avec badge de quantité cumulée ouvrant un volet modal de sélection.
class QuickAddButton extends ConsumerStatefulWidget {
  /// Données du produit concerné.
  final ProductUiModel product;

  const QuickAddButton({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends ConsumerState<QuickAddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Animation de rebond subtile (1.0 -> 1.18 -> 1.0) lors d'un changement de quantité
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  /// Recherche la ligne d'article correspondante dans le panier pour un produit sans variante.
  CartItemUiModel? _findCartItem() {
    final items = ref.read(cartProvider).items;
    for (final item in items) {
      if (item.productId == widget.product.id) {
        return item;
      }
    }
    return null;
  }

  /// SCÉNARIO MÉTIER : AJOUT RAPIDE INITIAL (Panier = 0)
  void _onQuickAdd() {
    HapticFeedback.lightImpact();
    ref.read(cartProvider.notifier).addProduct(widget.product, quantity: 1);
  }

  /// SCÉNARIO MÉTIER : INCRÉMENTATION DE LA QUANTITÉ (+1)
  void _onIncrease(int currentQty) {
    if (currentQty >= 10) return;
    HapticFeedback.lightImpact();
    final item = _findCartItem();
    if (item != null) {
      ref.read(cartProvider.notifier).updateQuantity(item.id, currentQty + 1);
    }
  }

  /// SCÉNARIO MÉTIER : DÉCRÉMENTATION (−1) OU RETRAIT SI QUANTITÉ == 1
  void _onDecrease(int currentQty) {
    HapticFeedback.lightImpact();
    final item = _findCartItem();
    if (item != null) {
      if (currentQty <= 1) {
        ref.read(cartProvider.notifier).removeItem(item.id);
      } else {
        ref.read(cartProvider.notifier).updateQuantity(item.id, currentQty - 1);
      }
    }
  }

  /// SCÉNARIO MÉTIER : OUVERTURE DE LA FEUILLE MODALE POUR LES VARIANTES
  void _showVariantSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radius24),
        ),
      ),
      builder: (sheetContext) => _VariantBottomSheet(product: widget.product),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Si le produit est en rupture de stock, aucun bouton d'ajout n'est affiché
    if (!widget.product.isInStock) {
      return const SizedBox.shrink();
    }

    final hasVariants =
        widget.product.variants != null && widget.product.variants!.isNotEmpty;

    // Écoute sélective de la quantité cumulée de CE produit dans le panier
    final cartQuantity = ref.watch(
      cartProvider.select((state) => state.items
          .where((i) => i.productId == widget.product.id)
          .fold(0, (acc, i) => acc + i.quantity)),
    );

    // Déclenchement de l'animation de rebond quand la quantité change
    ref.listen<int>(
      cartProvider.select((state) => state.items
          .where((i) => i.productId == widget.product.id)
          .fold(0, (acc, i) => acc + i.quantity)),
      (prev, next) {
        if (prev != null && prev != next && next > 0) {
          _bounceController.forward(from: 0.0);
        }
      },
    );

    // 2. Produit avec variantes : bouton circulaire d'options avec badge de quantité
    if (hasVariants) {
      return _buildVariantButton(context, cartQuantity);
    }

    // 3. Produit simple sans variante : bouton rond (0) ou pastille compteur (>= 1)
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: cartQuantity == 0
          ? _buildAddCircleButton(key: const ValueKey('circle_add'))
          : _buildCounterPill(
              key: const ValueKey('counter_pill'),
              quantity: cartQuantity,
            ),
    );
  }

  /// Construit le bouton rond initial avec icône chariot +
  Widget _buildAddCircleButton({required Key key}) {
    return Semantics(
      key: key,
      label: 'Ajouter ${widget.product.name} au panier',
      button: true,
      child: SizedBox(
        width: AppDimens.minTouchTarget,
        height: AppDimens.minTouchTarget,
        child: Center(
          child: Material(
            color: AppColors.surface.withValues(alpha: 0.92),
            shape: const CircleBorder(),
            elevation: 1.5,
            shadowColor: AppColors.shadow,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _onQuickAdd,
              child: const Padding(
                padding: EdgeInsets.all(AppDimens.space8),
                child: Icon(
                  Icons.add_shopping_cart_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construit le bouton pour les produits avec variantes (avec badge si déjà présent)
  Widget _buildVariantButton(BuildContext context, int cartQuantity) {
    final label = cartQuantity > 0
        ? 'Choisir une option pour ${widget.product.name} ($cartQuantity déjà dans le panier)'
        : 'Choisir une option pour ${widget.product.name}';

    return Semantics(
      label: label,
      button: true,
      child: SizedBox(
        width: AppDimens.minTouchTarget,
        height: AppDimens.minTouchTarget,
        child: Center(
          child: Badge(
            isLabelVisible: cartQuantity > 0,
            label: Text(
              cartQuantity > 99 ? '99+' : '$cartQuantity',
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.primary,
            child: Material(
              color: AppColors.surface.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              elevation: 1.5,
              shadowColor: AppColors.shadow,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _showVariantSheet(context),
                child: const Padding(
                  padding: EdgeInsets.all(AppDimens.space8),
                  child: Icon(
                    Icons.add_shopping_cart_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construit la pastille compteur (− N +) étirable
  Widget _buildCounterPill({
    required Key key,
    required int quantity,
  }) {
    final canIncrease = quantity < 10;

    return Semantics(
      key: key,
      container: true,
      label: 'Quantité de ${widget.product.name} dans le panier : $quantity',
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton Moins (−)
            Semantics(
              label: 'Diminuer la quantité de ${widget.product.name}',
              button: true,
              child: Material(
                color: AppColors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _onDecrease(quantity),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                    child: Icon(
                      Icons.remove_rounded,
                      size: 15,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),

            // Compteur numérique avec animation de rebond
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            // Bouton Plus (+)
            Semantics(
              label: 'Augmenter la quantité de ${widget.product.name}',
              button: true,
              enabled: canIncrease,
              child: Material(
                color: AppColors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: canIncrease ? () => _onIncrease(quantity) : null,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                    child: Icon(
                      Icons.add_rounded,
                      size: 15,
                      color: canIncrease
                          ? AppColors.onPrimary
                          : AppColors.onPrimary.withValues(alpha: 0.35),
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

/// Feuille modale en bas d'écran permettant de choisir une variante avant ajout rapide.
class _VariantBottomSheet extends ConsumerStatefulWidget {
  final ProductUiModel product;

  const _VariantBottomSheet({required this.product});

  @override
  ConsumerState<_VariantBottomSheet> createState() =>
      _VariantBottomSheetState();
}

class _VariantBottomSheetState extends ConsumerState<_VariantBottomSheet> {
  late String _selectedVariant;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.product.variants?.isNotEmpty == true
        ? widget.product.variants!.first
        : '';
  }

  void _onConfirm() {
    ref.read(cartProvider.notifier).addProduct(
          widget.product,
          quantity: _quantity,
          variant: _selectedVariant.isNotEmpty ? _selectedVariant : null,
        );
    Navigator.of(context).pop();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final variants = widget.product.variants ?? [];
    final totalPrice = widget.product.price * _quantity;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimens.space16,
          AppDimens.space12,
          AppDimens.space16,
          AppDimens.space16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Poignée de glissement supérieure
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space12),

            // En-tête : miniature produit, titre et bouton fermer
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radius8),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: AppColors.surfaceAlt,
                    child: widget.product.imageUrls.isNotEmpty
                        ? Image.network(
                            widget.product.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.primary,
                          ),
                  ),
                ),
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppConfig.formatPrice(widget.product.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textSecondary,
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: AppColors.divider, height: AppDimens.space24),

            // Choix des variantes disponibles
            if (variants.isNotEmpty) ...[
              const Text(
                'Choisir une option',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimens.space8),
              Wrap(
                spacing: AppDimens.space8,
                runSpacing: AppDimens.space8,
                children: variants.map((variant) {
                  final isSelected = _selectedVariant == variant;
                  return ChoiceChip(
                    label: Text(variant),
                    selected: isSelected,
                    selectedColor: AppColors.primarySoft,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedVariant = variant);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimens.space16),
            ],

            // Sélecteur de quantité
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quantité',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                QuantitySelector(
                  quantity: _quantity,
                  min: 1,
                  max: 10,
                  onChanged: (newQty) {
                    setState(() => _quantity = newQty);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space20),

            // Bouton de validation d'ajout au panier
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radius14),
                ),
              ),
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
              label: Text(
                'Ajouter au panier · ${AppConfig.formatPrice(totalPrice)}',
              ),
              onPressed: _onConfirm,
            ),
          ],
        ),
      ),
    );
  }
}
