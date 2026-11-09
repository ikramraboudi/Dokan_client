import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dokan_client/data/models/order_status.dart';
import 'package:Dokan_client/data/models/order_model.dart';
import 'package:Dokan_client/data/models/cart_item_ui_model.dart';

void main() {
  group('Cycle de vie officiel des commandes (Client / Admin / Livreur)', () {
    test('1. Les 6 statuts officiels Firestore sont reconnus exactement', () {
      // 1. "en attente" ➡️ Le client vient de passer la commande.
      expect(OrderStatus.fromString('en attente'), OrderStatus.pending);
      expect(OrderStatus.fromString('en_attente'), OrderStatus.pending);
      expect(OrderStatus.pending.value, 'en attente');
      expect(OrderStatus.pending.progressStep, 0);
      expect(OrderStatus.pending.canBeCancelledByCustomer, isTrue);

      // 2. "en cours" ➡️ L'admin a accepté et confirmé la commande (livreur auto-assigné).
      expect(OrderStatus.fromString('en cours'), OrderStatus.confirmed);
      expect(OrderStatus.fromString('en_cours'), OrderStatus.confirmed);
      expect(OrderStatus.confirmed.value, 'en cours');
      expect(OrderStatus.confirmed.progressStep, 1);
      expect(OrderStatus.confirmed.canBeCancelledByCustomer, isFalse);

      // 3. "enleve" ➡️ Le livreur a scanné le QR Code du bon d'enlèvement au dépôt.
      expect(OrderStatus.fromString('enleve'), OrderStatus.outForDelivery);
      expect(OrderStatus.fromString('enlevé'), OrderStatus.outForDelivery);
      expect(OrderStatus.outForDelivery.value, 'enleve');
      expect(OrderStatus.outForDelivery.progressStep, 2);
      expect(OrderStatus.outForDelivery.canBeCancelledByCustomer, isFalse);

      // 4. "livre" ➡️ Le livreur a remis la commande au client en main propre.
      expect(OrderStatus.fromString('livre'), OrderStatus.delivered);
      expect(OrderStatus.fromString('livré'), OrderStatus.delivered);
      expect(OrderStatus.fromString('delivered'), OrderStatus.delivered);
      expect(OrderStatus.delivered.value, 'livre');
      expect(OrderStatus.delivered.progressStep, 3);
      expect(OrderStatus.delivered.canBeCancelledByCustomer, isFalse);

      // 5. "annule" ➡️ Commande annulée (par l'admin ou le client).
      expect(OrderStatus.fromString('annule'), OrderStatus.cancelled);
      expect(OrderStatus.fromString('annulé'), OrderStatus.cancelled);
      expect(OrderStatus.fromString('cancelled'), OrderStatus.cancelled);
      expect(OrderStatus.cancelled.value, 'annule');
      expect(OrderStatus.cancelled.progressStep, -1);
      expect(OrderStatus.cancelled.canBeCancelledByCustomer, isFalse);

      // 6. "echec" ➡️ Échec de livraison (client injoignable, adresse erronée, etc.).
      expect(OrderStatus.fromString('echec'), OrderStatus.failed);
      expect(OrderStatus.fromString('échec'), OrderStatus.failed);
      expect(OrderStatus.fromString('failed'), OrderStatus.failed);
      expect(OrderStatus.failed.value, 'echec');
      expect(OrderStatus.failed.progressStep, -1);
      expect(OrderStatus.failed.canBeCancelledByCustomer, isFalse);
    });

    test('2. OrderUiModel.fromMap gère les formats officiels (customerId, statut, etc.)', () {
      final docData = <String, dynamic>{
        'displayNumber': 'DK-20261109-1234',
        'customerId': 'user_abc123',
        'customerName': 'Amira Ben Salem',
        'customerPhone': '98765432',
        'statut': 'en cours',
        'total': 185.500,
        'deliveryAddress': '15 Avenue Habib Bourguiba, Tunis',
        'items': [
          {
            'productId': 'prod_456',
            'name': 'Cafetière expresso',
            'imageUrl': 'https://example.com/coffee.jpg',
            'unitPrice': 185.500,
            'quantity': 1,
            'lineTotal': 185.500,
            'poids': 2.5,
          }
        ],
      };

      final order = OrderUiModel.fromMap('order_001', docData);

      expect(order.id, 'order_001');
      expect(order.userId, 'user_abc123');
      expect(order.customerName, 'Amira Ben Salem');
      expect(order.customerPhone, '98765432');
      expect(order.status, OrderStatus.confirmed);
      expect(order.total, 185.500);
      expect(order.items.length, 1);
      expect(order.items.first.productId, 'prod_456');
    });

    test('3. CartItemUiModel.toMap sérialise correctement pour le checkout', () {
      const item = CartItemUiModel(
        id: 'cart_1',
        productId: 'prod_999',
        name: 'Casque Audio Bluetooth',
        imageUrl: 'https://example.com/headphones.jpg',
        unitPrice: 89.0,
        quantity: 2,
        variantLabel: 'Noir',
        poids: 0.3,
      );

      final map = item.toMap();

      expect(map['productId'], 'prod_999');
      expect(map['id'], 'prod_999');
      expect(map['name'], 'Casque Audio Bluetooth');
      expect(map['unitPrice'], 89.0);
      expect(map['price'], 89.0);
      expect(map['quantity'], 2);
      expect(map['variantLabel'], 'Noir');
      expect(map['lineTotal'], 178.0);
      expect(map['poids'], 0.3);
      expect(map['totalPoids'], 0.6);
    });

    test('4. StatusHistoryEntry enregistre status et statut pour interopérabilité', () {
      final now = Timestamp.now();
      final entry = StatusHistoryEntry(
        status: OrderStatus.outForDelivery,
        at: now,
      );

      final map = entry.toMap();
      expect(map['status'], 'enleve');
      expect(map['statut'], 'enleve');
      expect(map['at'], now);

      final fromMap = StatusHistoryEntry.fromMap({
        'statut': 'enleve',
        'at': now,
      });
      expect(fromMap.status, OrderStatus.outForDelivery);
    });
  });
}
