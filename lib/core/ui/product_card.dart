/// ============================================================================
/// RÔLE DU FICHIER :
/// Carte de présentation d'un produit individuel (`ProductCard`).
/// Affiche la photographie de l'article, ses badges d'état (promotion, stock limité,
/// rupture), le bouton interactif cœur de favori, le nom sur 1 à 2 lignes,
/// le prix formaté en dinars tunisiens avec son ancien prix barré, et sa note.
///
/// PARTICULARITÉ TECHNIQUE ERGONOMIQUE :
/// Les prix utilisent le widget `Wrap` au lieu d'une `Row` : sur des écrans étroits
/// (largeur de carte < 160 dp), deux prix côte à côte risquaient de déborder de 2 pixels.
/// Le `Wrap` renvoie automatiquement le prix barré à la ligne sans lever d'erreur Flutter.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/ui/` (Composant Produit Réutilisable).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par :
///   * `HomeScreen` (sections de défilement horizontal).
///   * `ProductGrid` (grilles paginées du catalogue et des favoris).
/// - Dépend de :
///   * `data/models/product_ui_model.dart` pour les données de l'article.
///   * `core/config/app_config.dart` pour `formatPrice()`.
///   * `core/theme/app_colors.dart` et `core/theme/app_dimens.dart`.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../../data/models/product_ui_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Carte produit réutilisable de Dokan.
class ProductCard extends StatelessWidget {
  /// Modèle contenant les données de l'article à représenter.
  final ProductUiModel product;

  /// Action déclenchée lors de l'appui sur la carte (ouverture de la fiche détaillée).
  final VoidCallback? onTap;

  /// Action déclenchée lors de l'appui sur l'icône cœur (ajout/retrait favori).
  final VoidCallback? onFavoriteTap;

  /// État actuel du favori (vrai si présent dans la liste client).
  final bool isFavorite;

  /// Largeur optionnelle forcée (utile dans les carrousels horizontaux de l'accueil).
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
              // --- Image avec superposition des badges et du bouton favori ---
              // MOT TECHNIQUE - Stack :
              // Empile plusieurs widgets les uns sur les autres en couches z-index.
              Stack(
                children: [
                  // MOT TECHNIQUE - AspectRatio :
                  // Maintient un ratio largeur/hauteur constant (ici 1.18) pour éviter
                  // les déformations d'images quelle que soit la résolution de l'écran.
                  AspectRatio(
                    aspectRatio: 1.18,
                    child: Container(
                      color: AppColors.surfaceAlt,
                      child: product.imageUrls.isNotEmpty
                          ? Image.network(
                              product.imageUrls.first,
                              fit: BoxFit.cover,
                              // Affichage fluide d'un spinner pendant le téléchargement réseau
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
                              // Fallback élégant en cas d'erreur de connexion ou lien brisé
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

                  // Badge de remise promotionnelle ou d'état de stock
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

                  // Bouton Cœur Favori circulaire
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

              // --- Zone des informations textuelles du produit ---
              Padding(
                padding: const EdgeInsets.all(AppDimens.space8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Libellé de la catégorie
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

                    // Nom commercial du produit (tronqué élégamment au-delà de 2 lignes)
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

                    // MOT TECHNIQUE - Wrap :
                    // Affiche le prix et l'ancien prix côte à côte, mais passe
                    // automatiquement à la ligne sans planter si l'écran est trop étroit.
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

                    // Étoiles de notation et nombre d'avis
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
