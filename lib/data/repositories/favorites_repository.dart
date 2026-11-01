/// ============================================================================
/// RÔLE DU FICHIER : Interface abstraite décrivant l'ajout, le retrait et l'observation des articles favoris.
/// INTERAGIT AVEC : mock_favorites_repository.dart.
/// POUR L'ORAL : « FavoritesRepository définit le contrat de gestion des coups de cœur client. »
/// ============================================================================
/// ============================================================================
/// RÔLE DU FICHIER :
/// Interface abstraite définissant le contrat technique de gestion des favoris client.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `data/repositories/` (Contrats Abstraits).
///
/// RELATIONS ET DÉPENDANCES :
/// - Implémenté par : `lib/data/mock/mock_favorites_repository.dart`.
/// - Dépend de : `data/models/product_ui_model.dart`.
/// ============================================================================
library;

import '../models/product_ui_model.dart';

/// Contrat de gestion des articles favoris d'un client.
abstract class FavoritesRepository {
  /// Récupère la liste des produits mis de côté par le client.
  Future<List<ProductUiModel>> getFavorites();

  /// Ajoute un produit à la liste des favoris.
  Future<void> addFavorite(ProductUiModel product);

  /// Retire un produit de la liste des favoris.
  Future<void> removeFavorite(String productId);

  /// Vérifie si un article précis fait déjà partie des favoris du client.
  Future<bool> isFavorite(String productId);
}
