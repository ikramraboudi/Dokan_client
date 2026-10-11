import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../../data/models/product_ui_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// ============================================================
///  SOUKNA — CARTE PRODUIT RÉUTILISABLE
/// ============================================================
class ProductCard extends StatelessWidget {
  final ProductUiModel product;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;
  final double? width;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Image avec badges et bouton favori ---
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.18,
                    child: Container(
                      color: AppColors.surfaceAlt,
                      child: product.imageUrls.isNotEmpty
                          ? Image.network(
                              product.imageUrls.first,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.primarySoft,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 32,
                                    color: AppColors.primary,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppColors.primarySoft,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                size: 32,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),

                  // Badge de remise ou de disponibilité
                  Positioned(
                    top: AppDimens.space8,
                    left: AppDimens.space8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.hasDiscount && product.discountLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.space8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(AppDimens.radius8),
                            ),
                            child: Text(
                              product.discountLabel!,
                              style: const TextStyle(
                                color: AppColors.onAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (product.availability == ProductAvailability.limitedStock) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.space8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(AppDimens.radius8),
                            ),
                            child: const Text(
                              'Stock limité',
                              style: TextStyle(
                                color: AppColors.textOnDark,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ] else if (product.availability == ProductAvailability.outOfStock) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.space8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(AppDimens.radius8),
                            ),
                            child: const Text(
                              'Rupture',
                              style: TextStyle(
                                color: AppColors.textOnDark,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Bouton Cœur Favori
                  Positioned(
                    top: AppDimens.space8,
                    right: AppDimens.space8,
                    child: Semantics(
                      label: isFavorite
                          ? 'Retirer ${product.name} des favoris'
                          : 'Ajouter ${product.name} aux favoris',
                      button: true,
                      child: Material(
                        color: AppColors.surface,
                        shape: const CircleBorder(),
                        elevation: 1,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onFavoriteTap,
                          child: Padding(
                            padding: const EdgeInsets.all(AppDimens.space8),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 16,
                              color: isFavorite
                                  ? AppColors.favorite
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // --- Informations produit ---
              Padding(
                padding: const EdgeInsets.all(AppDimens.space8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Catégorie
                    Text(
                      product.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textHint,
                            fontSize: 10,
                          ),
                    ),
                    const SizedBox(height: 2),

                    // Nom sur 1-2 lignes
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: AppDimens.space4),

                    // Prix et ancien prix dans un Wrap sans dépassement
                    Wrap(
                      spacing: AppDimens.space4,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          AppConfig.formatPrice(product.price),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        if (product.hasDiscount && product.oldPrice != null)
                          Text(
                            AppConfig.formatPrice(product.oldPrice!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),

                    // Note et avis si existants
                    if (product.rating != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppColors.star,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (product.reviewCount > 0) ...[
                            const SizedBox(width: 2),
                            Text(
                              '(${product.reviewCount})',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
