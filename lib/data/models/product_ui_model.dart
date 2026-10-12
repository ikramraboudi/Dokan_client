/// ============================================================================
/// RÔLE DU FICHIER :
/// Modèle d'affichage complet d'un produit (`ProductUiModel`) et énumération
/// de disponibilité de stock (`ProductAvailability`).
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `data/models/` (Modèle Produit UI).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par :
///   * `CatalogRepository`, `MockCatalogRepository`.
///   * `ProductCard`, `ProductGrid`.
///   * `HomeScreen`, `CatalogScreen`, `SearchScreen`, `ProductDetailScreen`, `FavoritesScreen`.
/// - Dépend de : Dart pur.
/// ============================================================================
library;

/// Énumération décrivant la disponibilité d'un article en stock.
enum ProductAvailability {
  inStock('En stock'),
  limitedStock('Stock limité'),
  outOfStock('Rupture de stock');

  final String label;
  const ProductAvailability(this.label);
}

/// Modèle d'un produit présenté dans le catalogue Dokan.
class ProductUiModel {
  /// Identifiant unique (ex: 'prod_1').
  final String id;

  /// Nom commercial complet.
  final String name;

  /// Description textuelle détaillée.
  final String description;

  /// Liste des URLs d'images pour la galerie photo.
  final List<String> imageUrls;

  /// Prix de vente actuel (en dinars tunisiens).
  final double price;

  /// Ancien prix barré (nul si le produit n'a pas de réduction).
  final double? oldPrice;

  /// Libellé du badge promotionnel (ex: '-25 %' ou 'PROMO').
  final String? discountLabel;

  /// Statut de disponibilité en stock.
  final ProductAvailability availability;

  /// Nom de la catégorie associée.
  final String categoryName;

  /// Note moyenne sur 5 étoiles (nul si aucun avis).
  final double? rating;

  /// Nombre d'avis d'acheteurs déposés.
  final int reviewCount;

  /// Variantes disponibles au choix (ex: ['S', 'M', 'L'] ou ['Bleu', 'Noir']).
  final List<String>? variants;

  /// Vrai si l'article est un nouvel arrivage.
  final bool isNew;

  /// Vrai si l'article fait partie des meilleures ventes.
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

  /// Indique si l'article bénéficie d'une promotion réelle.
  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  /// Indique si l'article peut être commandé (non épuisé).
  bool get isInStock => availability != ProductAvailability.outOfStock;
}
