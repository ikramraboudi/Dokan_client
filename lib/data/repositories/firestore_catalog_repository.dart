/// ============================================================================
/// RÔLE DU FICHIER : Implémentation concrète interrogeant la collection Firestore products (catégories, recherche, filtres).
/// INTERAGIT AVEC : CatalogScreen, SearchScreen, CheckoutScreen.
/// POUR L'ORAL : « Ce repository exécute les requêtes de recherche et de catalogue paginé sur la collection products de Firestore. »
/// ============================================================================
library;

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
    List<ProductUiModel> allProducts = [];
    try {
      final snapshot = await _productsRef.get();
      allProducts =
          snapshot.docs.map((d) => ProductUiModel.fromFirestore(d)).toList();
    } catch (_) {
      // Fallback si hors ligne
    }

    int countFor(String cat) {
      final target = cat.toLowerCase();
      return allProducts
          .where((p) => p.categoryName.toLowerCase() == target)
          .length;
    }

    return [
      CategoryUiModel(
        id: 'cat_electromenager',
        name: 'electromenager',
        icon: Icons.kitchen_rounded,
        productCount: countFor('electromenager'),
      ),
      CategoryUiModel(
        id: 'cat_vetements',
        name: 'vetements',
        icon: Icons.checkroom_rounded,
        productCount: countFor('vetements'),
      ),
      CategoryUiModel(
        id: 'cat_chaussures',
        name: 'chaussures',
        icon: Icons.hiking_rounded,
        productCount: countFor('chaussures'),
      ),
      CategoryUiModel(
        id: 'cat_smartphones',
        name: 'smartphones',
        icon: Icons.smartphone_rounded,
        productCount: countFor('smartphones'),
      ),
      CategoryUiModel(
        id: 'cat_techs',
        name: 'techs',
        icon: Icons.computer_rounded,
        productCount: countFor('techs'),
      ),
      CategoryUiModel(
        id: 'cat_maison_cuisine',
        name: 'maison&cuisine',
        icon: Icons.soup_kitchen_rounded,
        productCount: countFor('maison&cuisine'),
      ),
      CategoryUiModel(
        id: 'cat_electronique',
        name: 'electronique',
        icon: Icons.devices_rounded,
        productCount: countFor('electronique'),
      ),
      CategoryUiModel(
        id: 'cat_accessoires',
        name: 'accessoires',
        icon: Icons.watch_rounded,
        productCount: countFor('accessoires'),
      ),
      CategoryUiModel(
        id: 'cat_beaute_soins',
        name: 'beaute&soins',
        icon: Icons.spa_rounded,
        productCount: countFor('beaute&soins'),
      ),
      CategoryUiModel(
        id: 'cat_sport_air',
        name: 'sport&air',
        icon: Icons.fitness_center_rounded,
        productCount: countFor('sport&air'),
      ),
      CategoryUiModel(
        id: 'cat_jouets_enfants',
        name: 'jouets&enfants',
        icon: Icons.toys_rounded,
        productCount: countFor('jouets&enfants'),
      ),
      CategoryUiModel(
        id: 'cat_papeterie_bureau',
        name: 'papeterie&bureau',
        icon: Icons.menu_book_rounded,
        productCount: countFor('papeterie&bureau'),
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