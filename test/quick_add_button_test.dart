/// ============================================================================
/// RÔLE DU FICHIER :
/// Tests de widgets pour le composant d'ajout rapide au panier (`QuickAddButton`).
///
/// COMPORTEMENTS TESTÉS :
/// 1) Produit simple (sans variante) :
///    - Panier = 0 : affiche le bouton circulaire d'ajout rapide.
///    - Un appui ajoute le produit et affiche le compteur interactif (− 1 +).
///    - Appui sur « + » incrémente à 2.
///    - Appui sur « − » décrémente à 1.
///    - Appui sur « − » à 1 retire l'article et réaffiche le bouton rond.
/// 2) Produit avec variantes :
///    - Affiche le bouton d'options avec icône tune.
///    - Un appui ouvre la feuille modale de choix des options.
/// 3) Produit en rupture de stock :
///    - Ne rend aucun bouton d'ajout (SizedBox.shrink).
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Dokan_client/core/ui/quick_add_button.dart';
import 'package:Dokan_client/data/models/product_ui_model.dart';

void main() {
  const simpleProduct = ProductUiModel(
    id: 'prod_simple',
    name: 'T-shirt Basique',
    description: 'T-shirt en coton',
    price: 35.0,
    imageUrls: ['https://example.com/tshirt.png'],
    categoryName: 'Mode',
    availability: ProductAvailability.inStock,
  );

  const productWithVariants = ProductUiModel(
    id: 'prod_variants',
    name: 'Chaussures Sport',
    description: 'Chaussures confortables',
    price: 120.0,
    imageUrls: ['https://example.com/shoes.png'],
    categoryName: 'Chaussures',
    variants: ['40', '41', '42', '43'],
    availability: ProductAvailability.inStock,
  );

  const outOfStockProduct = ProductUiModel(
    id: 'prod_oos',
    name: 'Montre Luxe',
    description: 'Montre élégante',
    price: 450.0,
    imageUrls: ['https://example.com/watch.png'],
    categoryName: 'Accessoires',
    availability: ProductAvailability.outOfStock,
  );

  Widget createTestWidget({
    required Widget child,
    ProviderContainer? container,
  }) {
    return UncontrolledProviderScope(
      container: container ?? ProviderContainer(),
      child: MaterialApp(
        home: Scaffold(
          body: Center(child: child),
        ),
      ),
    );
  }

  group('QuickAddButton — Tests de widgets', () {
    testWidgets('Produit en rupture : aucun bouton affiché', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const QuickAddButton(product: outOfStockProduct),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QuickAddButton), findsOneWidget);
      expect(find.byIcon(Icons.add_shopping_cart_rounded), findsNothing);
      expect(find.byIcon(Icons.tune_rounded), findsNothing);
    });

    testWidgets('Produit simple : affiche bouton rond d\'ajout à zéro', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createTestWidget(
          container: container,
          child: const QuickAddButton(product: simpleProduct),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_shopping_cart_rounded), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('Produit simple : cycle complet ajout, incrément, décrément et retrait',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createTestWidget(
          container: container,
          child: const QuickAddButton(product: simpleProduct),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Appui initial -> Ajout dans le panier
      await tester.tap(find.byIcon(Icons.add_shopping_cart_rounded));
      await tester.pumpAndSettle();

      // Vérifie transformation en compteur [ - 1 + ]
      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);

      // 2. Appui sur '+' -> Incrémentation à 2
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);

      // 3. Appui sur '-' -> Décrémentation à 1
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      // 4. Appui sur '-' à 1 -> Retrait de l'article et retour à l'icône
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add_shopping_cart_rounded), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('Produit avec variantes : affiche bouton options et ouvre la bottom sheet',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createTestWidget(
          container: container,
          child: const QuickAddButton(product: productWithVariants),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      // Appui ouvre la bottom sheet
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Choisir une option'), findsOneWidget);
      expect(find.text('Chaussures Sport'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(find.text('41'), findsOneWidget);
    });
  });
}
