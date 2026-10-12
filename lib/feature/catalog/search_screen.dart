import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/auth_required_dialog.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/product_grid.dart';
import '../../data/mock/mock_catalog_repository.dart';
import '../../data/mock/mock_favorites_repository.dart';
import '../../data/models/product_ui_model.dart';

/// Provider pour conserver l'historique des recherches récentes en mémoire
final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  return RecentSearchesNotifier();
});

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier()
      : super(['Chemise en lin', 'Sneakers', 'Écouteurs', 'Robe']);

  void addSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    state = [trimmed, ...state.where((item) => item.toLowerCase() != trimmed.toLowerCase())]
        .take(6)
        .toList();
  }

  void removeSearch(String query) {
    state = state.where((item) => item != query).toList();
  }

  void clearAll() {
    state = [];
  }
}

///  Dokan — ÉCRAN RECHERCHE AVANCÉE

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<ProductUiModel> _results = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSearched = false;

  static const List<String> _popularSuggestions = [
    'Sneakers',
    'Montre',
    'Huile d\'argan',
    'Tapis berbère',
    'Yoga',
    'Bébé',
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _hasSearched = false;
        _results = [];
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    ref.read(recentSearchesProvider.notifier).addSearch(query);

    try {
      final repo = ref.read(catalogRepositoryProvider);
      final products = await repo.searchProducts(query: query);

      if (mounted) {
        setState(() {
          _results = products;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Impossible de charger ces informations. Vérifiez votre connexion puis réessayez.';
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final recentSearches = ref.watch(recentSearchesProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: Semantics(
          label: 'Retour',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.textPrimary,
            tooltip: 'Retour',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: AppDimens.space16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppDimens.radius12),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (value) => _performSearch(value.trim()),
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Rechercher sur Dokan...',
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space12,
                  vertical: 10,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? Semantics(
                        label: 'Effacer la recherche',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: AppColors.textSecondary,
                          tooltip: 'Effacer',
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(recentSearches),
    );
  }

  Widget _buildBody(List<String> recentSearches) {
    if (_isLoading) {
      return ProductGrid(
        products: const [],
        isLoading: true,
      );
    }

    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage,
        onRetry: () => _performSearch(_searchController.text.trim()),
      );
    }

    // Affichage des résultats après soumission
    if (_hasSearched) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.space16,
              AppDimens.space12,
              AppDimens.space16,
              AppDimens.space4,
            ),
            child: Text(
              '${_results.length} résultat${_results.length > 1 ? 's' : ''} trouvé${_results.length > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ProductGrid(
              products: _results,
              isFavorite: (product) => ref.watch(favoritesProvider).maybeWhen(
                    data: (list) => list.any((p) => p.id == product.id),
                    orElse: () => false,
                  ),
              onProductTap: (product) {
                context.push(AppRoutes.productDetailPath(product.id));
              },
              onFavoriteTap: _onFavoriteTap,
              emptyTitle: 'Aucun résultat trouvé',
              emptyMessage:
                  'Aucun produit ne correspond à votre recherche. Essayez un autre terme ou modifiez les filtres.',
            ),
          ),
        ],
      );
    }

    // Vue initiale avec recherches récentes et suggestions
    return ListView(
      padding: const EdgeInsets.all(AppDimens.space16),
      children: [
        // Recherches récentes
        if (recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recherches récentes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () {
                  ref.read(recentSearchesProvider.notifier).clearAll();
                },
                child: const Text('Effacer tout'),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space8),
          Wrap(
            spacing: AppDimens.space8,
            runSpacing: AppDimens.space8,
            children: recentSearches.map((term) {
              return Chip(
                label: Text(term),
                backgroundColor: AppColors.surface,
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                deleteIconColor: AppColors.textSecondary,
                onDeleted: () {
                  ref.read(recentSearchesProvider.notifier).removeSearch(term);
                },
                avatar: const Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimens.space24),
        ],

        // Suggestions populaires
        Text(
          'Recherches populaires',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppDimens.space12),
        Wrap(
          spacing: AppDimens.space8,
          runSpacing: AppDimens.space8,
          children: _popularSuggestions.map((suggestion) {
            return ActionChip(
              avatar: const Icon(
                Icons.trending_up_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              label: Text(suggestion),
              backgroundColor: AppColors.primarySoft,
              labelStyle: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              onPressed: () {
                _searchController.text = suggestion;
                _performSearch(suggestion);
              },
            );
          }).toList(),
        ),

        const SizedBox(height: AppDimens.space32),
        // Astuce pour tester les états
        Container(
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radius12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Astuce de démonstration :',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppDimens.space4),
              Text(
                '• Tapez "#error" pour simuler une erreur réseau.\n• Tapez "#empty" pour tester l\'écran aucun résultat.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
