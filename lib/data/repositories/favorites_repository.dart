import '../models/product_ui_model.dart';

/// ============================================================
///  SOUKNA — INTERFACE DU REPOSITORY FAVORIS
/// ============================================================
abstract class FavoritesRepository {
  /// Récupère la liste des produits favoris
  Future<List<ProductUiModel>> getFavorites();

  /// Ajoute un produit aux favoris
  Future<void> addFavorite(ProductUiModel product);

  /// Retire un produit des favoris
  Future<void> removeFavorite(String productId);

  /// Vérifie si un produit est dans les favoris
  Future<bool> isFavorite(String productId);
}
