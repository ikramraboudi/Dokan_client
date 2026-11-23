/// ============================================================================
/// RÔLE DU FICHIER :
/// Tests de widgets pour les 3 animations clés :
/// A) Écran de démarrage (SplashScreen)
/// B) Ajout au panier, vol et barre flottante (QuickAddButton, FloatingCartBar)
/// C) Validation glissée et écran de confirmation (SlideToConfirmButton, OrderConfirmationScreen)
/// ============================================================================
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Dokan_client/core/ui/widgets/floating_cart_bar.dart';
import 'package:Dokan_client/feature/checkout/widgets/slide_to_confirm_button.dart';
import 'package:Dokan_client/feature/checkout/order_confirmation_screen.dart';
import 'package:Dokan_client/data/models/cart_item_ui_model.dart';
import 'package:Dokan_client/data/models/order_model.dart';
import 'package:Dokan_client/data/models/order_status.dart';
import 'package:Dokan_client/data/mock/mock_cart_repository.dart';
import 'package:Dokan_client/data/repositories/firestore_orders_repository.dart';

void main() {
  group('B. FloatingCartBar — Affichage et réactivité', () {
    testWidgets('Panier vide : FloatingCartBar est masquée (opacité 0)', (tester) async {
      final container = ProviderContainer(
        overrides: [
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

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: FloatingCartBar(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final opacityWidget = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacityWidget.opacity, equals(0.0));
    });

    testWidgets('Panier non vide : FloatingCartBar s\'affiche avec total et articles',
        (tester) async {
      const item = CartItemUiModel(
        id: 'c1',
        productId: 'p1',
        name: 'Casque Audio',
        imageUrl: '',
        unitPrice: 50.0,
        quantity: 2,
        poids: 0.5,
      );

      final container = ProviderContainer(
        overrides: [
          cartProvider.overrideWith(
            (ref) => CartNotifier(
              ref,
              MockCartRepository(),
              const CartState(items: [item]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      bool tapped = false;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: FloatingCartBar(
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 articles'), findsOneWidget);
      expect(find.text('Voir le panier'), findsOneWidget);

      await tester.tap(find.text('Voir le panier'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('C. SlideToConfirmButton — Glissement partiel et validation', () {
    testWidgets('Glissement partiel (< 85 %) : ne confirme pas et rebondit',
        (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: SlideToConfirmButton(
                  total: 51.80,
                  isLoading: false,
                  enabled: true,
                  onConfirm: () => confirmed = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Glisser de 60 px vers la droite (inférieur à 85% de 300 - 60 = 240 px)
      final arrowFinder = find.byIcon(Icons.arrow_forward_rounded);
      expect(arrowFinder, findsOneWidget);

      await tester.drag(arrowFinder, const Offset(60, 0));
      await tester.pumpAndSettle();

      expect(confirmed, isFalse);
    });

    testWidgets('Glissement complet (>= 85 %) : déclenche la confirmation',
        (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: SlideToConfirmButton(
                  total: 51.80,
                  isLoading: false,
                  enabled: true,
                  onConfirm: () => confirmed = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final arrowFinder = find.byIcon(Icons.arrow_forward_rounded);
      // Glisser de 260 px vers la droite
      await tester.drag(arrowFinder, const Offset(260, 0));
      await tester.pump();

      expect(confirmed, isTrue);
    });

    testWidgets('Double-tap de secours : confirme également', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: SlideToConfirmButton(
                  total: 51.80,
                  isLoading: false,
                  enabled: true,
                  onConfirm: () => confirmed = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Double-toucher
      await tester.tap(find.byType(SlideToConfirmButton));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(SlideToConfirmButton));
      await tester.pump();

      expect(confirmed, isTrue);
    });
  });

  group('C. OrderConfirmationScreen — Affichage et carte de résumé', () {
    testWidgets('Affiche le numéro DK-AAMMJJ-XXXX et la carte de résumé', (tester) async {
      final now = Timestamp.now();
      final dummyOrder = OrderUiModel(
        id: 'ord_123',
        displayNumber: 'DK-261122-0042',
        userId: 'usr_test',
        customerName: 'Kamel Test',
        customerPhone: '+216 98 000 000',
        status: OrderStatus.pending,
        statusHistory: const [],
        items: const [],
        itemCount: 0,
        subtotal: 44.80,
        discount: 0.0,
        deliveryFee: 7.0,
        total: 51.80,
        deliveryAddress: const OrderDeliveryAddress(
          recipientName: 'Kamel Test',
          phone: '+216 98 000 000',
          addressLine: 'Avenue Habib Bourguiba',
          city: 'Tunis',
          zone: 'Centre-ville',
        ),
        createdAt: now,
        updatedAt: now,
      );

      final container = ProviderContainer(
        overrides: [
          singleOrderStreamProvider('ord_123')
              .overrideWith((ref) => Stream.value(dummyOrder)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OrderConfirmationScreen(orderId: 'ord_123'),
          ),
        ),
      );
      // Laisser passer l'animation d'entrée
      await tester.pumpAndSettle(const Duration(milliseconds: 1600));

      expect(find.text('Commande confirmée !'), findsOneWidget);
      expect(find.text('DK-261122-0042'), findsOneWidget);
      expect(find.text('Suivre ma commande'), findsOneWidget);
      expect(find.text('Continuer mes achats'), findsOneWidget);
    });
  });
}
