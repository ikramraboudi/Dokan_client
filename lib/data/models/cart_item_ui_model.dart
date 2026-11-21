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

  /// Clé de la couleur sélectionnée (ex: 'noir', 'blanc').
  final String? selectedColor;

  /// Libellé de la taille sélectionnée (ex: 'M', '42').
  final String? selectedSize;

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
    this.selectedColor,
    this.selectedSize,
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

  /// Désérialisation tolérante (panier local ou persistant).
  factory CartItemUiModel.fromMap(Map<String, dynamic> map) {
    return CartItemUiModel(
      id: (map['id'] as String?) ?? '',
      productId: (map['productId'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      imageUrl: (map['imageUrl'] as String?) ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ??
          (map['price'] as num?)?.toDouble() ??
          0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      variantLabel: map['variantLabel'] as String?,
      selectedColor: map['selectedColor'] as String?,
      selectedSize: map['selectedSize'] as String?,
      availability: ProductAvailability.fromString(map['availability'] as String?),
      poids: (map['poids'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Sérialisation pour Firestore (`orders.items`).
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'id': productId,
      'name': name,
      'price': unitPrice,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'lineTotal': lineTotal,
      'poids': poids,
      'totalPoids': linePoids,
      if (variantLabel != null) 'variantLabel': variantLabel,
      if (selectedColor != null) 'selectedColor': selectedColor,
      if (selectedSize != null) 'selectedSize': selectedSize,
    };
  }

  /// Méthode de clonage immuable.
  CartItemUiModel copyWith({
    String? id,
    String? productId,
    String? name,
    String? imageUrl,
    double? unitPrice,
    int? quantity,
    String? variantLabel,
    String? selectedColor,
    String? selectedSize,
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
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
      availability: availability ?? this.availability,
      poids: poids ?? this.poids,
    );
  }
}
