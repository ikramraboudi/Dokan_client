// lib/services/product_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product_ui_model.dart';

final productServiceProvider = Provider<ProductService>((ref) => ProductService());

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _productsRef => _firestore.collection('products');

  // 1. Nouveaux arrivages (where isNew == true)
  Stream<List<ProductUiModel>> getNewProducts() {
    return _productsRef
        .where('isNew', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ProductUiModel.fromFirestore(d)).toList());
  }

  // 2. Promotions (produits avec hasDiscount / oldPrice renseigné)
  Stream<List<ProductUiModel>> getDiscountedProducts() {
    return _productsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((d) => ProductUiModel.fromFirestore(d))
          .where((product) => product.hasDiscount)
          .toList();
    });
  }

  // 3. Populaires (where isPopular == true)
  Stream<List<ProductUiModel>> getPopularProducts() {
    return _productsRef
        .where('isPopular', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ProductUiModel.fromFirestore(d)).toList());
  }
}