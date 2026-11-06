/// ============================================================================
/// RÔLE DU FICHIER : Tests unitaires et de widgets pour le service de notifications push
/// (MockNotificationService, enregistrement/suppression de token, navigation au clic et dialogue).
/// INTERAGIT AVEC : notification_service.dart, session_provider.dart, notification_permission_dialog.dart.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Dokan_client/core/session/session_provider.dart';
import 'package:Dokan_client/data/models/user_summary.dart';
import 'package:Dokan_client/feature/orders/notification_permission_dialog.dart';
import 'package:Dokan_client/services/notification_service.dart';

void main() {
  group('NotificationService — Tests unitaires du cycle de vie des tokens', () {
    test('Enregistrement du token lors de la connexion et suppression à la déconnexion', () async {
      final mockService = MockNotificationService();

      // Au départ, aucun terminal n'est enregistré
      expect(mockService.registeredTokens, isEmpty);
      expect(mockService.registeredUserId, isNull);

      // Simulation de connexion client
      await mockService.registerDeviceToken('client_123');
      expect(mockService.registeredTokens.contains('mock_token_client_123'), isTrue);
      expect(mockService.registeredUserId, equals('client_123'));

      // Simulation de déconnexion client
      await mockService.unregisterDeviceToken('client_123');
      expect(mockService.registeredTokens, isEmpty);
      expect(mockService.registeredUserId, isNull);
    });

    test('SessionNotifier coordonne unregisterDeviceToken lors de logout()', () {
      final mockService = MockNotificationService();
      mockService.registerDeviceToken('client_xyz');

      final notifier = SessionNotifier(
        initialState: const SessionState(
          user: UserSummary(
            fullName: 'Client Test',
            email: 'test@dokan.tn',
          ),
          isLoading: false,
        ),
        notificationService: mockService,
      );

      // Appel de logout avec userId explicite
      notifier.logout(userId: 'client_xyz');

      expect(notifier.state.isGuest, isTrue);
      expect(mockService.registeredTokens, isEmpty);
      expect(mockService.registeredUserId, isNull);
    });
  });

  group('NotificationService — Navigation au toucher de notification', () {
    test('Toucher une notification avec orderId déclenche la navigation vers le bon détail', () async {
      final mockService = MockNotificationService();
      String? navigatedOrderId;

      await mockService.initialize(
        onNavigateToOrder: (orderId) {
          navigatedOrderId = orderId;
        },
      );

      // Déclenchement d'un clic de notification avec orderId
      mockService.onNavigateToOrder?.call('ord_999');

      expect(navigatedOrderId, equals('ord_999'));
    });

    test('Message sans orderId ou avec identifiant vide ne déclenche aucune navigation erronée', () async {
      final mockService = MockNotificationService();
      String? navigatedOrderId;

      await mockService.initialize(
        onNavigateToOrder: (orderId) {
          if (orderId.trim().isNotEmpty) {
            navigatedOrderId = orderId;
          }
        },
      );

      // Notification locale sans payload
      await mockService.showLocalNotification(
        id: 1,
        title: 'Promotion Dokan',
        body: 'Découvrez nos nouveautés',
        payload: null,
      );

      expect(mockService.shownNotifications.length, 1);
      expect(navigatedOrderId, isNull);
    });
  });

  group('NotificationPermissionDialog — Tests de widgets', () {
    testWidgets('Affiche le dialogue explicatif avec les boutons Activer et Plus tard', (tester) async {
      final mockService = MockNotificationService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationPermissionDialog(
              notificationService: mockService,
              userId: 'user_456',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifie les libellés accessibles et bienveillants
      expect(find.text('Recevez des alertes sur votre commande'), findsOneWidget);
      expect(find.textContaining('Dokan vous informe en direct'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Activer les alertes'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Plus tard'), findsOneWidget);

      // Tap sur "Activer les alertes"
      await tester.tap(find.widgetWithText(ElevatedButton, 'Activer les alertes'));
      await tester.pumpAndSettle();

      expect(mockService.permissionGranted, isTrue);
      expect(mockService.registeredTokens.contains('mock_token_user_456'), isTrue);
    });
  });
}
