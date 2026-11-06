import 'package:flutter_test/flutter_test.dart';
import 'package:Dokan_client/feature/orders/order_notification_resolver.dart';

void main() {
  group('OrderNotificationResolver Tests', () {
    const orderId = 'order_abc123';
    const displayNumber = 'DK-261105-9XYZ';

    test('1. Première synchronisation (isFirstSync = true) ne notifie jamais', () {
      final payload = OrderNotificationResolver.notificationFor(
        oldState: null,
        orderId: orderId,
        displayNumber: displayNumber,
        rawStatus: 'confirmed',
        hasDriverArrived: false,
        isFirstSync: true,
      );

      expect(payload, isNull);
    });

    test('2. Changement de statut vers "confirmed" émet le bon message', () {
      final payload = OrderNotificationResolver.notificationFor(
        oldState: const OrderNotificationState(status: 'pending'),
        orderId: orderId,
        displayNumber: displayNumber,
        rawStatus: 'confirmed',
        hasDriverArrived: false,
        isFirstSync: false,
      );

      expect(payload, isNotNull);
      expect(payload!.title, 'Commande acceptée ✅');
      expect(payload.body, 'Dokan a accepté votre commande DK-261105-9XYZ.');
      expect(payload.orderId, orderId);
      expect(payload.notificationId, OrderNotificationResolver.stableNotificationId(orderId));
    });

    test('3. Même statut n\'émet aucune notification (anti-spam)', () {
      final payload = OrderNotificationResolver.notificationFor(
        oldState: const OrderNotificationState(status: 'confirmed'),
        orderId: orderId,
        displayNumber: displayNumber,
        rawStatus: 'confirmed',
        hasDriverArrived: false,
        isFirstSync: false,
      );

      expect(payload, isNull);
    });

    test('4. Transitions successives (preparing, out_for_delivery, delivered)', () {
      // preparing
      final prep = OrderNotificationResolver.notificationFor(
        oldState: const OrderNotificationState(status: 'confirmed'),
        orderId: orderId,
        displayNumber: displayNumber,
        rawStatus: 'preparing',
        hasDriverArrived: false,
        isFirstSync: false,
      );
      expect(prep?.title, 'En préparation 👩‍🍳');
      expect(prep?.body, 'Votre commande DK-261105-9XYZ est en cours de préparation.');

      // out_for_delivery
      final out = OrderNotificationResolver.notificationFor(
        oldState: const OrderNotificationState(status: 'preparing'),
        orderId: orderId,
        displayNumber: displayNumber,
        rawStatus: 'in_progress', // normalisation in_progress -> out_for_delivery
        hasDriverArrived: false,
        isFirstSync: false,
      );
      expect(out?.title, 'En route 🚚');
      expect(out?.body, 'Le livreur est en chemin avec votre commande DK-261105-9XYZ.');

      // delivered
      final deliv = OrderNotificationResolver.notificationFor(
        oldState: const OrderNotificationState(status: 'out_for_delivery', driverArrivedNotified: true),
        orderId: orderId,
        displayNumber: displayNumber,
        rawStatus: 'delivered',
        hasDriverArrived: true,
        isFirstSync: false,
      );
      expect(deliv?.title, 'Commande livrée 🎉');
      expect(deliv?.body, 'Merci d\'avoir choisi Dokan !');
    });

    test('5. Arrivée du livreur (driverArrivedAt) notifie une seule fois', () {
      // Premier passage : arrivée détectée
      final arrived1 = OrderNotificationResolver.notificationFor(
        oldState: const OrderNotificationState(status: 'out_for_delivery', driverArrivedNotified: false),
        orderId: orderId,
        displayNumber: displayNumber,
        rawStatus: 'out_for_delivery',
        hasDriverArrived: true,
        isFirstSync: false,
      );
      expect(arrived1, isNotNull);
      expect(arrived1!.title, 'Le livreur est arrivé 📍');
      expect(arrived1.body, 'Il est devant chez vous. Préparez le paiement en espèces.');

      // Mise à jour de l'état
      final nextState = OrderNotificationResolver.nextState(
        oldState: const OrderNotificationState(status: 'out_for_delivery', driverArrivedNotified: false),
        rawStatus: 'out_for_delivery',
        hasDriverArrived: true,
      );
      expect(nextState.driverArrivedNotified, isTrue);

      // Deuxième passage : déjà notifié -> pas de doublon
      final arrived2 = OrderNotificationResolver.notificationFor(
        oldState: nextState,
        orderId: orderId,
        displayNumber: displayNumber,
        rawStatus: 'out_for_delivery',
        hasDriverArrived: true,
        isFirstSync: false,
      );
      expect(arrived2, isNull);
    });

    test('6. Annulation par le client ne déclenche pas de notification', () {
      // Cas A : paramètre cancelledBy = 'client'
      final clientCancel1 = OrderNotificationResolver.notificationFor(
        oldState: const OrderNotificationState(status: 'pending'),
        orderId: orderId,
        displayNumber: displayNumber,
        rawStatus: 'cancelled',
        hasDriverArrived: false,
        isFirstSync: false,
        cancelledBy: 'client',
      );
      expect(clientCancel1, isNull);

      // Cas B : état local mémorisé cancelledByClient = true
      final clientCancel2 = OrderNotificationResolver.notificationFor(
        oldState: const OrderNotificationState(status: 'pending', cancelledByClient: true),
        orderId: orderId,
        displayNumber: displayNumber,
        rawStatus: 'cancelled',
        hasDriverArrived: false,
        isFirstSync: false,
      );
      expect(clientCancel2, isNull);
    });

    test('7. Annulation par l\'administrateur déclenche une alerte', () {
      final adminCancel = OrderNotificationResolver.notificationFor(
        oldState: const OrderNotificationState(status: 'confirmed'),
        orderId: orderId,
        displayNumber: displayNumber,
        rawStatus: 'cancelled',
        hasDriverArrived: false,
        isFirstSync: false,
        cancelledBy: 'admin',
      );
      expect(adminCancel, isNotNull);
      expect(adminCancel!.title, 'Commande annulée ❌');
      expect(adminCancel.body, 'Votre commande DK-261105-9XYZ a été annulée.');
    });

    test('8. Écran de détail ouvert (isDetailScreenOpen = true) supprime la notification', () {
      final payload = OrderNotificationResolver.notificationFor(
        oldState: const OrderNotificationState(status: 'confirmed'),
        orderId: orderId,
        displayNumber: displayNumber,
        rawStatus: 'preparing',
        hasDriverArrived: false,
        isFirstSync: false,
        isDetailScreenOpen: true,
      );
      expect(payload, isNull);
    });

    test('9. Statut initial "pending" n\'émet aucune notification', () {
      final payload = OrderNotificationResolver.notificationFor(
        oldState: null,
        orderId: orderId,
        displayNumber: displayNumber,
        rawStatus: 'pending',
        hasDriverArrived: false,
        isFirstSync: false,
      );
      expect(payload, isNull);
    });

    test('10. Identifiant de notification stable (hashCode positif)', () {
      final id1 = OrderNotificationResolver.stableNotificationId('order_123');
      final id2 = OrderNotificationResolver.stableNotificationId('order_123');
      final id3 = OrderNotificationResolver.stableNotificationId('order_456');

      expect(id1, equals(id2));
      expect(id1 >= 0, isTrue);
      expect(id1, isNot(equals(id3)));
    });

    test('11. Tolérance aux variantes françaises (acceptee, acceptée, confirmee, confirmée)', () {
      final payloadAcceptee = OrderNotificationResolver.notificationFor(
        oldState: const OrderNotificationState(status: 'pending'),
        orderId: orderId,
        displayNumber: displayNumber,
        rawStatus: 'acceptée',
        hasDriverArrived: false,
        isFirstSync: false,
      );
      expect(payloadAcceptee, isNotNull);
      expect(payloadAcceptee!.title, 'Commande acceptée ✅');

      final payloadConfirmee = OrderNotificationResolver.notificationFor(
        oldState: const OrderNotificationState(status: 'pending'),
        orderId: orderId,
        displayNumber: displayNumber,
        rawStatus: 'confirmée',
        hasDriverArrived: false,
        isFirstSync: false,
      );
      expect(payloadConfirmee, isNotNull);
      expect(payloadConfirmee!.title, 'Commande acceptée ✅');
    });
  });
}
