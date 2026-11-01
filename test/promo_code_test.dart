/// ============================================================================
/// RÔLE DU FICHIER :
/// Tests unitaires validant la conformité métier des codes promotionnels Dokan.
///
/// COMPORTEMENTS TESTÉS :
/// 1) Normalisation et insensibilité à la casse (« Dokan10 », « dokan10 »,
///    « DOKAN10 », «  Dokan10  »).
/// 2) Rejet des codes inconnus (« INVALIDE ») et des saisies vides (« », «   »).
/// 3) Calcul exact des montants : sous-total 100 DT -> remise 10 DT -> total 90 DT
///    (hors frais de port).
/// 4) Gestion de l'état du panier (`CartNotifier`) : application, erreur champ vide,
///    erreur code inconnu, retrait manuel et retrait automatique si panier vidé.
/// ============================================================================
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Dokan_client/data/models/promo_code.dart';
import 'package:Dokan_client/data/models/cart_item_ui_model.dart';
import 'package:Dokan_client/data/mock/mock_cart_repository.dart';

void main() {
  group('PromoRules — Validation et normalisation des codes promo', () {
    test('Accepte la casse canonique « Dokan10 »', () {
      final promo = PromoRules.find('Dokan10');
      expect(promo, isNotNull);
      expect(promo!.displayCode, equals('Dokan10'));
      expect(promo.discountValue, equals(10.0));
    });

    test('Accepte tout en minuscules « dokan10 »', () {
      final promo = PromoRules.find('dokan10');
      expect(promo, isNotNull);
      expect(promo!.displayCode, equals('Dokan10'));
      expect(promo.discountValue, equals(10.0));
    });

    test('Accepte tout en majuscules « DOKAN10 »', () {
      final promo = PromoRules.find('DOKAN10');
      expect(promo, isNotNull);
      expect(promo!.displayCode, equals('Dokan10'));
      expect(promo.discountValue, equals(10.0));
    });

    test('Accepte le code avec des espaces en début et fin «  Dokan10  »', () {
      final promo = PromoRules.find('   Dokan10   ');
      expect(promo, isNotNull);
      expect(promo!.displayCode, equals('Dokan10'));
      expect(promo.discountValue, equals(10.0));
    });

    test('Rejette un code inconnu', () {
      final promo = PromoRules.find('DOKAN50');
      expect(promo, isNull);
    });

    test('Rejette un champ vide ou constitué uniquement d\'espaces', () {
      expect(PromoRules.find(''), isNull);
      expect(PromoRules.find('   '), isNull);
    });

    test('Calcule correctement la remise : sous-total 100 -> remise 10', () {
      final promo = PromoRules.find('Dokan10');
      expect(promo, isNotNull);
      final discount = promo!.calculateDiscount(100.0);
      expect(discount, equals(10.0));
      expect(100.0 - discount, equals(90.0));
    });
  });

  group('CartState — Calculs financiers du panier avec remise', () {
    test('Sous-total 100 DT avec remise 10% donne une remise de 10 DT et 90 DT hors port', () {
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

      final stateWithPromo = CartState(
        items: items,
        appliedPromoCode: 'Dokan10',
        discountPercent: 10.0,
      );

      expect(stateWithPromo.subtotal, equals(100.0));
      expect(stateWithPromo.discountAmount, equals(10.0));
      // Sous 150 DT, les frais de port sont de 7 DT : 90 + 7 = 97 DT
      expect(stateWithPromo.total, equals(97.0));
      // Le total net hors livraison est bien de 90 DT
      expect(stateWithPromo.subtotal - stateWithPromo.discountAmount, equals(90.0));
    });
  });

  group('CartNotifier — Flux complet d\'application et de retrait du code promo', () {
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

    test('Erreur lors de la saisie d\'un code vide', () async {
      final notifier = container.read(cartProvider.notifier);
      final result = await notifier.applyPromoCode('   ');

      expect(result, isFalse);
      expect(container.read(cartProvider).promoError, equals('Saisissez un code promo.'));
      expect(container.read(cartProvider).appliedPromoCode, isNull);
    });

    test('Erreur lors de la saisie d\'un code inconnu', () async {
      final notifier = container.read(cartProvider.notifier);
      final result = await notifier.applyPromoCode('CODE_INEXISTANT');

      expect(result, isFalse);
      expect(container.read(cartProvider).promoError, equals('Ce code promo n\'existe pas.'));
      expect(container.read(cartProvider).appliedPromoCode, isNull);
    });

    test('Application réussie de « dokan10 » avec espaces', () async {
      final notifier = container.read(cartProvider.notifier);
      final result = await notifier.applyPromoCode('  dokan10  ');

      expect(result, isTrue);
      final state = container.read(cartProvider);
      expect(state.appliedPromoCode, equals('Dokan10'));
      expect(state.discountPercent, equals(10.0));
      expect(state.promoError, isNull);
    });

    test('Retrait manuel du code promo', () async {
      final notifier = container.read(cartProvider.notifier);
      await notifier.applyPromoCode('Dokan10');
      expect(container.read(cartProvider).appliedPromoCode, equals('Dokan10'));

      notifier.removePromoCode();
      final state = container.read(cartProvider);
      expect(state.appliedPromoCode, isNull);
      expect(state.discountPercent, equals(0.0));
      expect(state.discountAmount, equals(0.0));
    });

    test('Retrait automatique du code promo si le panier devient vide', () async {
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
      // Ajout manuel dans l'état
      container.read(cartProvider.notifier).restoreItem(item, 0);
      await notifier.applyPromoCode('Dokan10');
      expect(container.read(cartProvider).appliedPromoCode, equals('Dokan10'));

      // Suppression du seul article
      notifier.removeItem('item_1');
      final state = container.read(cartProvider);
      expect(state.isEmpty, isTrue);
      expect(state.appliedPromoCode, isNull);
      expect(state.discountPercent, equals(0.0));
    });
  });
}
