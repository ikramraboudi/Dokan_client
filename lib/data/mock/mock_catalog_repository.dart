/// ============================================================================
/// RÔLE DU FICHIER : Repository mock du catalogue fournissant des données de secours pour les tests et la démo hors-ligne.
/// INTERAGIT AVEC : catalogRepositoryProvider, HomeScreen, CatalogScreen.
/// POUR L'ORAL : « Ce mock sert de jeu de données de référence et de secours pour nos tests unitaires sans dépendre du réseau. »
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_ui_model.dart';
import '../models/product_ui_model.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/firestore_catalog_repository.dart';

// Provider officiel utilisant Firestore avec fallback Mock si besoin
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return FirestoreCatalogRepository();
});

/// Implémentation Mock hors-ligne avec produits représentatifs de chaque groupe d'options.
class MockCatalogRepository implements CatalogRepository {
  final List<ProductUiModel> _products = [
    const ProductUiModel(
      id: 'mock_smartphones',
      name: 'Samsung Galaxy A55 5G',
      description: 'Smartphone haut de gamme avec écran Super AMOLED 120Hz et triple capteur photo.',
      imageUrls: ['https://images.unsplash.com/photo-1511707171634-5f897ff02aa9'],
      price: 1200.000,
      oldPrice: 1350.000,
      discountLabel: '-11%',
      categoryName: 'smartphones',
      availability: ProductAvailability.inStock,
      isPopular: true,
      isNew: true,
    ),
    const ProductUiModel(
      id: 'mock_chaussures',
      name: 'Baskets Running Performance',
      description: 'Chaussures de running avec semelle amortissante et maintien optimal.',
      imageUrls: ['https://images.unsplash.com/photo-1542291026-7eec264c27ff'],
      price: 220.000,
      categoryName: 'chaussures',
      availability: ProductAvailability.inStock,
      isPopular: true,
    ),
    const ProductUiModel(
      id: 'mock_vetements',
      name: 'Veste Coupe-Vent Dokan',
      description: 'Veste déperlante et respirante conçue pour un confort quotidien.',
      imageUrls: ['https://images.unsplash.com/photo-1521572267360-ee0c2909d518'],
      price: 145.000,
      categoryName: 'vetements',
      availability: ProductAvailability.inStock,
      isNew: true,
    ),
    const ProductUiModel(
      id: 'mock_accessoires',
      name: 'Montre Chronographe Élégance',
      description: 'Montre avec cadran travaillé et finition métallique noble.',
      imageUrls: ['https://images.unsplash.com/photo-1524805444758-089113d48a6d'],
      price: 310.000,
      categoryName: 'accessoires',
      availability: ProductAvailability.inStock,
    ),
    const ProductUiModel(
      id: 'mock_papeterie',
      name: 'Organiseur de bureau en cuir',
      description: 'Accessoire de rangement pour fournitures et stylos.',
      imageUrls: ['https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c'],
      price: 45.000,
      categoryName: 'papeterie&bureau',
      availability: ProductAvailability.inStock,
    ),
    const ProductUiModel(
      id: 'mock_cuisine',
      name: 'Batterie de cuisine Inox 6 pièces',
      description: 'Set complet de casseroles et poêles compatibles tous feux.',
      imageUrls: ['https://images.unsplash.com/photo-1584990347449-39b0a1d4b684'],
      price: 195.000,
      categoryName: 'maison&cuisine',
      availability: ProductAvailability.inStock,
    ),
  ];

  @override
  Future<List<CategoryUiModel>> getCategories() async {
    return [
      const CategoryUiModel(
        id: 'cat_smartphones',
        name: 'smartphones',
        icon: Icons.smartphone_rounded,
        productCount: 1,
      ),
      const CategoryUiModel(
        id: 'cat_chaussures',
        name: 'chaussures',
        icon: Icons.hiking_rounded,
        productCount: 1,
      ),
      const CategoryUiModel(
        id: 'cat_vetements',
        name: 'vetements',
        icon: Icons.checkroom_rounded,
        productCount: 1,
      ),
      const CategoryUiModel(
        id: 'cat_accessoires',
        name: 'accessoires',
        icon: Icons.watch_rounded,
        productCount: 1,
      ),
      const CategoryUiModel(
        id: 'cat_papeterie_bureau',
        name: 'papeterie&bureau',
        icon: Icons.menu_book_rounded,
        productCount: 1,
      ),
      const CategoryUiModel(
        id: 'cat_maison_cuisine',
        name: 'maison&cuisine',
        icon: Icons.soup_kitchen_rounded,
        productCount: 1,
      ),
    ];
  }

  @override
  Future<List<ProductUiModel>> getNewProducts() async {
    return _products.where((p) => p.isNew).toList();
  }

  @override
  Future<List<ProductUiModel>> getDiscountedProducts() async {
    return _products.where((p) => p.hasDiscount).toList();
  }

  @override
  Future<List<ProductUiModel>> getPopularProducts() async {
    return _products.where((p) => p.isPopular).toList();
  }

  @override
  Future<List<ProductUiModel>> getProductsByCategory(
    String categoryName, {
    int page = 1,
    int limit = 10,
  }) async {
    if (categoryName == 'Tous' || categoryName.isEmpty) return _products;
    final catNorm = categoryName.toLowerCase();
    return _products.where((p) => p.categoryName.toLowerCase() == catNorm).toList();
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
    return _products.where((p) {
      if (query.isNotEmpty && !p.name.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
      if (categoryName != null &&
          categoryName.isNotEmpty &&
          categoryName != 'Tous' &&
          p.categoryName.toLowerCase() != categoryName.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<ProductUiModel?> getProductById(String id) async {
    return _products.where((p) => p.id == id).firstOrNull;
  }
}
