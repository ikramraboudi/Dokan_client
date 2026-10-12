/// ============================================================================
/// RÔLE DU FICHIER :
/// Grille de produits responsive avec détection de défilement pour la pagination
/// infinie simulée (`ProductGrid`).
///
/// COMPORTEMENTS CLÉS :
/// 1) Calcule dynamiquement le nombre de colonnes via `LayoutBuilder` (2 sur téléphone,
///    3 sur tablette ou écran large > 700 dp).
/// 2) Utilise `CustomScrollView` et `SliverGrid` pour un recyclage mémoire performant.
/// 3) Détecte automatiquement l'approche du bas de page (à 200 dp de la fin) et appelle
///    `onLoadMore` pour charger la page suivante de produits.
/// 4) Affiche un indicateur de chargement en bas de grille pendant les requêtes.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/ui/` (Grille de Produits Responsive).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par :
///   * `CatalogScreen` (catalogue complet et résultats filtrés).
///   * `SearchScreen` (résultats de recherche textuelle).
///   * `FavoritesScreen` (grille des articles favoris du client).
/// - Dépend de :
///   * `product_card.dart` pour le rendu de chaque cellule.
///   * `loading_state.dart` et `empty_state.dart`.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../../data/models/product_ui_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import 'empty_state.dart';
import 'loading_state.dart';
import 'product_card.dart';

/// Grille de produits adaptative et scrollable.
class ProductGrid extends StatefulWidget {
  final List<ProductUiModel> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final void Function(ProductUiModel product)? onProductTap;
  final void Function(ProductUiModel product)? onFavoriteTap;
  final bool Function(ProductUiModel product)? isFavorite;
  final String emptyTitle;
  final String emptyMessage;
  final ScrollController? scrollController;

  const ProductGrid({
    super.key,
    required this.products,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onLoadMore,
    this.onProductTap,
    this.onFavoriteTap,
    this.isFavorite,
    this.emptyTitle = 'Aucun produit trouvé',
    this.emptyMessage = 'Aucun article ne correspond à votre sélection.',
    this.scrollController,
  });

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  late ScrollController _controller;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    // Utilise le ScrollController fourni par le parent ou en crée un nouveau
    if (widget.scrollController != null) {
      _controller = widget.scrollController!;
    } else {
      _controller = ScrollController();
      _internalController = true;
    }
    // Écoute les mouvements de défilement pour déclencher la pagination
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// SCÉNARIO MÉTIER : PAGINATION AUTOMATIQUE AU DÉFILEMENT
  /// Lorsque la position de l'utilisateur atteint la fin de la zone de défilement
  /// (avec une marge d'anticipation de 200 dp), et s'il reste des articles à charger,
  /// la fonction `onLoadMore` est invoquée pour récupérer le lot suivant.
  void _onScroll() {
    if (_controller.position.pixels >= _controller.position.maxScrollExtent - 200) {
      if (!widget.isLoading && !widget.isLoadingMore && widget.hasMore) {
        widget.onLoadMore?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- État de chargement initial : grille de shimmer squelette ---
    if (widget.isLoading && widget.products.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;//(tablette ou mode paysage), on passe de 2 à 3 colonnes
          return ShimmerLoading(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppDimens.space16),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppDimens.space12,
                mainAxisSpacing: AppDimens.space16,
                childAspectRatio: 0.62,
              ),
              itemCount: 6,
              itemBuilder: (_, _) => Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radius16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(
                      child: ShimmerBox(
                        height: double.infinity,
                        width: double.infinity,
                        borderRadius: AppDimens.radius16,
                      ),
                    ),
                    SizedBox(height: AppDimens.space8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppDimens.space8),
                      child: ShimmerBox(height: 14, width: 80),
                    ),
                    SizedBox(height: AppDimens.space4),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppDimens.space8),
                      child: ShimmerBox(height: 16, width: double.infinity),
                    ),
                    SizedBox(height: AppDimens.space8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppDimens.space8),
                      child: ShimmerBox(height: 18, width: 60),
                    ),
                    SizedBox(height: AppDimens.space8),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // --- État liste vide ---
    if (widget.products.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: widget.emptyTitle,
        message: widget.emptyMessage,
      );
    }

    // --- Affichage de la grille de produits avec Slivers ---
    return LayoutBuilder(
      builder: (context, constraints) {
        // MOT TECHNIQUE - LayoutBuilder :
        // Détecte la largeur physique de l'écran pour adapter le nombre de colonnes.
        final crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;

        // MOT TECHNIQUE - CustomScrollView :
        // Zone de défilement composée de tranches ("slivers") hautement optimisées.
        return CustomScrollView(
          controller: _controller,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Tranche 1 : Grille des cartes produits
            SliverPadding(
              padding: const EdgeInsets.all(AppDimens.space16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppDimens.space12,
                  mainAxisSpacing: AppDimens.space16,
                  childAspectRatio: 0.60,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = widget.products[index];
                    return ProductCard(
                      product: product,
                      isFavorite: widget.isFavorite?.call(product) ?? false,
                      onTap: () => widget.onProductTap?.call(product),
                      onFavoriteTap: () => widget.onFavoriteTap?.call(product),
                    );
                  },
                  childCount: widget.products.length,
                ),
              ),
            ),

            // Tranche 2 : Indicateur de pagination pendant le chargement de la suite
            if (widget.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppDimens.space16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),

            // Tranche 3 : Espace inférieur de respiration pour dégager la barre d'onglets
            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimens.space32),
            ),
          ],
        );
      },
    );
  }
}
