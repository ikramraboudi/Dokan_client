/// ============================================================================
/// RÔLE DU FICHIER :
/// Tests unitaires / widget pour le nouveau design minimaliste et la sélection
/// de taille/couleur dans `ProductDetailScreen`.
///
/// COMPORTEMENTS TESTÉS :
/// 1) Le choix de la taille met à jour la sélection (pastille en couleur pleine).
/// 2) Le refus d'ajout au panier si une option obligatoire n'est pas choisie.
/// 3) L'ajout au panier déclenche l'état de succès / confirmation.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Dokan_client/feature/product/product_detail_screen.dart';
import 'package:Dokan_client/data/models/product_ui_model.dart';
import 'package:Dokan_client/data/mock/mock_cart_repository.dart';

void main() {
  const shoesProduct = ProductUiModel(
    id: 'prod_shoes_test',
    name: 'Sneakers Minimalistes Cuir',
    description: 'Baskets élégantes en cuir blanc',
    price: 189.0,
    imageUrls: ['https://example.com/shoes1.png', 'https://example.com/shoes2.png'],
    categoryName: 'Chaussures',
    availability: ProductAvailability.inStock,
    colors: ['Blanc', 'Noir'],
    sizes: ['40', '41', '42'],
  );

  Widget createTestWidget({required ProviderContainer container}) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: ProductDetailScreen(productId: 'prod_shoes_test'),
      ),
    );
  }

  group('ProductDetailScreen — Minimalist & Options Selection', () {
    testWidgets('1) Refus d\'ajout au panier sans sélection obligatoire', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          productDetailProvider('prod_shoes_test')
              .overrideWith((ref) => Future.value(shoesProduct)),
          cartProvider.overrideWith(
            (ref) => CartNotifier(
              ref,
              MockCartRepository(),
              const CartState(items: []),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // Vérifier la présence du compteur d'images '01 / 02'
      expect(find.text('01 / 02'), findsOneWidget);

      // Cliquer sur 'Ajouter au panier' sans avoir sélectionné de couleur ni de taille
      await tester.tap(find.text('Ajouter au panier'));
      await tester.pumpAndSettle();

      // Vérifier le SnackBar d'avertissement
      expect(
        find.text('Veuillez sélectionner une couleur avant d\'ajouter au panier.'),
        findsOneWidget,
      );

      // Le panier doit être toujours vide
      expect(container.read(cartProvider).items.isEmpty, isTrue);
    });

    testWidgets('2) Sélection de la couleur et de la taille puis ajout au panier avec succès',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          productDetailProvider('prod_shoes_test')
              .overrideWith((ref) => Future.value(shoesProduct)),
          cartProvider.overrideWith(
            (ref) => CartNotifier(
              ref,
              MockCartRepository(),
              const CartState(items: []),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // 1. Sélectionner la couleur 'Blanc' (tap sur la pastille avec tooltip 'Blanc')
      final colorTooltipFinder = find.byTooltip('Blanc');
      expect(colorTooltipFinder, findsOneWidget);
      await tester.tap(colorTooltipFinder);
      await tester.pumpAndSettle();

      // 2. Sélectionner la taille '42'
      final sizeFinder = find.text('42');
      expect(sizeFinder, findsOneWidget);
      await tester.tap(sizeFinder);
      await tester.pumpAndSettle();

      // Vérifier que la pastille taille 42 est sélectionnée (Container avec couleur primaire)
      final sizeContainer = tester.widget<AnimatedContainer>(
        find.ancestor(
          of: sizeFinder,
          matching: find.byType(AnimatedContainer),
        ).first,
      );
      final decoration = sizeContainer.decoration as BoxDecoration?;
      expect(decoration?.color, isNotNull);
      expect(decoration?.color != Colors.transparent, isTrue);

      // 3. Cliquer sur 'Ajouter au panier'
      await tester.tap(find.text('Ajouter au panier'));
      await tester.pump(const Duration(milliseconds: 100));

      // L'animation de confirmation doit être affichée
      expect(find.text('Ajouté au panier !'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Vérifier que le panier a bien reçu l'article avec options
      final cartItems = container.read(cartProvider).items;
      expect(cartItems.length, equals(1));
      expect(cartItems.first.selectedColor, equals('Blanc'));
      expect(cartItems.first.selectedSize, equals('42'));
    });
  });
}
