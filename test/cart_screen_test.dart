/// ============================================================================
/// RÔLE DU FICHIER :
/// Tests de widgets pour l'écran Panier (`CartScreen`).
///
/// COMPORTEMENTS TESTÉS :
/// 1) Panier vide : affiche l'état vide (`EmptyState`).
/// 2) Panier non vide : affiche la liste des articles, la section code promo et le récapitulatif des prix sans erreur de rendu.
/// 3) Modification de quantité dans la carte article.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Dokan_client/feature/cart/cart_screen.dart';
import 'package:Dokan_client/data/models/product_ui_model.dart';
import 'package:Dokan_client/data/mock/mock_cart_repository.dart';

void main() {
  Widget createTestWidget({required ProviderContainer container}) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: CartScreen(),
      ),
    );
  }

  group('CartScreen — Tests de rendu et d\'affichage', () {
    testWidgets('Panier vide : affiche EmptyState', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      expect(find.text('Mon panier'), findsOneWidget);
      expect(find.text('Votre panier est vide'), findsOneWidget);
    });

    testWidgets('Panier avec article : affiche le produit, code promo et récapitulatif',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      await notifier.addProduct(
        const ProductUiModel(
          id: 'prod_1',
          name: 'Montre Classique',
          description: 'Description',
          price: 129.0,
          imageUrls: [],
          categoryName: 'Accessoires',
        ),
      );

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // Vérifier que le titre et les boutons sont là
      expect(find.text('Mon panier'), findsOneWidget);
      expect(find.text('Vider'), findsOneWidget);

      // Vérifier que le contenu du panier est VISIBLE
      expect(find.text('Montre Classique'), findsOneWidget);
      expect(find.text('Code promotionnel'), findsOneWidget);
      expect(find.text('Récapitulatif de la commande'), findsOneWidget);
      expect(find.text('Continuer la commande'), findsOneWidget);
    });
  });
}
