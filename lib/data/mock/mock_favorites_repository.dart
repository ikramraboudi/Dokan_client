import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_ui_model.dart';
import '../repositories/favorites_repository.dart';

/// ============================================================
///  SOUKNA — MOCK DU REPOSITORY FAVORIS
/// ============================================================
class MockFavoritesRepository implements FavoritesRepository {
  final List<ProductUiModel> _favorites = [];

  MockFavoritesRepository() {
    // Initialise 2 favoris de démonstration
    _favorites.addAll([
      const ProductUiModel(
        id: 'prod-101',
        name: 'Chemise en lin premium à manches retroussables',
        description: 'Chemise en pur lin naturel respirant. Coupe droite moderne.',
        imageUrls: ['https://picsum.photos/seed/soukna-p101-1/600/600'],
        price: 89.900,
        oldPrice: 119.900,
        discountLabel: '-25%',
        availability: ProductAvailability.inStock,
        categoryName: 'Vêtements et mode',
        rating: 4.8,
        reviewCount: 42,
        isNew: true,
        isPopular: true,
      ),
      const ProductUiModel(
        id: 'prod-201',
        name: 'Sneakers urbaines en cuir suédé beige et blanc',
        description: 'Baskets légères avec semelle ergonomique.',
        imageUrls: ['https://picsum.photos/seed/soukna-p201-1/600/600'],
        price: 159.000,
        oldPrice: 199.000,
        discountLabel: '-20%',
        availability: ProductAvailability.inStock,
        categoryName: 'Chaussures et accessoires',
        rating: 4.7,
        reviewCount: 65,
        isNew: true,
        isPopular: true,
      ),
    ]);
  }

  @override
  Future<List<ProductUiModel>> getFavorites() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_favorites);
  }

  @override
  Future<void> addFavorite(ProductUiModel product) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!_favorites.any((p) => p.id == product.id)) {
      _favorites.add(product);
    }
  }

  @override
  Future<void> removeFavorite(String productId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _favorites.removeWhere((p) => p.id == productId);
  }

  @override
  Future<bool> isFavorite(String productId) async {
    return _favorites.any((p) => p.id == productId);
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return MockFavoritesRepository();
});

/// StateNotifier pour gérer l'état réactif global des favoris
class FavoritesNotifier extends StateNotifier<AsyncValue<List<ProductUiModel>>> {
  final FavoritesRepository _repo;

  FavoritesNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      final list = await _repo.getFavorites();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool isProductFavorite(String productId) {
    return state.maybeWhen(
      data: (list) => list.any((p) => p.id == productId),
      orElse: () => false,
    );
  }

  Future<void> toggleFavorite(ProductUiModel product) async {
    final currentList = state.value ?? [];
    final exists = currentList.any((p) => p.id == product.id);

    if (exists) {
      // Retrait optimiste immédiat
      final updated = currentList.where((p) => p.id != product.id).toList();
      state = AsyncValue.data(updated);
      await _repo.removeFavorite(product.id);
    } else {
      // Ajout optimiste immédiat
      final updated = [...currentList, product];
      state = AsyncValue.data(updated);
      await _repo.addFavorite(product);
    }
  }

  Future<void> removeFavorite(String productId) async {
    final currentList = state.value ?? [];
    final updated = currentList.where((p) => p.id != productId).toList();
    state = AsyncValue.data(updated);
    await _repo.removeFavorite(productId);
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<ProductUiModel>>>((ref) {
  final repo = ref.watch(favoritesRepositoryProvider);
  return FavoritesNotifier(repo);
});
