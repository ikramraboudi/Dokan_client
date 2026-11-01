/// ============================================================================
/// RÔLE DU FICHIER : Gestionnaire de favoris en mémoire (FavoritesNotifier) avec bascule toggle et vérification d'appartenance.
/// INTERAGIT AVEC : favoritesProvider, FavoritesScreen, ProductCard, ProductDetailScreen.
/// POUR L'ORAL : « FavoritesNotifier gère la liste réactive des articles favoris du client avec notification instantanée des cœurs. »
/// ============================================================================
/// ============================================================================
/// RÔLE DU FICHIER :
/// Implémentation simulée du service des favoris (`MockFavoritesRepository`)
/// et gestionnaire d'état réactif global (`FavoritesNotifier`).
///
/// COMPORTEMENTS MÉTIER CLÉS :
/// 1) Maintient la liste des favoris en mémoire vive pendant la session.
/// 2) Initialisé avec 2 produits par défaut pour la commodité de démonstration.
/// 3) Utilise un mécanisme de mise à jour optimiste : le cœur change d'état
///    instantanément à l'écran sans faire attendre l'utilisateur.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `data/mock/` (Source de Données Simulée & Notifier).
///
/// RELATIONS ET DÉPENDANCES :
/// - Injecté par : `favoritesProvider`.
/// - Consommé par : `FavoritesScreen`, `HomeScreen`, `CatalogScreen`, `ProductCard`.
/// - Dépend de : `data/repositories/favorites_repository.dart` et `data/models/product_ui_model.dart`.
/// ============================================================================
// DONNÉES FICTIVES
// TODO API : Synchroniser la liste des favoris avec la base de données de l'utilisateur distant.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_ui_model.dart';
import '../repositories/favorites_repository.dart';

/// Implémentation en mémoire du stockage des favoris.
class MockFavoritesRepository implements FavoritesRepository {
  final List<ProductUiModel> _favorites = [];

  // TODO Firebase : à migrer vers Firestore (favoris synchronisés avec le compte utilisateur)
  MockFavoritesRepository();

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

/// Provider d'injection du repository de favoris.
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return MockFavoritesRepository();
});

/// GESTIONNAIRE D'ÉTAT DES FAVORIS (FavoritesNotifier)
///
/// MOT TECHNIQUE - AsyncValue :
/// Encapsule les données dans un conteneur représentant les états :
/// `loading`, `data` (succès avec liste de produits) ou `error`.

class FavoritesNotifier extends StateNotifier<AsyncValue<List<ProductUiModel>>> {
  final FavoritesRepository _repo;

  FavoritesNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadFavorites();
  }

  /// Charge la liste initiale des favoris depuis le repository.
  Future<void> loadFavorites() async {
    try {
      final list = await _repo.getFavorites();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Vérifie rapidement si un article est actuellement dans les favoris.
  bool isProductFavorite(String productId) {
    return state.maybeWhen(
      data: (list) => list.any((p) => p.id == productId),
      orElse: () => false,
    );
  }

  /// SCÉNARIO MÉTIER : BASCULE DE FAVORI OPTIMISTE
  /// 1) L'utilisateur touche le cœur.
  /// 2) L'état local `state` est mis à jour immédiatement pour que l'interface
  ///    réagisse instantanément (zéro latence perçue par l'utilisateur).
  /// 3) L'appel réseau asynchrone est déclenché en arrière-plan.

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

  /// Supprime un favori et synchronise le repository.
  Future<void> removeFavorite(String productId) async {
    final currentList = state.value ?? [];
    final updated = currentList.where((p) => p.id != productId).toList();
    state = AsyncValue.data(updated);
    await _repo.removeFavorite(productId);
  }

  /// Réinitialise la liste locale lors d'une déconnexion.
  void clear() {
    state = const AsyncValue.data([]);
  }
}

/// Provider global des favoris accessible dans toute l'application.
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<ProductUiModel>>>((ref) {
  final repo = ref.watch(favoritesRepositoryProvider);
  return FavoritesNotifier(repo);
});
