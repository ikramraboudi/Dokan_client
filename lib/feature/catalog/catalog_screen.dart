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
import '../../core/ui/error_state.dart';
import '../../core/ui/filter_sheet.dart';
import '../../core/ui/product_grid.dart';
import '../../core/ui/sort_sheet.dart';
import '../../data/mock/mock_catalog_repository.dart';
import '../../data/mock/mock_favorites_repository.dart';
import '../../data/models/product_ui_model.dart';

/// ============================================================
///  SOUKNA — ÉCRAN CATALOGUE COMPLET (ÉTAPE 3 : FILTRES & TRI)
/// ============================================================
class CatalogScreen extends ConsumerStatefulWidget {
  final String? categoryName;
  final String? searchQuery;

  const CatalogScreen({
    super.key,
    this.categoryName,
    this.searchQuery,
  });

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final List<ProductUiModel> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _currentPage = 1;
  static const int _pageSize = 6;

  // État des filtres et du tri
  late FilterCriteria _filters;
  String _currentSort = 'relevance';

  static const List<String> _categories = [
    'Vêtements et mode',
    'Chaussures et accessoires',
    'Beauté et soins',
    'Électronique et technologie',
    'Maison et décoration',
    'Sport et loisirs',
    'Enfants et bébé',
  ];

  @override
  void initState() {
    super.initState();
    _filters = FilterCriteria(category: widget.categoryName);
    _loadProducts(initial: true);
  }

  Future<void> _loadProducts({bool initial = false}) async {
    if (initial) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
        _products.clear();
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final repo = ref.read(catalogRepositoryProvider);
      final results = await repo.searchProducts(
        query: widget.searchQuery ?? '',
        categoryName: _filters.category,
        minPrice: _filters.minPrice > 0 ? _filters.minPrice : null,
        maxPrice: _filters.maxPrice < 300 ? _filters.maxPrice : null,
        inStockOnly: _filters.inStockOnly ? true : null,
        sortBy: _currentSort,
        page: _currentPage,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (initial) {
            _products.addAll(results);
            _isLoading = false;
          } else {
            _products.addAll(results);
            _isLoadingMore = false;
          }

          if (results.length < _pageSize) {
            _hasMore = false;
          } else {
            _currentPage++;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage =
              'Impossible de charger ces informations. Vérifiez votre connexion puis réessayez.';
        });
      }
    }
  }

  void _openSortSheet() async {
    final selected = await SortSheet.show(context, _currentSort);
    if (selected != null && selected != _currentSort) {
      setState(() {
        _currentSort = selected;
      });
      _loadProducts(initial: true);
    }
  }

  void _openFilterSheet() async {
    final updated = await FilterSheet.show(
      context,
      initialCriteria: _filters,
      availableCategories: _categories,
    );

    if (updated != null) {
      setState(() {
        _filters = updated;
      });
      _loadProducts(initial: true);
    }
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

  String _getSortLabel(String key) {
    final opt = SortSheet.options.firstWhere(
      (element) => element['key'] == key,
      orElse: () => {'label': 'Pertinence'},
    );
    return opt['label']!;
  }

  @override
  Widget build(BuildContext context) {
    final title = _filters.category ??
        (widget.searchQuery != null ? 'Recherche : ${widget.searchQuery}' : 'Catalogue');

    final hasActiveFilters = _filters.isActive || _currentSort != 'relevance';

    return Scaffold(
      appBar: AppTopBar(
        title: title,
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Barre d'outils avec compteur, Trier et Filtrer
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space16,
              vertical: AppDimens.space12,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1.0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isLoading
                        ? 'Chargement...'
                        : '${_products.length} article${_products.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                // Bouton Trier
                OutlinedButton.icon(
                  onPressed: _openSortSheet,
                  icon: const Icon(Icons.sort_rounded, size: 16),
                  label: Text(_getSortLabel(_currentSort)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12),
                    side: BorderSide(
                      color: _currentSort != 'relevance'
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    backgroundColor: _currentSort != 'relevance'
                        ? AppColors.primarySoft
                        : AppColors.transparent,
                    foregroundColor: _currentSort != 'relevance'
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppDimens.space8),

                // Bouton Filtrer
                OutlinedButton.icon(
                  onPressed: _openFilterSheet,
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: Text(
                    _filters.isActive ? 'Filtré' : 'Filtrer',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12),
                    side: BorderSide(
                      color: _filters.isActive ? AppColors.primary : AppColors.border,
                    ),
                    backgroundColor: _filters.isActive
                        ? AppColors.primarySoft
                        : AppColors.transparent,
                    foregroundColor: _filters.isActive
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Chips des filtres actifs
          if (hasActiveFilters)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
                vertical: AppDimens.space8,
              ),
              color: AppColors.surface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_filters.category != null && widget.categoryName == null) ...[
                      InputChip(
                        label: Text(_filters.category!),
                        onDeleted: () {
                          setState(() {
                            _filters = _filters.copyWith(category: () => null);
                          });
                          _loadProducts(initial: true);
                        },
                      ),
                      const SizedBox(width: AppDimens.space8),
                    ],
                    if (_filters.minPrice > 0 || _filters.maxPrice < 300) ...[
                      InputChip(
                        label: Text(
                          '${AppConfig.formatPrice(_filters.minPrice)} - ${AppConfig.formatPrice(_filters.maxPrice)}',
                        ),
                        onDeleted: () {
                          setState(() {
                            _filters = _filters.copyWith(
                              minPrice: 0.0,
                              maxPrice: 300.0,
                            );
                          });
                          _loadProducts(initial: true);
                        },
                      ),
                      const SizedBox(width: AppDimens.space8),
                    ],
                    if (_filters.inStockOnly) ...[
                      InputChip(
                        label: const Text('En stock uniquement'),
                        onDeleted: () {
                          setState(() {
                            _filters = _filters.copyWith(inStockOnly: false);
                          });
                          _loadProducts(initial: true);
                        },
                      ),
                      const SizedBox(width: AppDimens.space8),
                    ],
                    if (_currentSort != 'relevance') ...[
                      InputChip(
                        label: Text('Tri : ${_getSortLabel(_currentSort)}'),
                        onDeleted: () {
                          setState(() {
                            _currentSort = 'relevance';
                          });
                          _loadProducts(initial: true);
                        },
                      ),
                      const SizedBox(width: AppDimens.space8),
                    ],
                  ],
                ),
              ),
            ),

          // Grille de résultats
          Expanded(
            child: _errorMessage != null
                ? ErrorState(
                    message: _errorMessage,
                    onRetry: () => _loadProducts(initial: true),
                  )
                : ProductGrid(
                    products: _products,
                    isLoading: _isLoading,
                    isLoadingMore: _isLoadingMore,
                    hasMore: _hasMore,
                    isFavorite: (product) => ref.watch(favoritesProvider).maybeWhen(
                          data: (list) => list.any((p) => p.id == product.id),
                          orElse: () => false,
                        ),
                    onLoadMore: () => _loadProducts(initial: false),
                    onProductTap: (product) {
                      context.push(AppRoutes.productDetailPath(product.id));
                    },
                    onFavoriteTap: _onFavoriteTap,
                    emptyTitle: 'Aucun produit trouvé',
                    emptyMessage:
                        'Aucun produit ne correspond à votre recherche. Essayez un autre terme ou modifiez les filtres.',
                  ),
          ),
        ],
      ),
    );
  }
}
