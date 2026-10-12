/// ============================================================================
/// RÔLE DU FICHIER :
/// Modèle représentant un article enregistré dans les favoris du client (`FavoriteUiModel`).
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `data/models/` (Modèle Favoris UI).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : `FavoritesRepository`, `MockFavoritesRepository`, `FavoritesScreen`.
/// - Dépend de : `product_ui_model.dart`.
/// ============================================================================
library;

import 'product_ui_model.dart';

/// Article mis en favori par un client authentifié.
class FavoriteUiModel {
  /// Identifiant du produit associé.
  final String productId;

  /// Données sommaires du produit pour affichage rapide.
  final ProductUiModel productSummary;

  /// Horodatage de l'enregistrement en favori.
  final DateTime savedAt;

  const FavoriteUiModel({
    required this.productId,
    required this.productSummary,
    required this.savedAt,
  });
}
