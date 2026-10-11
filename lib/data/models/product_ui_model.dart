/// Disponibilité d'un produit
enum ProductAvailability {
  inStock('En stock'),
  limitedStock('Stock limité'),
  outOfStock('Rupture de stock');

  final String label;
  const ProductAvailability(this.label);
}

/// ============================================================
///  SOUKNA — MODÈLE D'AFFICHAGE PRODUIT
/// ============================================================
class ProductUiModel {
  final String id;
  final String name;
  final String description;
  final List<String> imageUrls;
  final double price;
  final double? oldPrice;
  final String? discountLabel;
  final ProductAvailability availability;
  final String categoryName;
  final double? rating;
  final int reviewCount;
  final List<String>? variants;
  final bool isNew;
  final bool isPopular;

  const ProductUiModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrls,
    required this.price,
    this.oldPrice,
    this.discountLabel,
    this.availability = ProductAvailability.inStock,
    required this.categoryName,
    this.rating,
    this.reviewCount = 0,
    this.variants,
    this.isNew = false,
    this.isPopular = false,
  });

  bool get hasDiscount => oldPrice != null && oldPrice! > price;
  bool get isInStock => availability != ProductAvailability.outOfStock;
}
