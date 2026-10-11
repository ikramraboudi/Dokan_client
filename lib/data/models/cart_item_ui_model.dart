import 'product_ui_model.dart';

/// ============================================================
///  SOUKNA — MODÈLE D'AFFICHAGE LIGNE DE PANIER
/// ============================================================
class CartItemUiModel {
  final String id; // Identifiant unique composite (productId + variant)
  final String productId;
  final String name;
  final String imageUrl;
  final double unitPrice;
  final int quantity;
  final String? variantLabel;
  final ProductAvailability availability;

  const CartItemUiModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    this.variantLabel,
    this.availability = ProductAvailability.inStock,
  });

  /// Total pour cette ligne d'article
  /// // TODO API : à confirmer côté serveur sur totaux
  double get lineTotal => unitPrice * quantity;

  bool get isInStock => availability != ProductAvailability.outOfStock;

  CartItemUiModel copyWith({
    String? id,
    String? productId,
    String? name,
    String? imageUrl,
    double? unitPrice,
    int? quantity,
    String? variantLabel,
    ProductAvailability? availability,
  }) {
    return CartItemUiModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      variantLabel: variantLabel ?? this.variantLabel,
      availability: availability ?? this.availability,
    );
  }
}
