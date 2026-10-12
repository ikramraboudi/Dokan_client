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
import '../../data/mock/mock_cart_repository.dart';
import '../../data/mock/mock_catalog_repository.dart';
import '../../data/mock/mock_favorites_repository.dart';
import '../../data/models/product_ui_model.dart';

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

  void _onAddToCart(ProductUiModel product) {
    if (!product.isInStock) return;

    ref.read(cartProvider.notifier).addProduct(
          product,
          quantity: _quantity,
          variant: _selectedVariant,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Article ajouté au panier.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

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

                            // Note et avis
                            if (product.rating != null) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 20,
                                    color: AppColors.star,
                                  ),
                                  const SizedBox(width: AppDimens.space4),
                                  Text(
                                    product.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (product.reviewCount > 0) ...[
                                    const SizedBox(width: AppDimens.space4),
                                    Text(
                                      '(${product.reviewCount} avis)',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: AppDimens.space16),
                            ],

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

                            // Sélecteur de quantité
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Quantité',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                QuantitySelector(
                                  quantity: _quantity,
                                  enabled: isInStock,
                                  onChanged: (newQty) {
                                    setState(() {
                                      _quantity = newQty;
                                    });
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

  Widget _buildBottomAction(ProductUiModel product, bool isInStock, bool isFavorite) {
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
                onPressed: isInStock ? () => _onAddToCart(product) : null,
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: Text(
                  isInStock ? 'Ajouter au panier' : 'Article indisponible',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
