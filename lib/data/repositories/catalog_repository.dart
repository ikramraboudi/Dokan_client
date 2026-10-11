import '../models/category_ui_model.dart';
import '../models/product_ui_model.dart';

/// ============================================================
///  SOUKNA — INTERFACE DU REPOSITORY CATALOGUE
/// ============================================================
abstract class CatalogRepository {
  /// Récupère l'ensemble des catégories
  Future<List<CategoryUiModel>> getCategories();

  /// Récupère les nouveaux arrivages
  Future<List<ProductUiModel>> getNewProducts();

  /// Récupère les produits en promotion
  Future<List<ProductUiModel>> getDiscountedProducts();

  /// Récupère les produits les plus populaires
  Future<List<ProductUiModel>> getPopularProducts();

  /// Récupère les produits d'une catégorie avec pagination
  Future<List<ProductUiModel>> getProductsByCategory(
    String categoryName, {
    int page = 1,
    int limit = 10,
  });

  /// Recherche et filtre les produits avec pagination
  Future<List<ProductUiModel>> searchProducts({
    required String query,
    String? categoryName,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    String? sortBy,
    int page = 1,
    int limit = 10,
  });

  /// Récupère le détail d'un produit par son identifiant
  Future<ProductUiModel?> getProductById(String id);
}
