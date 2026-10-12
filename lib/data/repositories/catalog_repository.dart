/// ============================================================================
/// RÔLE DU FICHIER :
/// Interface abstraite définissant le contrat technique du catalogue de produits.
/// Déclare les méthodes de récupération des rubriques, des nouveautés, des promotions,
/// de la recherche multicritères et de la consultation détaillée d'un article.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `data/repositories/` (Contrats Abstraits).
///
/// RELATIONS ET DÉPENDANCES :
/// - Implémenté par : `lib/data/mock/mock_catalog_repository.dart`.
/// - Dépend de : `data/models/category_ui_model.dart` et `data/models/product_ui_model.dart`.
/// ============================================================================
library;

import '../models/category_ui_model.dart';
import '../models/product_ui_model.dart';

/// Contrat d'accès aux données du catalogue et moteur de recherche.
abstract class CatalogRepository {
  /// Récupère la liste complète des catégories disponibles.
  Future<List<CategoryUiModel>> getCategories();

  /// Récupère la sélection des nouveaux arrivages.
  Future<List<ProductUiModel>> getNewProducts();

  /// Récupère les articles bénéficiant de réductions promotionnelles.
  Future<List<ProductUiModel>> getDiscountedProducts();

  /// Récupère les articles les plus consultés ou populaires.
  Future<List<ProductUiModel>> getPopularProducts();

  /// Récupère les produits d'une catégorie donnée avec pagination.
  Future<List<ProductUiModel>> getProductsByCategory(
    String categoryName, {
    int page = 1,
    int limit = 10,
  });

  /// Recherche textuelle et filtrage multicritères avec tri et pagination.
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

  /// Récupère la fiche détaillée d'un article à partir de son identifiant unique.
  Future<ProductUiModel?> getProductById(String id);
}
