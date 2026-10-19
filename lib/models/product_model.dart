// lib/models/product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
final String id;
final String title;
final double price;
final String description;
final String imageUrl;
final bool inStock;

Product({
required this.id,
required this.title,
required this.price,
required this.description,
required this.imageUrl,
required this.inStock,
});

// Factory to convert a Firestore DocumentSnapshot into a Product object
factory Product.fromFirestore(DocumentSnapshot doc) {
final data = doc.data() as Map<String, dynamic>? ?? {};

return Product(
id: doc.id,
title: data['title'] as String? ?? 'Unnamed Product',
// Handles both integer and double from Firestore safely:
price: (data['price'] as num?)?.toDouble() ?? 0.0,
description: data['description'] as String? ?? '',
imageUrl: data['imageUrl'] as String? ?? '',
inStock: data['inStock'] as bool? ?? true,
);
}
}