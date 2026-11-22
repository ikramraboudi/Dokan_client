/// ============================================================================
/// RÔLE DU FICHIER : Fiche produit détaillée avec design épuré et minimaliste (boutique moderne).
///                   Grande image centrée, compteur discret 01/04, nom et prix centrés,
///                   pastilles de taille rondes, cubes de couleur avec anneau, et grand bouton pilule.
/// INTERAGIT AVEC : productDetailProvider, cartProvider, favoritesProvider, ProductReviewsSection.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/auth_required_dialog.dart';
import '../../core/ui/error_state.dart';
import '../../core/utils/product_options.dart';
import '../../data/mock/mock_cart_repository.dart';
import '../../data/mock/mock_catalog_repository.dart';
import '../../data/mock/mock_favorites_repository.dart';
import '../../data/models/cart_item_ui_model.dart';
import '../../data/models/product_ui_model.dart';
import 'widgets/product_reviews_section.dart';

/// Provider pour récupérer le produit par son identifiant.
final productDetailProvider =
    FutureProvider.family<ProductUiModel?, String>((ref, id) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getProductById(id);
});

/// Fiche produit détaillée Dokan (Style Minimaliste & Centré).
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
  bool _isAddedSuccess = false;
  bool _isButtonPressed = false;
  bool _isDescriptionExpanded = false;

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
      HapticFeedback.mediumImpact();
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
      HapticFeedback.mediumImpact();
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
      HapticFeedback.mediumImpact();
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

    HapticFeedback.lightImpact();

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
    } else {
      ref.read(cartProvider.notifier).addProduct(
            product,
            quantity: _quantity,
            variant: _selectedVariant,
            selectedColor: _selectedColor,
            selectedSize: _selectedSize,
          );
    }

    // Animation de validation sur le bouton
    setState(() => _isAddedSuccess = true);
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) {
        setState(() => _isAddedSuccess = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F7),
      body: productAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => ErrorState(
          onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
        ),
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Article introuvable.'));
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

          // Clé composite d'identification de l'article dans le panier
          final compositeId =
              '${product.id}_${_selectedColor ?? ''}_${_selectedSize ?? ''}_${_selectedVariant ?? ''}';
          final existingCartItem = cartState.items.where((i) {
            return i.id == compositeId;
          }).firstOrNull;

          final currentQuantity = existingCartItem?.quantity ?? _quantity;

          final isFavorite = ref.watch(favoritesProvider).maybeWhen(
                data: (list) => list.any((p) => p.id == widget.productId),
                orElse: () => false,
              );

          return Stack(
            children: [
              // Contenu principal défilant
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120.0),
                  child: Column(
                    children: [
                      // Espacement pour la barre transparente supérieure
                      const SizedBox(height: 72.0),

                      // 1. Grande Image centrée & Compteur
                      _buildCenterImageGallery(product),

                      const SizedBox(height: AppDimens.space16),

                      // 2. Nom, Prix et infos discrètes (centrés)
                      _buildHeaderInfo(product),

                      const SizedBox(height: AppDimens.space24),

                      // 3. Choix Couleur (si applicable)
                      if (availableColors.isNotEmpty) ...[
                        _buildColorSelector(
                          availableColors,
                          _highlightMissingOptions && _selectedColor == null,
                        ),
                        const SizedBox(height: AppDimens.space20),
                      ],

                      // 4. Choix Taille (si applicable)
                      if (availableSizes.isNotEmpty) ...[
                        _buildSizeSelector(
                          availableSizes,
                          _highlightMissingOptions && _selectedSize == null,
                        ),
                        const SizedBox(height: AppDimens.space20),
                      ],

                      // 5. Options anciennes variantes (si présentes)
                      if (product.variants != null && product.variants!.isNotEmpty) ...[
                        _buildLegacyVariantsSelector(product.variants!),
                        const SizedBox(height: AppDimens.space20),
                      ],

                      // 6. Sélecteur de Quantité en pilule compacte
                      _buildQuantitySection(currentQuantity, isInStock, existingCartItem),

                      const SizedBox(height: AppDimens.space24),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppDimens.space24),
                        child: Divider(color: AppColors.divider, height: 1.0),
                      ),

                      const SizedBox(height: AppDimens.space24),

                      // 7. Description complète
                      _buildDescriptionSection(product),

                      const SizedBox(height: AppDimens.space20),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppDimens.space24),
                        child: Divider(color: AppColors.divider, height: 1.0),
                      ),

                      const SizedBox(height: AppDimens.space20),

                      // 8. Section Avis des clients
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                        child: ProductReviewsSection(product: product),
                      ),
                    ],
                  ),
                ),
              ),

              // Barre supérieure transparente fixe avec bouton retour et cœur
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTransparentTopBar(product, isFavorite),
              ),

              // Grand bouton fixe « Ajouter au panier »
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomAddToCartBar(product, isInStock, existingCartItem),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Barre supérieure transparente avec pastilles rondes translucides (retour et cœur)
  Widget _buildTransparentTopBar(ProductUiModel product, bool isFavorite) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bouton retour circulaire
            Semantics(
              label: 'Retour à la page précédente',
              button: true,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.90),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.textPrimary),
                  tooltip: 'Retour',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),

            // Bouton cœur favori circulaire
            Semantics(
              label: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
              button: true,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.90),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 20,
                    color: isFavorite ? AppColors.favorite : AppColors.textSecondary,
                  ),
                  tooltip: 'Favori',
                  onPressed: () => _onFavoriteTap(product),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Grande image centrée avec ombre elliptique douce au sol et compteur discret 01 / 04
  Widget _buildCenterImageGallery(ProductUiModel product) {
    final screenHeight = MediaQuery.of(context).size.height;
    final galleryHeight = (screenHeight * 0.42).clamp(260.0, 360.0);
    final totalImages = product.imageUrls.isNotEmpty ? product.imageUrls.length : 1;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Ombre portée elliptique très douce sous le produit
            Positioned(
              bottom: 12,
              child: Container(
                width: 170,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 22,
                      spreadRadius: 3,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),

            // Galerie d'images PageView
            SizedBox(
              height: galleryHeight,
              child: PageView.builder(
                controller: _imagePageController,
                itemCount: totalImages,
                onPageChanged: (idx) => setState(() => _activeImageIndex = idx),
                itemBuilder: (context, index) {
                  final url = product.imageUrls.isNotEmpty ? product.imageUrls[index] : '';
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
                      child: url.isNotEmpty
                          ? Image.network(
                              url,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                );
                              },
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.inventory_2_outlined,
                                size: 80,
                                color: AppColors.textHint,
                              ),
                            )
                          : const Icon(
                              Icons.inventory_2_outlined,
                              size: 80,
                              color: AppColors.textHint,
                            ),
                    ),
                  );
                },
              ),
            ),

            // Badges sobres en haut à gauche (Promotion / Nouveauté)
            Positioned(
              top: 8,
              left: AppDimens.space24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.hasDiscount && product.discountLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                      ),
                      child: Text(
                        product.discountLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (product.isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                      ),
                      child: const Text(
                        'NOUVEAU',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        // Compteur discret centré sous l'image (ex: 01 / 04)
        if (totalImages > 1) ...[
          const SizedBox(height: AppDimens.space8),
          Text(
            '${(_activeImageIndex + 1).toString().padLeft(2, '0')} / ${totalImages.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
              color: AppColors.textHint,
            ),
          ),
        ],
      ],
    );
  }

  /// Nom, Prix centré et ligne discrète d'informations (stock & poids)
  Widget _buildHeaderInfo(ProductUiModel product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
      child: Column(
        children: [
          // Nom du produit centré
          Text(
            product.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),

          const SizedBox(height: AppDimens.space8),

          // Prix centré
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                AppConfig.formatPrice(product.price),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (product.hasDiscount && product.oldPrice != null) ...[
                const SizedBox(width: AppDimens.space8),
                Text(
                  AppConfig.formatPrice(product.oldPrice!),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppDimens.space6),

          // Ligne discrète d'informations sous le prix (Stock & Poids unitaire)
          Text(
            '${product.availability.label} · ${product.poids > 0 ? (product.poids > 30 ? "${product.poids.toStringAsFixed(1)} kg (camion requis)" : "${product.poids.toStringAsFixed(2)} kg") : "Disponible"}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Sélecteur de couleur : petits cubes arrondis de 36 px avec cadre anneau si sélectionné
  Widget _buildColorSelector(List<String> colorKeys, bool isMissing) {
    return Column(
      children: [
        Text(
          'COULEUR',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: isMissing ? AppColors.error : AppColors.textHint,
          ),
        ),
        if (isMissing) ...[
          const SizedBox(height: 2),
          const Text(
            'Veuillez choisir une couleur',
            style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: AppDimens.space12),
        Wrap(
          spacing: AppDimens.space12,
          runSpacing: AppDimens.space12,
          alignment: WrapAlignment.center,
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
                    _highlightMissingOptions = false;
                  });
                },
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeInOut,
                      width: 38,
                      height: 38,
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDimens.radius12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorDef.color,
                          borderRadius: BorderRadius.circular(AppDimens.radius8),
                          border: Border.all(
                            color: colorDef.borderColor ??
                                (isSelected ? Colors.transparent : AppColors.border),
                            width: colorDef.borderColor != null ? 1.0 : 0.6,
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
      ],
    );
  }

  /// Sélecteur de taille : pastilles rondes de 44 px (fond transparent ou primaire si sélectionné)
  Widget _buildSizeSelector(List<String> sizes, bool isMissing) {
    return Column(
      children: [
        Text(
          'TAILLE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: isMissing ? AppColors.error : AppColors.textHint,
          ),
        ),
        if (isMissing) ...[
          const SizedBox(height: 2),
          const Text(
            'Veuillez choisir une taille',
            style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: AppDimens.space12),
        Wrap(
          spacing: AppDimens.space8,
          runSpacing: AppDimens.space8,
          alignment: WrapAlignment.center,
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
                    _highlightMissingOptions = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      size,
                      style: TextStyle(
                        fontSize: 13,
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
      ],
    );
  }

  /// Variantes héritées éventuelles
  Widget _buildLegacyVariantsSelector(List<String> variants) {
    return Column(
      children: [
        const Text(
          'OPTIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppColors.textHint,
          ),
        ),
        const SizedBox(height: AppDimens.space8),
        Wrap(
          spacing: AppDimens.space8,
          runSpacing: AppDimens.space8,
          alignment: WrapAlignment.center,
          children: variants.map((v) {
            final isSelected = _selectedVariant == v;
            return ChoiceChip(
              label: Text(v),
              selected: isSelected,
              selectedColor: AppColors.primarySoft,
              onSelected: (selected) {
                if (selected) setState(() => _selectedVariant = v);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Sélecteur de quantité compact en pilule centrée (− 1 +)
  Widget _buildQuantitySection(int currentQuantity, bool isInStock, CartItemUiModel? existingCartItem) {
    return Column(
      children: [
        const Text(
          'Quantité',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppColors.textHint,
          ),
        ),
        const SizedBox(height: AppDimens.space8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
            border: Border.all(color: AppColors.border, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 18),
                color: currentQuantity > 1 && isInStock ? AppColors.textPrimary : AppColors.textHint,
                onPressed: isInStock && currentQuantity > 1
                    ? () {
                        final newQty = currentQuantity - 1;
                        if (existingCartItem != null) {
                          ref.read(cartProvider.notifier).updateQuantity(existingCartItem.id, newQty);
                        } else {
                          setState(() => _quantity = newQty);
                        }
                      }
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12),
                child: Text(
                  '$currentQuantity',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 18),
                color: currentQuantity < 10 && isInStock ? AppColors.textPrimary : AppColors.textHint,
                onPressed: isInStock && currentQuantity < 10
                    ? () {
                        final newQty = currentQuantity + 1;
                        if (existingCartItem != null) {
                          ref.read(cartProvider.notifier).updateQuantity(existingCartItem.id, newQty);
                        } else {
                          setState(() => _quantity = newQty);
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Section Description alignée à gauche avec bouton discret « Voir plus »
  Widget _buildDescriptionSection(ProductUiModel product) {
    final text = product.description;
    final isLong = text.length > 140;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            text,
            maxLines: _isDescriptionExpanded || !isLong ? null : 3,
            overflow: _isDescriptionExpanded || !isLong ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (isLong)
            GestureDetector(
              onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  _isDescriptionExpanded ? 'Voir moins' : 'Voir plus',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Grand bouton arrondi pleine largeur « Ajouter au panier » fixé en bas
  Widget _buildBottomAddToCartBar(
    ProductUiModel product,
    bool isInStock,
    CartItemUiModel? existingCartItem,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppDimens.space20, 12, AppDimens.space20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F7).withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Listener(
          onPointerDown: (_) => setState(() => _isButtonPressed = true),
          onPointerUp: (_) => setState(() => _isButtonPressed = false),
          onPointerCancel: (_) => setState(() => _isButtonPressed = false),
          child: AnimatedScale(
            scale: _isButtonPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInStock
                      ? (_isAddedSuccess ? AppColors.success : AppColors.primary)
                      : AppColors.border,
                  foregroundColor: Colors.white,
                  elevation: isInStock ? 2 : 0,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  ),
                ),
                onPressed: isInStock ? () => _onAddToCart(product, existingCartItem) : null,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isAddedSuccess
                      ? const Row(
                          key: ValueKey('added'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Ajouté au panier !',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          isInStock
                              ? (existingCartItem != null
                                  ? 'Ajouter encore au panier'
                                  : 'Ajouter au panier')
                              : 'Rupture de stock',
                          key: ValueKey(existingCartItem != null ? 'again' : 'add'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isInStock ? Colors.white : AppColors.textHint,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
