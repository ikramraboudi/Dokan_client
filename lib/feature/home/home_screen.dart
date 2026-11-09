/// ============================================================================
/// RÔLE DU FICHIER : Écran d'accueil principal avec carrousel de bannières, boutons catégories et carrousels produits Firestore en temps réel.
/// INTERAGIT AVEC : productServiceProvider, ProductCard, SearchScreen, CatalogScreen.
/// POUR L'ORAL : « L'accueil synchronise en temps réel les nouveautés et promotions depuis Firestore et présente les rubriques phares. »
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/main_shell.dart';
import '../../core/navigation/routes.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_top_bar.dart';
import '../../core/ui/auth_required_dialog.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/loading_state.dart';
import '../../core/ui/product_card.dart';
import '../../data/mock/mock_favorites_repository.dart';
import '../../data/mock/mock_catalog_repository.dart';
import '../../data/models/category_ui_model.dart';
import '../../data/models/product_ui_model.dart';
import '../orders/widgets/active_delivery_banner.dart';
import 'widgets/interactive_banner_carousel.dart';

/// Provider pour charger les catégories de l'accueil
final homeCategoriesProvider = FutureProvider<List<CategoryUiModel>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getCategories();
});

/// Provider pour les nouveaux produits
final newProductsProvider = FutureProvider<List<ProductUiModel>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getNewProducts();
});

/// Provider pour les produits en promo
final discountedProductsProvider = FutureProvider<List<ProductUiModel>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getDiscountedProducts();
});

/// Provider pour les produits populaires
final popularProductsProvider = FutureProvider<List<ProductUiModel>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getPopularProducts();
});

///  Dokan — ÉCRAN D'ACCUEIL COMPLET
///  Utilise un SingleChildScrollView unique pour un défilement
///  vertical fluide sans conflit de geste.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final List<BannerItem> _banners = [
    BannerItem(
      title: 'Nouvelle Collection',
      subtitle: 'Découvrez les dernières tendances de la saison',
      tag: 'NOUVEAU',
      colors: const [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
      onTap: () => context.push(AppRoutes.catalog),
    ),
    BannerItem(
      title: 'Jusqu\'à -30 %',
      subtitle: 'Des réductions exceptionnelles sur une large sélection',
      tag: 'PROMOTIONS',
      colors: const [AppColors.statusOutForDelivery, AppColors.statusPending, AppColors.accent],
      onTap: () => context.push(AppRoutes.catalog),
    ),
    BannerItem(
      title: 'Maison & Décoration',
      subtitle: 'Sublimez vos espaces de vie avec élégance',
      tag: 'TENDANCE',
      colors: const [AppColors.primaryDark, AppColors.primary, AppColors.info],
      onTap: () => context.push(
        '${AppRoutes.catalog}?category=${Uri.encodeComponent('Maison & Décoration')}',
      ),
    ),
  ];

  void _onProductFavoriteTap(ProductUiModel product) {
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

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartCountProvider);
    // Padding inférieur pour que le dernier contenu ne soit pas caché
    // par la barre de navigation ou par la zone de geste système.
    final bottomPadding = MediaQuery.of(context).padding.bottom + AppDimens.space16;

    return Scaffold(
      appBar: AppTopBar(
        showLogo: true,
        actions: [
          Semantics(
            label: 'Ouvrir mon panier ($cartCount articles)',
            button: true,
            child: IconButton(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text(
                  cartCount > 99 ? '99+' : '$cartCount',
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: AppColors.accent,
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.textPrimary,
                ),
              ),
              tooltip: 'Panier',
              onPressed: () => context.go(AppRoutes.cart),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(homeCategoriesProvider);
          ref.invalidate(newProductsProvider);
          ref.invalidate(discountedProductsProvider);
          ref.invalidate(popularProductsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: AppDimens.space16,
            bottom: bottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Barre de recherche cliquable ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                child: Semantics(
                  label: 'Rechercher un produit ou une catégorie sur Dokan',
                  button: true,
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.search),
                    borderRadius: BorderRadius.circular(AppDimens.radius12),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimens.radius12),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                          SizedBox(width: AppDimens.space12),
                          Text(
                            'Rechercher sur Dokan...',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- Détection de commande en cours de livraison & Scan QR Livreur ---
              const ActiveDeliveryBanner(),

              const SizedBox(height: AppDimens.space12),

              // --- Carrousel de bannières interactif (défilement toutes les 2s) ---
              InteractiveBannerCarousel(
                banners: _banners,
                autoScrollInterval: const Duration(seconds: 2),
              ),
              const SizedBox(height: AppDimens.space24),

              // --- Raccourcis Catégories ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Catégories',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.categories),
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space8),
              _buildCategoriesSection(),

              const SizedBox(height: AppDimens.space24),

              // --- Section Nouveautés ---
              _buildProductSection(
                title: 'Nouveaux arrivages',
                provider: newProductsProvider,
              ),

              const SizedBox(height: AppDimens.space24),

              // --- Section Promotions ---
              _buildProductSection(
                title: 'Promotions du moment',
                provider: discountedProductsProvider,
              ),

              const SizedBox(height: AppDimens.space24),

              // --- Section Populaires ---
              _buildProductSection(
                title: 'Produits populaires',
                provider: popularProductsProvider,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categoriesAsync = ref.watch(homeCategoriesProvider);

    return categoriesAsync.when(
      loading: () => SizedBox(
        height: 95,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(width: AppDimens.space12),
          itemBuilder: (_, _) => const ShimmerBox(
            width: 72,
            height: 90,
            borderRadius: AppDimens.radius12,
          ),
        ),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
        child: Text(
          'Impossible de charger les catégories.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
        ),
      ),
      data: (categories) => SizedBox(
        height: 100,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppDimens.space12),
          itemBuilder: (context, index) {
            final cat = categories[index];
            return Semantics(
              label: 'Ouvrir la catégorie ${cat.name}',
              button: true,
              child: InkWell(
                onTap: () {
                  context.push('${AppRoutes.catalog}?category=${Uri.encodeComponent(cat.name)}');
                },
                borderRadius: BorderRadius.circular(AppDimens.radius12),
                child: SizedBox(
                  width: 76,
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 1.0),
                        ),
                        child: Icon(
                          cat.icon,
                          size: 28,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space8),
                      Text(
                        cat.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductSection({
    required String title,
    required FutureProvider<List<ProductUiModel>> provider,
  }) {
    final productsAsync = ref.watch(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: AppDimens.space12),
        productsAsync.when(
          loading: () => SizedBox(
            height: 250,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: AppDimens.space12),
              itemBuilder: (_, _) => const ShimmerBox(
                width: 170,
                height: 250,
                borderRadius: AppDimens.radius16,
              ),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
            child: ErrorState(
              onRetry: () => ref.invalidate(provider),
            ),
          ),
          data: (products) {
            if (products.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimens.space16),
                child: Text('Aucun produit pour le moment.'),
              );
            }

            return SizedBox(
              height: 275,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppDimens.space12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  final isFav = ref.watch(favoritesProvider).maybeWhen(
                        data: (list) => list.any((p) => p.id == product.id),
                        orElse: () => false,
                      );
                  return ProductCard(
                    width: 170,
                    product: product,
                    isFavorite: isFav,
                    onTap: () {
                      context.push(AppRoutes.productDetailPath(product.id));
                    },
                    onFavoriteTap: () => _onProductFavoriteTap(product),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
