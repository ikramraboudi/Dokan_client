/// ============================================================================
/// RÔLE DU FICHIER : Suite de tests unitaires et widgets pour la fonctionnalité des avis clients post-livraison.
///
/// CAS TESTÉS :
/// 1. Pas d'avis possible hors statut `delivered`.
/// 2. Le bouton « Envoyer » est désactivé tant que le curseur n'est pas touché.
/// 3. Un second envoi pour le même article met à jour au lieu de créer un doublon.
/// 4. Calcul de moyenne et de répartition dans le Mock.
/// 5. Commentaire de plus de 500 caractères refusé.
/// 6. Un visiteur voit les avis sans bouton d'écriture.
/// ============================================================================
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:Dokan_client/data/models/order_model.dart';
import 'package:Dokan_client/data/models/order_status.dart';
import 'package:Dokan_client/data/models/product_ui_model.dart';
import 'package:Dokan_client/data/models/review_model.dart';
import 'package:Dokan_client/data/repositories/firestore_orders_repository.dart';
import 'package:Dokan_client/data/repositories/review_repository.dart';
import 'package:Dokan_client/feature/orders/order_detail_screen.dart';
import 'package:Dokan_client/feature/orders/review_screen.dart';
import 'package:Dokan_client/feature/product/widgets/product_reviews_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Avis Clients — Tests Unitaires du Repository & Modèle', () {
    test('4. Calcul de moyenne et de répartition dans MockReviewRepository', () async {
      final repo = MockReviewRepository();

      // Soumission de plusieurs avis pour un produit de test
      await repo.submitReview(const ReviewUiModel(
        id: 'cmd_1_prod_test',
        productId: 'prod_test',
        orderId: 'cmd_1',
        userId: 'u1',
        authorName: 'Karim M.',
        rating: 5,
        comment: 'Top qualité',
      ));

      await repo.submitReview(const ReviewUiModel(
        id: 'cmd_2_prod_test',
        productId: 'prod_test',
        orderId: 'cmd_2',
        userId: 'u2',
        authorName: 'Sonia B.',
        rating: 5,
        comment: 'Très bien',
      ));

      await repo.submitReview(const ReviewUiModel(
        id: 'cmd_3_prod_test',
        productId: 'prod_test',
        orderId: 'cmd_3',
        userId: 'u3',
        authorName: 'Ali T.',
        rating: 2,
        comment: 'Moyen',
      ));

      final summary = await repo.getSummary('prod_test');

      expect(summary.totalReviews, equals(3));
      // Moyenne : (5 + 5 + 2) / 3 = 4.0
      expect(summary.averageRating, closeTo(4.0, 0.01));
      expect(summary.distribution[5], equals(2));
      expect(summary.distribution[2], equals(1));
      expect(summary.distribution[4], equals(0));
      expect(summary.ratioFor(5), closeTo(2 / 3, 0.01));
    });

    test('3. Un second envoi pour le même article met à jour au lieu de créer un doublon', () async {
      final repo = MockReviewRepository();

      final firstReview = const ReviewUiModel(
        id: 'cmd_10_prod_dedup',
        productId: 'prod_dedup',
        orderId: 'cmd_10',
        userId: 'u1',
        authorName: 'Karim M.',
        rating: 3,
        comment: 'Initialement moyen',
      );
      await repo.submitReview(firstReview);

      var reviews = await repo.getReviews('prod_dedup');
      expect(reviews.length, equals(1));
      expect(reviews.first.rating, equals(3));
      expect(reviews.first.comment, equals('Initialement moyen'));

      // Deuxième soumission avec le même ID déterministe mais note et commentaire mis à jour
      final updatedReview = const ReviewUiModel(
        id: 'cmd_10_prod_dedup',
        productId: 'prod_dedup',
        orderId: 'cmd_10',
        userId: 'u1',
        authorName: 'Karim M.',
        rating: 5,
        comment: 'Après échange, c\'est parfait !',
      );
      await repo.submitReview(updatedReview);

      reviews = await repo.getReviews('prod_dedup');
      expect(reviews.length, equals(1), reason: 'Aucun doublon ne doit être créé');
      expect(reviews.first.rating, equals(5));
      expect(reviews.first.comment, equals('Après échange, c\'est parfait !'));
    });

    test('5. Commentaire de plus de 500 caractères refusé', () async {
      final repo = MockReviewRepository();
      final longComment = 'a' * 501;

      final reviewTooLong = ReviewUiModel(
        id: 'cmd_x_prod_x',
        productId: 'prod_x',
        orderId: 'cmd_x',
        userId: 'u1',
        authorName: 'Test U.',
        rating: 4,
        comment: longComment,
      );

      expect(
        () async => await repo.submitReview(reviewTooLong),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Anonymisation du nom : Prénom + initiale uniquement', () {
      expect(ReviewUiModel.sanitizeAuthorName('Karim Mansour'), equals('Karim M.'));
      expect(ReviewUiModel.sanitizeAuthorName('sonia ben ali'), equals('Sonia B.'));
      expect(ReviewUiModel.sanitizeAuthorName('Yassine'), equals('Yassine'));
      expect(ReviewUiModel.sanitizeAuthorName('karim.mansour@gmail.com'), equals('Karim M.'));
      expect(ReviewUiModel.sanitizeAuthorName(''), equals('Client Dokan'));
      expect(ReviewUiModel.sanitizeAuthorName(null), equals('Client Dokan'));
    });
  });

  group('Avis Clients — Tests Widgets & Ergonomie', () {
    testWidgets('2. Le bouton Envoyer est désactivé tant que le curseur n\'est pas touché', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          reviewRepositoryProvider.overrideWithValue(MockReviewRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ReviewScreen(
              orderId: 'cmd_test_new',
              productId: 'prod_test_new',
              productName: 'Produit Inédit',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifier le bouton Envoyer initial
      final sendButtonFinder = find.widgetWithText(ElevatedButton, 'Envoyer →');
      expect(sendButtonFinder, findsOneWidget);

      final ElevatedButton buttonBefore = tester.widget(sendButtonFinder);
      expect(buttonBefore.onPressed, isNull, reason: 'Le bouton doit être inactif au chargement');

      // Glisser le curseur
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      // Simuler une interaction en modifiant la valeur du curseur
      final Slider slider = tester.widget(sliderFinder);
      slider.onChanged!(4.0);
      await tester.pumpAndSettle();

      final ElevatedButton buttonAfter = tester.widget(sendButtonFinder);
      expect(buttonAfter.onPressed, isNotNull, reason: 'Le bouton devient actif après interaction avec le curseur');
    });

    testWidgets('1. Pas d\'avis possible hors statut delivered dans le détail de commande', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final pendingOrder = OrderUiModel(
        id: 'cmd_pending_1',
        displayNumber: 'CMD-PENDING-1',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        userId: 'test_user',
        customerName: 'Client Test',
        customerPhone: '99887766',
        status: OrderStatus.pending,
        statusHistory: const [],
        items: const [
          OrderItemUiModel(
            productId: 'prod_1',
            name: 'Article en cours',
            unitPrice: 50.0,
            quantity: 1,
            lineTotal: 50.0,
            imageUrl: '',
            poids: 1.0,
          ),
        ],
        itemCount: 1,
        discount: 0.0,
        deliveryAddress: const OrderDeliveryAddress(
          recipientName: 'Client Test',
          phone: '99887766',
          addressLine: 'Rue 1',
          city: 'Tunis',
        ),
        deliveryFee: 7.0,
        subtotal: 50.0,
        total: 57.0,
      );

      final container = ProviderContainer(
        overrides: [
          singleOrderStreamProvider('cmd_pending_1')
              .overrideWith((ref) => Stream.value(pendingOrder)),
          reviewRepositoryProvider.overrideWithValue(MockReviewRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OrderDetailScreen(orderId: 'cmd_pending_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifier l'absence du bandeau "Votre commande est livrée"
      expect(find.text('Votre commande est livrée !'), findsNothing);
      // Vérifier l'absence du bouton "Donner mon avis"
      expect(find.text('⭐ Donner mon avis'), findsNothing);
    });

    testWidgets('6. Un visiteur voit les avis sans bouton d\'écriture', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const testProduct = ProductUiModel(
        id: 'prod_visitor_test',
        name: 'Produit Visiteur',
        description: 'Description visiteur',
        price: 89.0,
        imageUrls: [],
        categoryName: 'Tech',
        availability: ProductAvailability.inStock,
      );

      final mockRepo = MockReviewRepository();
      // Ajouter un avis pour ce produit
      await mockRepo.submitReview(const ReviewUiModel(
        id: 'cmd_vis_prod_visitor_test',
        productId: 'prod_visitor_test',
        orderId: 'cmd_vis',
        userId: 'u_visitor_reviewer',
        authorName: 'Karim M.',
        rating: 5,
        comment: 'Très bon produit testé par un client.',
      ));

      final container = ProviderContainer(
        overrides: [
          reviewRepositoryProvider.overrideWithValue(mockRepo),
          // Visiteur non éligible (pas d'ordre livré)
          eligibleDeliveredOrderIdProvider('prod_visitor_test')
              .overrideWith((ref) => Future.value(null)),
          myReviewForProductProvider('prod_visitor_test')
              .overrideWith((ref) => Future.value(null)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ProductReviewsSection(product: testProduct),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Les avis doivent être visibles pour le visiteur
      expect(find.text('Avis des clients'), findsOneWidget);
      expect(find.text('Karim M.'), findsOneWidget);
      expect(find.text('Très bon produit testé par un client.'), findsOneWidget);
      expect(find.text('Achat vérifié ✅'), findsOneWidget);

      // MAIS aucun bouton d'écriture ne doit apparaître
      expect(find.text('⭐ Donner mon avis'), findsNothing);
    });
  });
}
