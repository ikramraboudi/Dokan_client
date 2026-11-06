/// ============================================================================
/// RÔLE DU FICHIER :
/// Tests de synchronisation réactive entre le panier et la fiche produit (`ProductDetailScreen`).
///
/// COMPORTEMENTS TESTÉS :
/// 1) Si le produit a déjà été ajouté (ex: quantité = 3 depuis la carte produit),
///    la fiche produit affiche directement « 3 » dans son sélecteur de quantité.
/// 2) Modifier la quantité sur la fiche produit met à jour instantanément le panier.
/// 3) Le bouton d'action reflète l'état présent dans le panier.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Dokan_client/feature/product/product_detail_screen.dart';
import 'package:Dokan_client/data/models/product_ui_model.dart';
import 'package:Dokan_client/data/models/cart_item_ui_model.dart';
import 'package:Dokan_client/data/mock/mock_cart_repository.dart';

void main() {
  const testProduct = ProductUiModel(
    id: 'prod_pots',
    name: 'Set de Casseroles Antiadhésives',
    description: 'Set complet 5 pièces de cuisine',
    price: 129.0,
    imageUrls: ['https://example.com/pots.png'],
    categoryName: 'Maison',
    availability: ProductAvailability.inStock,
  );

  Widget createTestWidget({required ProviderContainer container}) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: ProductDetailScreen(productId: 'prod_pots'),
      ),
    );
  }

  group('ProductDetailScreen — Synchronisation réactive avec le panier', () {
    testWidgets('Produit déjà à 3 dans le panier : affiche 3 directement dans le détail',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const initialItem = CartItemUiModel(
        id: 'c_pots',
        productId: 'prod_pots',
        name: 'Set de Casseroles Antiadhésives',
        imageUrl: 'https://example.com/pots.png',
        unitPrice: 129.0,
        quantity: 3,
        poids: 0.0,
      );

      final container = ProviderContainer(
        overrides: [
          productDetailProvider('prod_pots')
              .overrideWith((ref) => Future.value(testProduct)),
          cartProvider.overrideWith(
            (ref) => CartNotifier(
              ref,
              MockCartRepository(),
              const CartState(items: [initialItem]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // Vérifier que le sélecteur de quantité affiche 3
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Quantité'), findsOneWidget);
      expect(find.text('Ajouter encore au panier'), findsOneWidget);

      // Appuyer sur '+' dans la fiche détail pour passer à 4
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      // Vérifier que la quantité affichée et le panier sont synchronisés à 4
      expect(find.text('4'), findsOneWidget);
      expect(
        container.read(cartProvider).items.firstWhere((i) => i.productId == 'prod_pots').quantity,
        equals(4),
      );
    });
  });
}
