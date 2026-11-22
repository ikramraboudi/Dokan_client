import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Dokan_client/core/utils/product_options.dart';
import 'package:Dokan_client/data/mock/mock_cart_repository.dart';
import 'package:Dokan_client/data/models/cart_item_ui_model.dart';
import 'package:Dokan_client/data/models/order_model.dart';
import 'package:Dokan_client/data/models/product_ui_model.dart';

void main() {
  group('1. Correspondance Catégorie -> Options (Groupes A à E et non concernée)', () {
    test('Groupe A : Électroménager, Smartphones, Tech, Électronique -> Blanc, Noir, Beige, Rouge bordeaux, Gris (0 taille)', () {
      final categories = [
        'Électroménager',
        'electromenager',
        'cat_electromenager',
        'Smartphones',
        'smartphones',
        'cat_smartphones',
        'Tech',
        'techs',
        'cat_techs',
        'Électronique',
        'electronique',
        'cat_electronique',
      ];

      for (final cat in categories) {
        expect(ProductOptions.getGroupForCategory(cat), 'A', reason: 'Failed for $cat');
        final product = ProductUiModel(
          id: 'test_a',
          name: 'Produit A',
          description: '',
          imageUrls: const [],
          price: 100,
          categoryName: cat,
        );
        expect(
          ProductOptions.getColorsForProduct(product),
          ['blanc', 'noir', 'beige', 'rouge_bordeaux', 'gris'],
        );
        expect(ProductOptions.getSizesForProduct(product), isEmpty);
      }
    });

    test('Groupe B : Chaussures -> Noir, Blanc, Bleu marine & 8 pointures', () {
      final categories = ['Chaussures', 'chaussures', 'cat_chaussures', 'CHAUSSURE'];
      for (final cat in categories) {
        expect(ProductOptions.getGroupForCategory(cat), 'B');
        final product = ProductUiModel(
          id: 'test_b',
          name: 'Sneakers',
          description: '',
          imageUrls: const [],
          price: 150,
          categoryName: cat,
        );
        expect(ProductOptions.getColorsForProduct(product), ['noir', 'blanc', 'bleu_marine']);
        expect(ProductOptions.getSizesForProduct(product), ['36', '38', '39', '40', '41', '42', '43', '44']);
      }
    });

    test('Groupe C : Vêtements -> 6 couleurs & Tailles S à XXL', () {
      final categories = ['Vêtements', 'vetements', 'cat_vetements', 'Vêtement'];
      for (final cat in categories) {
        expect(ProductOptions.getGroupForCategory(cat), 'C');
        final product = ProductUiModel(
          id: 'test_c',
          name: 'T-Shirt',
          description: '',
          imageUrls: const [],
          price: 40,
          categoryName: cat,
        );
        expect(
          ProductOptions.getColorsForProduct(product),
          ['noir', 'blanc', 'rouge', 'vert', 'bleu', 'jaune'],
        );
        expect(ProductOptions.getSizesForProduct(product), ['S', 'M', 'L', 'XL', 'XXL']);
      }
    });

    test('Groupe D : Accessoires -> Bronze, Doré, Argent (0 taille)', () {
      final categories = ['Accessoires', 'accessoires', 'cat_accessoires'];
      for (final cat in categories) {
        expect(ProductOptions.getGroupForCategory(cat), 'D');
        final product = ProductUiModel(
          id: 'test_d',
          name: 'Montre',
          description: '',
          imageUrls: const [],
          price: 80,
          categoryName: cat,
        );
        expect(ProductOptions.getColorsForProduct(product), ['bronze', 'dore', 'argent']);
        expect(ProductOptions.getSizesForProduct(product), isEmpty);
      }
    });

    test('Groupe E : Papeterie et bureau, Sport et air -> Blanc, Noir, Beige (0 taille)', () {
      final categories = [
        'Papeterie et bureau',
        'papeterie&bureau',
        'cat_papeterie_bureau',
        'Sport et air',
        'sport&air',
        'cat_sport_air',
        'Sport et plein air',
      ];
      for (final cat in categories) {
        expect(ProductOptions.getGroupForCategory(cat), 'E', reason: 'Failed for $cat');
        final product = ProductUiModel(
          id: 'test_e',
          name: 'Cahier / Ballon',
          description: '',
          imageUrls: const [],
          price: 25,
          categoryName: cat,
        );
        expect(ProductOptions.getColorsForProduct(product), ['blanc', 'noir', 'beige']);
        expect(ProductOptions.getSizesForProduct(product), isEmpty);
      }
    });

    test('Catégories non concernées (Maison & cuisine, Beauté & soins, etc.) -> aucune option', () {
      final unconcerned = [
        'Maison & cuisine',
        'maison&cuisine',
        'cat_maison_cuisine',
        'beaute&soins',
        'jouets&enfants',
      ];
      for (final cat in unconcerned) {
        expect(ProductOptions.getGroupForCategory(cat), isNull);
        final product = ProductUiModel(
          id: 'test_none',
          name: 'Casserole',
          description: '',
          imageUrls: const [],
          price: 60,
          categoryName: cat,
        );
        expect(ProductOptions.getColorsForProduct(product), isEmpty);
        expect(ProductOptions.getSizesForProduct(product), isEmpty);
        expect(ProductOptions.hasOptions(product), isFalse);
      }
    });

    test('Priorité aux options personnalisées du produit si définies', () {
      const customProduct = ProductUiModel(
        id: 'custom_1',
        name: 'Produit personnalisé',
        description: '',
        imageUrls: [],
        price: 50,
        categoryName: 'vetements',
        colors: ['rouge', 'bleu'],
        sizes: ['M', 'L'],
      );
      expect(ProductOptions.getColorsForProduct(customProduct), ['rouge', 'bleu']);
      expect(ProductOptions.getSizesForProduct(customProduct), ['M', 'L']);
    });
  });

  group('2. Clé de ligne du panier et gestion des variantes', () {
    test('Deux variantes différentes du même produit créent deux lignes séparées', () async {
      final container = ProviderContainer();
      final notifier = container.read(cartProvider.notifier);

      const product = ProductUiModel(
        id: 'prod_sneaker',
        name: 'Sneaker',
        description: '',
        imageUrls: ['img.jpg'],
        price: 200,
        categoryName: 'chaussures',
      );

      // Ajout variante 1 : Noir / 42
      await notifier.addProduct(
        product,
        quantity: 1,
        selectedColor: 'noir',
        selectedSize: '42',
      );

      // Ajout variante 2 : Blanc / 44
      await notifier.addProduct(
        product,
        quantity: 1,
        selectedColor: 'blanc',
        selectedSize: '44',
      );

      final state = container.read(cartProvider);
      expect(state.items.length, 2);
      expect(state.items[0].id, 'prod_sneaker_noir_42_');
      expect(state.items[0].selectedColor, 'noir');
      expect(state.items[0].selectedSize, '42');
      expect(state.items[0].quantity, 1);

      expect(state.items[1].id, 'prod_sneaker_blanc_44_');
      expect(state.items[1].selectedColor, 'blanc');
      expect(state.items[1].selectedSize, '44');
      expect(state.items[1].quantity, 1);
    });

    test('La même variante ajoutée une 2e fois incrémente la quantité sans créer de nouvelle ligne', () async {
      final container = ProviderContainer();
      final notifier = container.read(cartProvider.notifier);

      const product = ProductUiModel(
        id: 'prod_shirt',
        name: 'T-Shirt',
        description: '',
        imageUrls: ['img.jpg'],
        price: 50,
        categoryName: 'vetements',
      );

      // 1er ajout : Rouge / M
      await notifier.addProduct(
        product,
        quantity: 2,
        selectedColor: 'rouge',
        selectedSize: 'M',
      );

      // 2e ajout : Rouge / M
      await notifier.addProduct(
        product,
        quantity: 3,
        selectedColor: 'rouge',
        selectedSize: 'M',
      );

      final state = container.read(cartProvider);
      expect(state.items.length, 1);
      expect(state.items.first.quantity, 5);
      expect(state.items.first.selectedColor, 'rouge');
      expect(state.items.first.selectedSize, 'M');
    });
  });

  group('3. Validation et obligation de sélection', () {
    test('Détection correcte des options manquantes avant ajout', () {
      const clothingProduct = ProductUiModel(
        id: 'prod_vet',
        name: 'Veste',
        description: '',
        imageUrls: [],
        price: 120,
        categoryName: 'vetements',
      );

      final availableColors = ProductOptions.getColorsForProduct(clothingProduct);
      final availableSizes = ProductOptions.getSizesForProduct(clothingProduct);

      expect(availableColors.isNotEmpty, isTrue);
      expect(availableSizes.isNotEmpty, isTrue);

      String? selectedColor;
      String? selectedSize;

      // Cas 1 : Aucun choix
      bool missingBoth = (selectedColor == null && availableColors.isNotEmpty) &&
          (selectedSize == null && availableSizes.isNotEmpty);
      expect(missingBoth, isTrue);

      // Cas 2 : Couleur choisie, taille manquante
      selectedColor = 'noir';
      bool missingSizeOnly = selectedColor != null && (selectedSize == null && availableSizes.isNotEmpty);
      expect(missingSizeOnly, isTrue);

      // Cas 3 : Les deux choisis
      selectedSize = 'L';
      bool allSelected = (selectedColor != null || availableColors.isEmpty) &&
          (selectedSize != null || availableSizes.isEmpty);
      expect(allSelected, isTrue);
    });
  });

  group('4. Rétrocompatibilité et lecture d\'anciennes commandes Firestore', () {
    test('Désérialisation d\'une ancienne commande sans selectedColor ni selectedSize', () {
      final oldOrderItemData = {
        'productId': 'prod_old_1',
        'name': 'Produit ancien',
        'imageUrl': 'https://example.com/old.png',
        'price': 85.0,
        'quantity': 2,
        'lineTotal': 170.0,
        'poids': 1.2,
      };

      final orderItem = OrderItemUiModel.fromMap(oldOrderItemData);

      expect(orderItem.productId, 'prod_old_1');
      expect(orderItem.name, 'Produit ancien');
      expect(orderItem.selectedColor, isNull);
      expect(orderItem.selectedSize, isNull);
      expect(orderItem.unitPrice, 85.0);
      expect(orderItem.quantity, 2);
    });

    test('Sérialisation et désérialisation d\'une nouvelle commande avec selectedColor et selectedSize', () {
      final newOrderItem = const OrderItemUiModel(
        productId: 'prod_new_1',
        name: 'Polo Bleu',
        imageUrl: 'https://example.com/polo.png',
        unitPrice: 65.0,
        quantity: 1,
        selectedColor: 'bleu_marine',
        selectedSize: 'XL',
        lineTotal: 65.0,
      );

      final map = newOrderItem.toMap();
      expect(map['selectedColor'], 'bleu_marine');
      expect(map['selectedSize'], 'XL');

      final deserialized = OrderItemUiModel.fromMap(map);
      expect(deserialized.selectedColor, 'bleu_marine');
      expect(deserialized.selectedSize, 'XL');
      expect(deserialized.lineTotal, 65.0);
    });

    test('Désérialisation de CartItemUiModel tolérante aux anciens payloads', () {
      final oldCartMap = {
        'id': 'legacy_item',
        'productId': 'prod_leg',
        'name': 'Ancien item',
        'imageUrl': '',
        'unitPrice': 30.0,
        'quantity': 1,
      };

      final cartItem = CartItemUiModel.fromMap(oldCartMap);
      expect(cartItem.selectedColor, isNull);
      expect(cartItem.selectedSize, isNull);
      expect(cartItem.unitPrice, 30.0);
    });
  });
}
