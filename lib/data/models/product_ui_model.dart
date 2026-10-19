// lib/data/models/product_ui_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Énumération décrivant la disponibilité d'un article en stock.
enum ProductAvailability {
  inStock('En stock'),
  limitedStock('Stock limité'),
  outOfStock('Rupture de stock');

  final String label;
  const ProductAvailability(this.label);

  static ProductAvailability fromString(String? value) {
    return switch (value) {
      'limitedStock' => ProductAvailability.limitedStock,
      'outOfStock' => ProductAvailability.outOfStock,
      _ => ProductAvailability.inStock,
    };
  }
}

/// Modèle d'un produit présenté dans le catalogue Dokan.
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

  /// Indique si l'article bénéficie d'une promotion réelle.
  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  /// Indique si l'article peut être commandé (non épuisé).
  bool get isInStock => availability != ProductAvailability.outOfStock;

  // lib/data/models/product_ui_model.dart

  /// ── CONVERTISSEUR DEPUIS FIRESTORE ─────────────────────────────────────────
  factory ProductUiModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Support both imageUrls (List) and imageUrl (String)
    List<String> images = [];
    if (data['imageUrls'] is List) {
      images = (data['imageUrls'] as List).map((e) => e.toString()).toList();
    } else if (data['imageUrl'] is String && (data['imageUrl'] as String).isNotEmpty) {
      images = [data['imageUrl'] as String];
    }

    List<String>? variantsList;
    if (data['variants'] is List) {
      variantsList = (data['variants'] as List).map((e) => e.toString()).toList();
    }

    return ProductUiModel(
      id: doc.id,
      // Supports both 'name' and 'title' fields from Firestore
      name: (data['name'] as String?) ?? (data['title'] as String?) ?? 'Produit sans nom',
      description: data['description'] as String? ?? '',
      imageUrls: images,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      oldPrice: (data['oldPrice'] as num?)?.toDouble(),
      discountLabel: data['discountLabel'] as String?,
      availability: ProductAvailability.fromString(data['availability'] as String?),
      categoryName: data['categoryName'] as String? ?? 'Général',
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      variants: variantsList,
      isNew: data['isNew'] as bool? ?? false,
      isPopular: data['isPopular'] as bool? ?? false,
    );
  }

  /// ── CONVERTISSEUR VERS FIRESTORE ───────────────────────────────────────────
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrls': imageUrls,
      'price': price,
      'oldPrice': oldPrice,
      'discountLabel': discountLabel,
      'availability': availability.name, // 'inStock', 'limitedStock', ou 'outOfStock'
      'categoryName': categoryName,
      'rating': rating,
      'reviewCount': reviewCount,
      'variants': variants,
      'isNew': isNew,
      'isPopular': isPopular,
    };
  }
}