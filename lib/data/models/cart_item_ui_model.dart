/// ============================================================================
/// RÔLE DU FICHIER : Modèle immuable d'une ligne d'article dans le panier avec quantité, prix unitaire et calcul du sous-total de ligne.
/// INTERAGIT AVEC : CartNotifier, CartScreen, CheckoutScreen.
/// POUR L'ORAL : « CartItemUiModel est l'objet immuable représentant un produit sélectionné avec sa variante et sa quantité. »
/// ============================================================================
/// ============================================================================
/// RÔLE DU FICHIER :
/// Modèle représentant une ligne d'article dans le panier d'achat (`CartItemUiModel`).
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `data/models/` (Modèle Panier UI).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : `CartRepository`, `MockCartRepository`, `CartState`, `CartScreen`.
/// - Dépend de : `product_ui_model.dart` pour `ProductAvailability`.
/// ============================================================================
library;

import 'product_ui_model.dart';

/// Ligne d'article du panier d'achat Dokan.
class CartItemUiModel {
  /// Identifiant unique composite (ex: 'prod_1_Taille_M').
  final String id;

  /// Identifiant de référence du produit source.
  final String productId;

  /// Nom de l'article.
  final String name;

  /// URL de la vignette d'illustration.
  final String imageUrl;

  /// Prix unitaire d'achat.
  final double unitPrice;

  /// Nombre d'exemplaires choisis.
  final int quantity;

  /// Libellé de l'option ou de la taille sélectionnée (ex: 'Taille : L').
  final String? variantLabel;

  /// Statut de disponibilité en stock.
  final ProductAvailability availability;

  /// Poids unitaire en kg du produit.
  final double poids;

  const CartItemUiModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    this.variantLabel,
    this.availability = ProductAvailability.inStock,
    this.poids = 0.0,
  });

  /// Total calculé pour cette ligne (prix unitaire × quantité).
  // TODO API : Le montant total sera également recalculé et certifié côté backend.
  double get lineTotal => unitPrice * quantity;

  /// Poids total calculé pour cette ligne (poids unitaire × quantité).
  double get linePoids => poids * quantity;

  /// Vrai si l'article est actuellement disponible.
  bool get isInStock => availability != ProductAvailability.outOfStock;

  /// Méthode de clonage immuable.
  CartItemUiModel copyWith({
    String? id,
    String? productId,
    String? name,
    String? imageUrl,
    double? unitPrice,
    int? quantity,
    String? variantLabel,
    ProductAvailability? availability,
    double? poids,
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
      poids: poids ?? this.poids,
    );
  }
}
