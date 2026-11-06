import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Dokan_client/core/ui/price_summary.dart';
import 'package:Dokan_client/data/mock/mock_cart_repository.dart';
import 'package:Dokan_client/data/models/cart_item_ui_model.dart';
import 'package:Dokan_client/data/models/order_model.dart';
import 'package:Dokan_client/data/models/order_status.dart';
import 'package:Dokan_client/data/models/product_ui_model.dart';
import 'package:Dokan_client/feature/cart/cart_screen.dart';

void main() {
  group('1. ProductUiModel & CartItemUiModel — Champs de poids (poids & linePoids)', () {
    test('ProductUiModel supporte poids par défaut 0.0 et sérialisation Firestore', () {
      const prodDefault = ProductUiModel(
        id: 'p1',
        name: 'T-shirt Dokan',
        description: 'Coton bio',
        imageUrls: [],
        price: 29.0,
        categoryName: 'Mode',
      );
      expect(prodDefault.poids, 0.0);
      expect(prodDefault.toFirestore()['poids'], 0.0);

      const prodWeighted = ProductUiModel(
        id: 'p2',
        name: 'Machine à laver',
        description: 'Capacité 8kg',
        imageUrls: [],
        price: 850.0,
        categoryName: 'Électroménager',
        poids: 65.5,
      );
      expect(prodWeighted.poids, 65.5);
      expect(prodWeighted.toFirestore()['poids'], 65.5);

      final copy = prodDefault.copyWith(poids: 1.2);
      expect(copy.poids, 1.2);
    });

    test('CartItemUiModel calcule linePoids = poids * quantity', () {
      const item = CartItemUiModel(
        id: 'c1',
        productId: 'prod_1',
        name: 'Sac de ciment',
        imageUrl: '',
        unitPrice: 15.0,
        quantity: 3,
        poids: 25.0,
      );

      expect(item.poids, 25.0);
      expect(item.quantity, 3);
      expect(item.linePoids, 75.0); // 25.0 * 3
      expect(item.lineTotal, 45.0);

      final updated = item.copyWith(quantity: 1);
      expect(updated.linePoids, 25.0);
    });
  });

  group('2. CartState — Logique métier et seuils de dispatching des véhicules', () {
    test('Panier vide : poids nul et véhicule standard voiture', () {
      const emptyState = CartState(items: []);
      expect(emptyState.totalPoids, 0.0);
      expect(emptyState.maxItemPoids, 0.0);
      expect(emptyState.requiresTruck, isFalse);
      expect(emptyState.requiredVehicleType, 'voiture');
    });

    test('Règle 1 : Camion requis si le poids total dépasse 50.0 kg (totalPoids > 50.0)', () {
      const state = CartState(
        items: [
          CartItemUiModel(
            id: 'item_1',
            productId: 'p1',
            name: 'Pack d\'eau minérale (6x1.5L)',
            imageUrl: '',
            unitPrice: 4.5,
            quantity: 6,
            poids: 9.0, // 6 * 9.0 = 54.0 kg (> 50 kg)
          ),
        ],
      );

      expect(state.totalPoids, 54.0);
      expect(state.maxItemPoids, 9.0); // Chaque article fait 9 kg <= 30 kg
      expect(state.requiresTruck, isTrue);
      expect(state.requiredVehicleType, 'camion');
    });

    test('Règle 2 : Camion requis si un article unitaire dépasse 30.0 kg (maxItemPoids > 30.0)', () {
      const state = CartState(
        items: [
          CartItemUiModel(
            id: 'item_heavy',
            productId: 'p_refrig',
            name: 'Mini Réfrigérateur',
            imageUrl: '',
            unitPrice: 450.0,
            quantity: 1,
            poids: 35.0, // 35 kg > 30 kg, même si total = 35 kg <= 50 kg
          ),
          CartItemUiModel(
            id: 'item_light',
            productId: 'p_cable',
            name: 'Câble HDMI',
            imageUrl: '',
            unitPrice: 15.0,
            quantity: 1,
            poids: 0.2,
          ),
        ],
      );

      expect(state.totalPoids, 35.2);
      expect(state.maxItemPoids, 35.0);
      expect(state.requiresTruck, isTrue);
      expect(state.requiredVehicleType, 'camion');
    });

    test('Règle 3 : Voiture standard si total <= 50.0 kg ET aucun article > 30.0 kg', () {
      const state = CartState(
        items: [
          CartItemUiModel(
            id: 'i1',
            productId: 'p1',
            name: 'Micro-ondes',
            imageUrl: '',
            unitPrice: 220.0,
            quantity: 1,
            poids: 14.5,
          ),
          CartItemUiModel(
            id: 'i2',
            productId: 'p2',
            name: 'Grille-pain',
            imageUrl: '',
            unitPrice: 45.0,
            quantity: 2,
            poids: 1.5,
          ),
        ],
      );

      expect(state.totalPoids, 17.5);
      expect(state.maxItemPoids, 14.5);
      expect(state.requiresTruck, isFalse);
      expect(state.requiredVehicleType, 'voiture');
    });

    test('Cas limites stricts (50.0 kg exact et 30.0 kg exact restent en voiture)', () {
      // 50.0 kg exact
      const boundary50 = CartState(
        items: [
          CartItemUiModel(
            id: 'b1',
            productId: 'p1',
            name: 'Colis 25kg',
            imageUrl: '',
            unitPrice: 100.0,
            quantity: 2,
            poids: 25.0, // Total = 50.0 kg exact, maxItem = 25.0 kg
          ),
        ],
      );
      expect(boundary50.totalPoids, 50.0);
      expect(boundary50.maxItemPoids, 25.0);
      expect(boundary50.requiresTruck, isFalse);
      expect(boundary50.requiredVehicleType, 'voiture');

      // 30.0 kg unitaire exact avec total <= 50 kg
      const boundary30 = CartState(
        items: [
          CartItemUiModel(
            id: 'b2',
            productId: 'p2',
            name: 'Colis 30kg',
            imageUrl: '',
            unitPrice: 120.0,
            quantity: 1,
            poids: 30.0, // maxItem = 30.0 kg exact
          ),
        ],
      );
      expect(boundary30.totalPoids, 30.0);
      expect(boundary30.maxItemPoids, 30.0);
      expect(boundary30.requiresTruck, isFalse);
      expect(boundary30.requiredVehicleType, 'voiture');
    });
  });

  group('3. CartNotifier — Intégration du poids lors de addProduct', () {
    test('addProduct propage le poids du produit dans le CartItem', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);
      const heavyProduct = ProductUiModel(
        id: 'prod_kettlebell',
        name: 'Kettlebell 16kg',
        description: 'Fonte noire',
        imageUrls: [],
        price: 89.0,
        categoryName: 'Sport',
        poids: 16.0,
      );

      await notifier.addProduct(heavyProduct, quantity: 2);

      final state = container.read(cartProvider);
      expect(state.items.length, 1);
      expect(state.items.first.poids, 16.0);
      expect(state.items.first.linePoids, 32.0);
      expect(state.totalPoids, 32.0);
      expect(notifier.totalPoids, 32.0);
      expect(notifier.requiresTruck, isFalse);
      expect(notifier.requiredVehicleType, 'voiture');

      // Ajout d'une 3e unité -> 3 * 16 = 48 kg (toujours voiture)
      await notifier.addProduct(heavyProduct, quantity: 1);
      expect(container.read(cartProvider).totalPoids, 48.0);
      expect(container.read(cartProvider).requiresTruck, isFalse);

      // Ajout d'une 4e unité -> 4 * 16 = 64 kg (> 50 kg -> camion !)
      await notifier.addProduct(heavyProduct, quantity: 1);
      expect(container.read(cartProvider).totalPoids, 64.0);
      expect(container.read(cartProvider).requiresTruck, isTrue);
      expect(container.read(cartProvider).requiredVehicleType, 'camion');
    });
  });

  group('4. PriceSummary UI — Affichage de la ligne Poids total', () {
    testWidgets('PriceSummary affiche la ligne Poids total formatée avec 1 décimale', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PriceSummary(
              subtotal: 120.0,
              deliveryFee: 7.0,
              total: 127.0,
              totalPoids: 23.456,
            ),
          ),
        ),
      );

      expect(find.text('Poids total'), findsOneWidget);
      expect(find.text('23.5 kg'), findsOneWidget);
    });

    testWidgets('PriceSummary sans totalPoids ne plante pas et n\'affiche pas la ligne', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PriceSummary(
              subtotal: 120.0,
              deliveryFee: 7.0,
              total: 127.0,
            ),
          ),
        ),
      );

      expect(find.text('Poids total'), findsNothing);
    });
  });

  group('5. CartScreen UI — Bannières de véhicule et badges de poids', () {
    testWidgets('Affiche la bannière Camion requis (Icons.local_shipping) quand requiresTruck == true', (tester) async {
      const heavyItem = CartItemUiModel(
        id: 'prod_armoire',
        productId: 'prod_armoire',
        name: 'Armoire dressing',
        imageUrl: '',
        unitPrice: 950.0,
        quantity: 1,
        poids: 55.0, // > 50 kg -> Camion requis
      );

      final container = ProviderContainer(
        overrides: [
          cartProvider.overrideWith(
            (ref) => CartNotifier(
              ref,
              MockCartRepository(),
              const CartState(items: [heavyItem]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CartScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.local_shipping), findsOneWidget);
      expect(
        find.textContaining('Camion requis : Poids lourd'),
        findsOneWidget,
      );
      expect(find.text('55.0 kg'), findsWidgets);
    });

    testWidgets('Affiche la bannière Livraison standard en voiture quand requiresTruck == false', (tester) async {
      const lightItem = CartItemUiModel(
        id: 'prod_livre',
        productId: 'prod_livre',
        name: 'Livre Dokan',
        imageUrl: '',
        unitPrice: 25.0,
        quantity: 2,
        poids: 0.8, // 2 * 0.8 = 1.6 kg <= 50 kg -> Voiture
      );

      final container = ProviderContainer(
        overrides: [
          cartProvider.overrideWith(
            (ref) => CartNotifier(
              ref,
              MockCartRepository(),
              const CartState(items: [lightItem]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CartScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.directions_car), findsOneWidget);
      expect(find.text('Livraison standard en voiture.'), findsOneWidget);
      // Badge indiquant quantité x poids unitaire = total ligne
      expect(find.text('2 × 0.8 kg = 1.6 kg'), findsOneWidget);
    });
  });

  group('6. OrderModel — Sérialisation & payload de dispatching', () {
    test('OrderItemUiModel sérialise et désérialise poids et totalPoids', () {
      const orderItem = OrderItemUiModel(
        productId: 'item_123',
        name: 'Batterie de cuisine',
        imageUrl: 'https://example.com/item.png',
        unitPrice: 150.0,
        quantity: 2,
        lineTotal: 300.0,
        poids: 6.5,
      );

      expect(orderItem.linePoids, 13.0);
      expect(orderItem.totalPoids, 13.0);

      final map = orderItem.toMap();
      expect(map['poids'], 6.5);
      expect(map['totalPoids'], 13.0);
      expect(map['price'], 150.0);
      expect(map['unitPrice'], 150.0);

      final restored = OrderItemUiModel.fromMap(map);
      expect(restored.poids, 6.5);
      expect(restored.linePoids, 13.0);
    });

    test('OrderUiModel sérialise les champs obligatoires du dispatching (totalPoids, requiresTruck, requiredVehicleType)', () {
      const address = OrderDeliveryAddress(
        recipientName: 'Mourad',
        phone: '98123456',
        addressLine: 'Avenue Bourguiba',
        city: 'Tunis',
      );

      final order = OrderUiModel(
        id: 'ord_dispatch_1',
        displayNumber: 'DK-261106-9999',
        userId: 'user_xyz',
        customerName: 'Mourad',
        customerPhone: '98123456',
        status: OrderStatus.pending,
        statusHistory: const [],
        items: const [
          OrderItemUiModel(
            productId: 'p_heavy',
            name: 'Gros meuble',
            imageUrl: '',
            unitPrice: 500.0,
            quantity: 1,
            lineTotal: 500.0,
            poids: 55.0,
          ),
        ],
        itemCount: 1,
        subtotal: 500.0,
        discount: 0.0,
        deliveryFee: 7.0,
        total: 507.0,
        deliveryAddress: address,
        totalPoids: 55.0,
        requiresTruck: true,
        requiredVehicleType: 'camion',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      final payload = order.toFirestore();

      expect(payload['totalPrice'], 507.0);
      expect(payload['totalPoids'], 55.0);
      expect(payload['requiresTruck'], isTrue);
      expect(payload['requiredVehicleType'], 'camion');
    });
  });
}
