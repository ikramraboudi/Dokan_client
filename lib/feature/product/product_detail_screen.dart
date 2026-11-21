/// ============================================================================
/// RÔLE DU FICHIER : Fiche produit détaillée avec galerie d'images, choix des variantes, sélecteur de quantité et bouton d'achat fixé en bas.
/// INTERAGIT AVEC : productDetailProvider, cartProvider, favoritesProvider.
/// POUR L'ORAL : « La fiche produit présente l'article avec galerie défilante, sélecteur de taille et bouton d'ajout au panier verrouillé en bas d'écran. »
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_top_bar.dart';
import '../../core/ui/auth_required_dialog.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/quantity_selector.dart';
import '../../core/utils/product_options.dart';
import '../../data/mock/mock_cart_repository.dart';
import '../../data/mock/mock_catalog_repository.dart';
import '../../data/mock/mock_favorites_repository.dart';
import '../../data/models/cart_item_ui_model.dart';
import '../../data/models/product_ui_model.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';
import 'widgets/product_reviews_section.dart';

/// Provider pour récupérer le produit par identifiant
final productDetailProvider =
    FutureProvider.family<ProductUiModel?, String>((ref, id) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getProductById(id);
});


///  Dokan — FICHE PRODUIT DÉTAILLÉE
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final PageController _imagePageController = PageController();
  int _activeImageIndex = 0;
  int _quantity = 1;
  String? _selectedVariant;
  String? _selectedColor;
  String? _selectedSize;
  bool _highlightMissingOptions = false;

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  void _onFavoriteTap(ProductUiModel product) {
    final session = ref.read(sessionProvider);
    if (session.isGuest) {
      AuthRequiredDialog.show(
        context,
        ref,
        message: 'Pour ajouter cet article à vos favoris, connectez-vous ou créez un compte.',
        pendingAction: () {
          ref.read(favoritesProvider.notifier).toggleFavorite(product);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Favoris mis à jour pour ${product.name}.'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      );
    } else {
      ref.read(favoritesProvider.notifier).toggleFavorite(product);
      final isNowFav = ref.read(favoritesProvider.notifier).isProductFavorite(product.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowFav
                ? '${product.name} ajouté à vos favoris.'
                : '${product.name} retiré de vos favoris.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onAddToCart(ProductUiModel product, CartItemUiModel? existingCartItem) {
    if (!product.isInStock) return;

    final availableColors = ProductOptions.getColorsForProduct(product);
    final availableSizes = ProductOptions.getSizesForProduct(product);

    final needsColor = availableColors.isNotEmpty && _selectedColor == null;
    final needsSize = availableSizes.isNotEmpty && _selectedSize == null;

    if (needsColor && needsSize) {
      setState(() => _highlightMissingOptions = true);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez choisir une couleur et une taille.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    } else if (needsColor) {
      setState(() => _highlightMissingOptions = true);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez choisir une couleur.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    } else if (needsSize) {
      setState(() => _highlightMissingOptions = true);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez choisir une taille.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (existingCartItem != null) {
      if (existingCartItem.quantity >= 10) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quantité maximale atteinte (10 unités).'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      final newQty = (existingCartItem.quantity + 1).clamp(1, 10);
      ref.read(cartProvider.notifier).updateQuantity(existingCartItem.id, newQty);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} mis à jour ($newQty au panier).'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ref.read(cartProvider.notifier).addProduct(
            product,
            quantity: _quantity,
            variant: _selectedVariant,
            selectedColor: _selectedColor,
            selectedSize: _selectedSize,
          );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} ajouté au panier ($_quantity).'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Détail de l\'article',
        showBackButton: true,
      ),
      body: productAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => ErrorState(
          onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
        ),
        data: (product) {
          if (product == null) {
            return const Center(
              child: Text('Article introuvable.'),
            );
          }

          // Initialisation de la variante si non sélectionnée
          if (_selectedVariant == null &&
              product.variants != null &&
              product.variants!.isNotEmpty) {
            _selectedVariant = product.variants!.first;
          }

          final isInStock = product.isInStock;
          final availableColors = ProductOptions.getColorsForProduct(product);
          final availableSizes = ProductOptions.getSizesForProduct(product);

          // Détection de l'article déjà présent dans le panier pour ce produit (et cette combinaison)
          final compositeId =
              '${product.id}_${_selectedColor ?? ''}_${_selectedSize ?? ''}_${_selectedVariant ?? ''}';
          final existingCartItem = cartState.items.where((i) {
            return i.id == compositeId;
          }).firstOrNull;

          // Si le produit est déjà dans le panier, afficher sa quantité réelle du panier
          final currentQuantity = existingCartItem?.quantity ?? _quantity;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: AppDimens.space32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Galerie d'images PageView avec indicateurs ---
                      _buildImageGallery(product),

                      Padding(
                        padding: const EdgeInsets.all(AppDimens.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Catégorie et disponibilité
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  product.categoryName,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                _buildAvailabilityBadge(product.availability),
                              ],
                            ),
                            const SizedBox(height: AppDimens.space8),

                            // Nom du produit
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    height: 1.25,
                                  ),
                            ),
                            const SizedBox(height: AppDimens.space12),

                            // Note et avis réels issus des reviews vérifiées
                            Builder(
                              builder: (context) {
                                final summary = ref.watch(productReviewSummaryProvider(product.id)).valueOrNull;
                                final myReview = ref.watch(myReviewForProductProvider(product.id)).valueOrNull;
                                final allReviews = ref.watch(productReviewsStreamProvider(product.id)).valueOrNull ?? const <ReviewUiModel>[];

                                double? avg = summary?.averageRating;
                                int total = summary?.totalReviews ?? 0;

                                if (total == 0) {
                                  final combined = <ReviewUiModel>[...allReviews];
                                  if (myReview != null && !combined.any((r) => r.id == myReview.id)) {
                                    combined.add(myReview);
                                  }
                                  if (combined.isNotEmpty) {
                                    total = combined.length;
                                    avg = combined.fold<num>(0, (prev, r) => prev + r.rating).toDouble() / total;
                                  }
                                }

                                if (total == 0 || avg == null) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppDimens.space16),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 20,
                                        color: AppColors.star,
                                      ),
                                      const SizedBox(width: AppDimens.space4),
                                      Text(
                                        avg.toStringAsFixed(1).replaceAll('.', ','),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: AppDimens.space4),
                                      Text(
                                        '($total avis)',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // Prix, ancien prix et remise
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  AppConfig.formatPrice(product.price),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                if (product.hasDiscount && product.oldPrice != null) ...[
                                  const SizedBox(width: AppDimens.space12),
                                  Text(
                                    AppConfig.formatPrice(product.oldPrice!),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textHint,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: AppDimens.space8),
                                  if (product.discountLabel != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppDimens.space8,
                                        vertical: AppDimens.space4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(AppDimens.radius8),
                                      ),
                                      child: Text(
                                        product.discountLabel!,
                                        style: const TextStyle(
                                          color: AppColors.onAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),

                            const Divider(
                              color: AppColors.divider,
                              height: AppDimens.space32,
                            ),

                            // Variantes (ex. Tailles / Couleurs)
                            if (product.variants != null && product.variants!.isNotEmpty) ...[
                              Text(
                                'Options disponibles',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppDimens.space8),
                              Wrap(
                                spacing: AppDimens.space8,
                                runSpacing: AppDimens.space8,
                                children: product.variants!.map((variant) {
                                  final isSelected = _selectedVariant == variant;
                                  return ChoiceChip(
                                    label: Text(variant),
                                    selected: isSelected,
                                    selectedColor: AppColors.primarySoft,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedVariant = variant;
                                        });
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: AppDimens.space24),
                            ],

                            // Section Couleur (pour les catégories concernées)
                            if (availableColors.isNotEmpty)
                              _buildColorSection(
                                availableColors,
                                _highlightMissingOptions && _selectedColor == null,
                              ),

                            // Section Taille (pour les catégories concernées)
                            if (availableSizes.isNotEmpty)
                              _buildSizeSection(
                                availableSizes,
                                _highlightMissingOptions && _selectedSize == null,
                              ),

                            // Sélecteur de quantité synchronisé avec le panier
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Quantité',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                QuantitySelector(
                                  quantity: currentQuantity,
                                  enabled: isInStock,
                                  onChanged: (newQty) {
                                    if (existingCartItem != null) {
                                      // Produit déjà dans le panier : mise à jour instantanée du panier
                                      ref.read(cartProvider.notifier).updateQuantity(
                                            existingCartItem.id,
                                            newQty,
                                          );
                                    } else {
                                      // Produit pas encore dans le panier : sélection locale avant ajout
                                      setState(() {
                                        _quantity = newQty;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),

                            const Divider(
                              color: AppColors.divider,
                              height: AppDimens.space32,
                            ),

                            // Description complète
                            Text(
                              'Description du produit',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppDimens.space8),
                            Text(
                              product.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                            ),

                            const Divider(
                              color: AppColors.divider,
                              height: AppDimens.space32,
                            ),

                            // Section Avis des clients
                            ProductReviewsSection(product: product),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Barre fixe inférieure avec boutons d'action ---
              _buildBottomAction(
                product,
                isInStock,
                ref.watch(favoritesProvider).maybeWhen(
                      data: (list) => list.any((p) => p.id == widget.productId),
                      orElse: () => false,
                    ),
                existingCartItem,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageGallery(ProductUiModel product) {
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _imagePageController,
            itemCount: product.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _activeImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final url = product.imageUrls[index];
              return Container(
                color: AppColors.surfaceAlt,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.primarySoft,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Indicateurs de points si plusieurs images
        if (product.imageUrls.length > 1) ...[
          const SizedBox(height: AppDimens.space12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(product.imageUrls.length, (index) {
              final isActive = _activeImageIndex == index;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: AppDimens.space4),
                width: isActive ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildAvailabilityBadge(ProductAvailability availability) {
    Color bg;
    Color fg;
    String text;

    switch (availability) {
      case ProductAvailability.inStock:
        bg = AppColors.successSoft;
        fg = AppColors.success;
        text = 'En stock';
        break;
      case ProductAvailability.limitedStock:
        bg = AppColors.accentSoft;
        fg = AppColors.warning;
        text = 'Stock limité';
        break;
      case ProductAvailability.outOfStock:
        bg = AppColors.errorSoft;
        fg = AppColors.error;
        text = 'Rupture de stock';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radius8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildColorSection(List<String> colorKeys, bool isMissing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Couleur',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (isMissing) ...[
              const SizedBox(width: AppDimens.space8),
              const Text(
                '* Requis',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppDimens.space12),
        Wrap(
          spacing: AppDimens.space12,
          runSpacing: AppDimens.space12,
          children: colorKeys.map((key) {
            final colorDef = ProductOptions.getColor(key);
            if (colorDef == null) return const SizedBox.shrink();

            final isSelected = _selectedColor == key;

            return Semantics(
              label: colorDef.name,
              button: true,
              selected: isSelected,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = key;
                  });
                },
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeInOut,
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDimens.radius12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorDef.color,
                          borderRadius: BorderRadius.circular(AppDimens.radius8),
                          border: Border.all(
                            color: colorDef.borderColor ??
                                (isSelected ? Colors.transparent : AppColors.border),
                            width: colorDef.borderColor != null ? 1.0 : 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimens.space24),
      ],
    );
  }

  Widget _buildSizeSection(List<String> sizes, bool isMissing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Taille',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (isMissing) ...[
              const SizedBox(width: AppDimens.space8),
              const Text(
                '* Requis',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppDimens.space12),
        Wrap(
          spacing: AppDimens.space8,
          runSpacing: AppDimens.space8,
          children: sizes.map((size) {
            final isSelected = _selectedSize == size;

            return Semantics(
              label: 'Taille $size',
              button: true,
              selected: isSelected,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSize = size;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space12,
                    vertical: AppDimens.space8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radius12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      size,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimens.space24),
      ],
    );
  }

  Widget _buildBottomAction(
    ProductUiModel product,
    bool isInStock,
    bool isFavorite,
    CartItemUiModel? existingCartItem,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
        ),
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
            // Bouton Cœur Favori
            Semantics(
              label: isFavorite
                  ? 'Retirer cet article de mes favoris'
                  : 'Ajouter cet article à mes favoris',
              button: true,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppDimens.radius14),
                ),
                child: IconButton(
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite
                        ? AppColors.favorite
                        : AppColors.textSecondary,
                  ),
                  tooltip: 'Favori',
                  onPressed: () => _onFavoriteTap(product),
                ),
              ),
            ),
            const SizedBox(width: AppDimens.space12),

            // Bouton Ajouter au panier (désactivé si indisponible)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isInStock ? () => _onAddToCart(product, existingCartItem) : null,
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: Text(
                  isInStock
                      ? (existingCartItem != null
                          ? 'Ajouter encore au panier'
                          : 'Ajouter au panier')
                      : 'Article indisponible',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
