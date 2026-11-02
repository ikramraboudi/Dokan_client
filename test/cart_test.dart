/// ============================================================================
/// RÔLE DU FICHIER :
/// Tests unitaires validant la logique métier du panier d'achat Dokan
/// et la validation/calcul des coupons Firestore.
///
/// COMPORTEMENTS TESTÉS :
/// 1) Calculs financiers : sous-total brut, seuil de gratuité de livraison
///    (7 DT sous 150 DT, offerte dès 150 DT), total général.
/// 2) Gestion de l'état du panier (`CartNotifier`) : ajout d'article, modification
///    de quantité, suppression avec support d'annulation (*Undo*), vidage du panier.
/// 3) CouponModel : calcul de réductions (% et fixe), validation métier.
/// ============================================================================
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Dokan_client/data/models/cart_item_ui_model.dart';
import 'package:Dokan_client/data/models/coupon_model.dart';
import 'package:Dokan_client/data/models/product_ui_model.dart';
import 'package:Dokan_client/data/mock/mock_cart_repository.dart';

void main() {
  group('CartState — Calculs financiers du panier', () {
    test('Panier vide : montants à zéro', () {
      const state = CartState();
      expect(state.isEmpty, isTrue);
      expect(state.isNotEmpty, isFalse);
      expect(state.totalItemCount, equals(0));
      expect(state.subtotal, equals(0.0));
      expect(state.deliveryFee, equals(0.0));
      expect(state.total, equals(0.0));
    });

    test('Sous-total < 150 DT : frais de livraison à 7 DT', () {
      final items = [
        const CartItemUiModel(
          id: 'p1',
          productId: 'p1',
          name: 'Produit Test',
          imageUrl: '',
          unitPrice: 100.0,
          quantity: 1,
        ),
      ];

      final state = CartState(items: items);

      expect(state.subtotal, equals(100.0));
      expect(state.deliveryFee, equals(7.0));
      expect(state.total, equals(107.0));
    });

    test('Sous-total >= 150 DT : livraison offerte (0 DT)', () {
      final items = [
        const CartItemUiModel(
          id: 'p1',
          productId: 'p1',
          name: 'Produit Cher',
          imageUrl: '',
          unitPrice: 160.0,
          quantity: 1,
        ),
      ];

      final state = CartState(items: items);

      expect(state.subtotal, equals(160.0));
      expect(state.deliveryFee, equals(0.0));
      expect(state.total, equals(160.0));
    });
  });

  group('CartNotifier — Flux d\'opérations sur le panier', () {
    late ProviderContainer container;
    late MockCartRepository mockRepo;

    setUp(() {
      mockRepo = MockCartRepository();
      container = ProviderContainer(
        overrides: [
          cartRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Ajout d\'un produit dans le panier', () async {
      final notifier = container.read(cartProvider.notifier);
      final product = const ProductUiModel(
        id: 'prod_1',
        name: 'Produit 1',
        description: 'Description produit',
        price: 45.0,
        imageUrls: [],
        categoryName: 'Mode',
      );

      await notifier.addProduct(product, quantity: 2);

      final state = container.read(cartProvider);
      expect(state.items.length, equals(1));
      expect(state.items.first.productId, equals('prod_1'));
      expect(state.items.first.quantity, equals(2));
      expect(state.totalItemCount, equals(2));
      expect(state.subtotal, equals(90.0));
    });

    test('Modification de la quantité d\'un article', () async {
      final notifier = container.read(cartProvider.notifier);
      final product = const ProductUiModel(
        id: 'prod_1',
        name: 'Produit 1',
        description: 'Description produit',
        price: 30.0,
        imageUrls: [],
        categoryName: 'Mode',
      );

      await notifier.addProduct(product, quantity: 1);
      final itemId = container.read(cartProvider).items.first.id;

      await notifier.updateQuantity(itemId, 4);

      final state = container.read(cartProvider);
      expect(state.items.first.quantity, equals(4));
      expect(state.subtotal, equals(120.0));
    });

    test('Suppression d\'un article et restauration (Undo)', () async {
      final notifier = container.read(cartProvider.notifier);
      final item = const CartItemUiModel(
        id: 'item_1',
        productId: 'prod_1',
        name: 'Article',
        imageUrl: '',
        unitPrice: 50.0,
        quantity: 1,
      );

      await mockRepo.addItem(item);
      notifier.restoreItem(item, 0);

      expect(container.read(cartProvider).items.length, equals(1));

      final removed = notifier.removeItem('item_1');
      expect(removed, isNotNull);
      expect(container.read(cartProvider).isEmpty, isTrue);

      notifier.restoreItem(removed!, 0);
      expect(container.read(cartProvider).items.length, equals(1));
    });

    test('Vidage complet du panier', () async {
      final notifier = container.read(cartProvider.notifier);
      final product = const ProductUiModel(
        id: 'prod_1',
        name: 'Produit 1',
        description: 'Description produit',
        price: 25.0,
        imageUrls: [],
        categoryName: 'Mode',
      );

      await notifier.addProduct(product, quantity: 3);
      expect(container.read(cartProvider).isNotEmpty, isTrue);

      await notifier.clearCart();
      expect(container.read(cartProvider).isEmpty, isTrue);
      expect(container.read(cartProvider).subtotal, equals(0.0));
    });
  });

  group('CouponModel — Validations et calculs de réductions Firestore', () {
    test('Réduction en pourcentage sans plafond', () {
      final coupon = CouponModel(
        id: 'PROMO15',
        code: 'PROMO15',
        discountType: 'percentage',
        discountValue: 15.0,
        startDate: Timestamp.now(),
      );
      expect(coupon.calculateDiscount(100.0), equals(15.0));
      expect(coupon.calculateDiscount(200.0), equals(30.0));
    });

    test('Réduction en pourcentage avec plafond maximal', () {
      final coupon = CouponModel(
        id: 'PROMO50',
        code: 'PROMO50',
        discountType: 'percentage',
        discountValue: 50.0,
        maxDiscountAmount: 20.0,
        startDate: Timestamp.now(),
      );

      // 50% de 100 = 50 mais plafonné à 20
      expect(coupon.calculateDiscount(100.0), equals(20.0));
      // 50% de 30 = 15 (sous le plafond)
      expect(coupon.calculateDiscount(30.0), equals(15.0));
    });

    test('Réduction en montant fixe', () {
      final coupon = CouponModel(
        id: 'FIX20',
        code: 'FIX20',
        discountType: 'fixed',
        discountValue: 20.0,
        startDate: Timestamp.now(),
      );

      expect(coupon.calculateDiscount(100.0), equals(20.0));
      // La remise ne peut pas dépasser le sous-total
      expect(coupon.calculateDiscount(15.0), equals(15.0));
    });

    test('Validation du montant minimum du panier', () {
      final coupon = CouponModel(
        id: 'MIN70',
        code: 'MIN70',
        discountType: 'percentage',
        discountValue: 10.0,
        minCartAmount: 70.0,
        startDate: Timestamp.now(),
      );

      final errorUnder = coupon.validate(subtotal: 50.0);
      expect(errorUnder, contains('70'));

      final okAbove = coupon.validate(subtotal: 75.0);
      expect(okAbove, isNull);
    });

    test('Validation de la première commande uniquement', () {
      final coupon = CouponModel(
        id: 'FIRST',
        code: 'FIRST',
        discountType: 'fixed',
        discountValue: 10.0,
        isFirstOrderOnly: true,
        startDate: Timestamp.now(),
      );

      // Sans utilisateur connecté
      expect(coupon.validate(subtotal: 50.0, userId: null), contains('connecter'));

      // Utilisateur avec commandes existantes
      expect(
        coupon.validate(subtotal: 50.0, userId: 'u1', userPreviousOrdersCount: 2),
        contains('première commande'),
      );

      // Nouvel utilisateur
      expect(
        coupon.validate(subtotal: 50.0, userId: 'u1', userPreviousOrdersCount: 0),
        isNull,
      );
    });

    test('Validation du type oncePerUser', () {
      final coupon = CouponModel(
        id: 'ONCE',
        code: 'ONCE',
        discountType: 'percentage',
        discountValue: 10.0,
        usageLimitType: 'oncePerUser',
        usedByUsers: ['user_abc'],
        startDate: Timestamp.now(),
      );

      // Utilisateur ayant déjà utilisé le code
      expect(
        coupon.validate(subtotal: 50.0, userId: 'user_abc'),
        contains('déjà utilisé'),
      );
      // Nouvel utilisateur
      expect(
        coupon.validate(subtotal: 50.0, userId: 'user_xyz'),
        isNull,
      );
    });
  });
}
