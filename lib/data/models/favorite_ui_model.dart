import 'product_ui_model.dart';

/// ============================================================
///  SOUKNA — MODÈLE D'AFFICHAGE ARTICLE FAVORIS
/// ============================================================
class FavoriteUiModel {
  final String productId;
  final ProductUiModel productSummary;
  final DateTime savedAt;

  const FavoriteUiModel({
    required this.productId,
    required this.productSummary,
    required this.savedAt,
  });
}
