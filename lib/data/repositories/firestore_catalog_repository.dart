// lib/data/repositories/firestore_catalog_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_ui_model.dart';
import '../models/product_ui_model.dart';
import 'catalog_repository.dart';

final firestoreCatalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return FirestoreCatalogRepository();
});

class FirestoreCatalogRepository implements CatalogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  @override
  Future<List<CategoryUiModel>> getCategories() async {
    // Basic fallback category list
    return const [
      CategoryUiModel(
        id: 'cat_all',
        name: 'Tous',
        icon: Icons.grid_view_rounded,
        productCount: 0,
      ),
      CategoryUiModel(
        id: 'cat_electronics',
        name: 'Électronique',
        icon: Icons.devices_rounded,
        productCount: 0,
      ),
      CategoryUiModel(
        id: 'cat_fashion',
        name: 'Mode',
        icon: Icons.checkroom_rounded,
        productCount: 0,
      ),
    ];
  }

  @override
  Future<List<ProductUiModel>> getNewProducts() async {
    final snapshot = await _productsRef.get();
    final allProducts =
    snapshot.docs.map((d) => ProductUiModel.fromFirestore(d)).toList();

    // Filter by isNew if present, otherwise return all products
    final newProducts = allProducts.where((p) => p.isNew).toList();
    return newProducts.isNotEmpty ? newProducts : allProducts;
  }

  @override
  Future<List<ProductUiModel>> getDiscountedProducts() async {
    final snapshot = await _productsRef.get();
    final allProducts =
    snapshot.docs.map((d) => ProductUiModel.fromFirestore(d)).toList();

    final discounted = allProducts.where((p) => p.hasDiscount).toList();
    return discounted.isNotEmpty ? discounted : allProducts;
  }

  @override
  Future<List<ProductUiModel>> getPopularProducts() async {
    final snapshot = await _productsRef.get();
    final allProducts =
    snapshot.docs.map((d) => ProductUiModel.fromFirestore(d)).toList();

    final popular = allProducts.where((p) => p.isPopular).toList();
    return popular.isNotEmpty ? popular : allProducts;
  }

  @override
  Future<List<ProductUiModel>> getProductsByCategory(
      String categoryName, {
        int page = 1,
        int limit = 10,
      }) async {
    final snapshot = await _productsRef.get();
    final allProducts =
    snapshot.docs.map((d) => ProductUiModel.fromFirestore(d)).toList();

    if (categoryName == 'Tous' || categoryName.isEmpty) return allProducts;

    return allProducts
        .where((p) =>
    p.categoryName.toLowerCase() == categoryName.toLowerCase())
        .toList();
  }

  @override
  Future<List<ProductUiModel>> searchProducts({
    required String query,
    String? categoryName,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    String? sortBy,
    int page = 1,
    int limit = 10,
  }) async {
    final snapshot = await _productsRef.get();
    var list =
    snapshot.docs.map((d) => ProductUiModel.fromFirestore(d)).toList();

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where((p) =>
      p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q))
          .toList();
    }

    if (categoryName != null &&
        categoryName.isNotEmpty &&
        categoryName != 'Tous') {
      list = list
          .where((p) =>
      p.categoryName.toLowerCase() == categoryName.toLowerCase())
          .toList();
    }

    if (minPrice != null) {
      list = list.where((p) => p.price >= minPrice).toList();
    }

    if (maxPrice != null) {
      list = list.where((p) => p.price <= maxPrice).toList();
    }

    if (inStockOnly == true) {
      list = list.where((p) => p.isInStock).toList();
    }

    return list;
  }

  @override
  Future<ProductUiModel?> getProductById(String id) async {
    final doc = await _productsRef.doc(id).get();
    if (doc.exists) {
      return ProductUiModel.fromFirestore(doc);
    }
    return null;
  }
}