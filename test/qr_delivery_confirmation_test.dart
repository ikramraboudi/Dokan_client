import 'package:flutter_test/flutter_test.dart';
import 'package:Dokan_client/data/models/qr_confirmation_payload.dart';
import 'package:Dokan_client/data/models/order_model.dart';
import 'package:Dokan_client/data/models/order_status.dart';

void main() {
  group('Système de sécurisation des livraisons (QR Code & PIN)', () {
    test('1. Parsing strict du QR code généré par l\'application Livreur', () {
      const rawQr = 'DOKAN-CONFIRM:cmd-12345:DOKAN-102:45.5';
      final payload = QrConfirmationPayload.parse(rawQr);

      expect(payload, isNotNull);
      expect(payload!.orderId, 'cmd-12345');
      expect(payload.displayNumber, 'DOKAN-102');
      expect(payload.total, 45.5);
    });

    test('2. Rejet des QR codes au format invalide ou corrompu', () {
      expect(QrConfirmationPayload.parse(null), isNull);
      expect(QrConfirmationPayload.parse(''), isNull);
      expect(QrConfirmationPayload.parse('RANDOM_QR_CODE_123'), isNull);
      expect(QrConfirmationPayload.parse('DOKAN-CONFIRM:only_two_parts'), isNull);
      expect(QrConfirmationPayload.parse('OTHER-PREFIX:cmd-1:DK-1:10.0'), isNull);
    });

    test('3. Calcul déterministe du code PIN de secours à 6 chiffres', () {
      const orderId = 'cmd-12345';
      final pin1 = QrConfirmationPayload.calculatePin(orderId);
      final pin2 = QrConfirmationPayload.calculatePin(orderId);

      // Le code doit être déterministe et faire exactement 6 chiffres
      expect(pin1, pin2);
      expect(pin1.length, 6);
      expect(int.tryParse(pin1), isNotNull);
      expect(int.parse(pin1), greaterThanOrEqualTo(100000));
      expect(int.parse(pin1), lessThanOrEqualTo(999999));

      // Test de vérification PIN
      expect(
        QrConfirmationPayload.verifyPin(orderId: orderId, inputPin: pin1),
        isTrue,
      );
      expect(
        QrConfirmationPayload.verifyPin(orderId: orderId, inputPin: '000000'),
        isFalse,
      );
      expect(
        QrConfirmationPayload.verifyPin(orderId: orderId, inputPin: '123'),
        isFalse,
      );
    });

    test('4. OrderUiModel détecte correctement les commandes en cours de livraison', () {
      final orderDelivering = OrderUiModel.fromMap('order_1', {
        'displayNumber': 'DK-101',
        'status': 'enleve',
        'total': 50.0,
      });

      expect(orderDelivering.status, OrderStatus.outForDelivery);
      expect(orderDelivering.canBeConfirmedByClient, isTrue);
      expect(orderDelivering.isConfirmedByClient, isFalse);

      final orderConfirmedWithDriver = OrderUiModel.fromMap('order_2', {
        'displayNumber': 'DK-102',
        'status': 'en cours',
        'total': 75.0,
        'driver': {
          'id': 'drv_1',
          'name': 'Ali Ben Salah',
        },
      });

      expect(orderConfirmedWithDriver.canBeConfirmedByClient, isTrue);

      final orderAlreadyDelivered = OrderUiModel.fromMap('order_3', {
        'displayNumber': 'DK-103',
        'status': 'livre',
        'total': 75.0,
        'deliveryConfirmedBy': 'client_qr_scan',
      });

      expect(orderAlreadyDelivered.canBeConfirmedByClient, isFalse);
      expect(orderAlreadyDelivered.isConfirmedByClient, isTrue);
      expect(orderAlreadyDelivered.deliveryConfirmedBy, 'client_qr_scan');
    });
  });
}
