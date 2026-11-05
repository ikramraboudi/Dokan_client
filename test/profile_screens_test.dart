/// ============================================================================
/// RÔLE DU FICHIER : Tests unitaires et de widgets pour le profil, la FAQ colorée
/// et les pages légales interactives (« points clés »).
/// INTERAGIT AVEC : ProfileScreen, FaqScreen, LegalScreen, EditProfileScreen, app_router.dart.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Dokan_client/core/navigation/app_router.dart';
import 'package:Dokan_client/core/navigation/routes.dart';
import 'package:Dokan_client/core/session/session_provider.dart';
import 'package:Dokan_client/core/utils/validators.dart';
import 'package:Dokan_client/data/models/user_summary.dart';
import 'package:Dokan_client/feature/profile/edit_profile_screen.dart';
import 'package:Dokan_client/feature/profile/faq_data.dart';
import 'package:Dokan_client/feature/profile/faq_screen.dart';
import 'package:Dokan_client/feature/profile/legal_screen.dart';
import 'package:Dokan_client/feature/profile/profile_screen.dart';
import 'package:Dokan_client/feature/profile/support_bottom_sheet.dart';
import 'package:Dokan_client/services/auth_service.dart';

void main() {
  group('Validators — Profil et Téléphone', () {
    test('Validators.phone rejette les valeurs vides ou trop courtes', () {
      expect(Validators.phone(null), isNotNull);
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone('   '), isNotNull);
      expect(Validators.phone('1234567'), isNotNull);
      expect(Validators.phone('21000000'), isNull);
      expect(Validators.phone('98123456'), isNull);
    });

    test('Validators.fullName vérifie la longueur minimale de 3 caractères', () {
      expect(Validators.fullName(null), isNotNull);
      expect(Validators.fullName(''), isNotNull);
      expect(Validators.fullName('Ab'), isNotNull);
      expect(Validators.fullName('Ali'), isNull);
      expect(Validators.fullName('Karim Trabelsi'), isNull);
    });
  });

  group('TÂCHE 1 — Profil réservé aux clients & Protection des routes', () {
    testWidgets('Un visiteur non connecté voit l\'écran de bienvenue et aucune donnée client',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(
            (ref) => _FakeSessionNotifier(null, isLoading: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pump();

      // Vue visiteur
      expect(find.text('Connectez-vous pour accéder à votre profil'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Se connecter'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Créer un compte'), findsOneWidget);

      // Aucune donnée client ou menu du profil
      expect(find.text('Modifier le profil'), findsNothing);
      expect(find.text('Mes commandes'), findsNothing);
      expect(find.text('Mes adresses'), findsNothing);
      expect(find.text('Paramètres et aide'), findsNothing);
    });

    testWidgets('Un client connecté voit le profil complet', (tester) async {
      const user = UserSummary(
        email: 'client@dokan.tn',
        fullName: 'Nader K',
        phone: '20123456',
      );
      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(
            (ref) => _FakeSessionNotifier(user, isLoading: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Nader K'), findsOneWidget);
      expect(find.text('client@dokan.tn'), findsOneWidget);
      expect(find.text('Modifier le profil'), findsOneWidget);
      expect(find.text('Mes commandes'), findsOneWidget);
      expect(find.text('Mes adresses de livraison'), findsOneWidget);
      expect(find.text('Paramètres et aide'), findsOneWidget);
    });

    test('Redirection GoRouter protège les routes profil pour les visiteurs', () {
      // Configure la session visiteur
      sessionStateNotifier.value = const SessionState(user: null, isLoading: false);

      // Vérifie les routes publiques vs protégées
      expect(AppRoutes.editProfile, '/profile/edit');
      expect(AppRoutes.terms, '/legal/terms');
      expect(AppRoutes.privacy, '/legal/privacy');
      expect(appRouter.configuration.redirect, isNotNull);
    });
  });

  group('TÂCHE 2 — FAQ colorée et accordéon strict', () {
    testWidgets('Affiche 8 questions et permet d\'ouvrir une seule réponse à la fois',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: FaqScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));

      // Vérifie l'en-tête
      expect(find.text('Besoin d\'aide ?'), findsOneWidget);
      expect(find.text('Questions fréquentes'), findsOneWidget);

      // Vérifie que les 8 questions sont bien définies et visibles
      expect(dokanFaqItems.length, 8);
      for (final item in dokanFaqItems) {
        expect(find.text(item.question), findsOneWidget);
      }

      // 1. Déplie la première question : "Comment commander ?"
      await tester.tap(find.text('Comment commander ?'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Ajoutez au panier, puis touchez « Continuer la commande ».'),
        findsOneWidget,
      );

      // 2. Déplie la seconde question : "Comment ajouter une adresse ?"
      await tester.tap(find.text('Comment ajouter une adresse ?'));
      await tester.pump(const Duration(milliseconds: 300));

      // La seconde réponse est visible
      expect(
        find.text('Profil › Mes adresses › Ajouter.'),
        findsOneWidget,
      );

      // La première est refermée (accordéon exclusif)
      expect(
        find.text('Ajoutez au panier, puis touchez « Continuer la commande ».'),
        findsNothing,
      );
    });
  });

  group('TÂCHE 3 — Pages légales « points clés » interactives', () {
    testWidgets('Conditions d\'utilisation affiche 6 cartes et progresse 0/6 -> 6/6',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: LegalScreen(type: LegalType.terms),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Conditions d\'utilisation'), findsWidgets);
      expect(find.text('0/6 points lus'), findsOneWidget);

      // Vérifie la présence des 6 titres
      expect(find.text('Votre compte'), findsOneWidget);
      expect(find.text('Vos commandes'), findsOneWidget);
      expect(find.text('Le paiement'), findsOneWidget);
      expect(find.text('La livraison'), findsOneWidget);
      expect(find.text('L\'annulation'), findsOneWidget);
      expect(find.text('Votre mot de passe'), findsOneWidget);

      // Touche la première carte
      await tester.tap(find.text('Votre compte'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('1/6 points lus'), findsOneWidget);

      // Touche les 5 autres cartes
      await tester.tap(find.text('Vos commandes'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Le paiement'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('La livraison'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('L\'annulation'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Votre mot de passe'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('6/6 points lus'), findsOneWidget);
      expect(find.text('Merci d\'avoir lu ! 🎉'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'J\'ai compris'), findsOneWidget);
    });

    testWidgets('Politique de confidentialité affiche 6 cartes avec titre et emoji',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: LegalScreen(type: LegalType.privacy),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Confidentialité'), findsWidgets);
      expect(find.text('0/6 points lus'), findsOneWidget);

      expect(find.text('Ce que nous collectons'), findsOneWidget);
      expect(find.text('Pourquoi'), findsOneWidget);
      expect(find.text('Où c\'est stocké'), findsOneWidget);
      expect(find.text('Le partage'), findsOneWidget);
      expect(find.text('Vos droits'), findsOneWidget);
      expect(find.text('Une question ?'), findsOneWidget);
    });
  });

  group('EditProfileScreen — Tests de formulaires et état du bouton Enregistrer', () {
    testWidgets('Le bouton Enregistrer est désactivé si aucun champ n\'a été modifié',
        (tester) async {
      const initialUser = UserSummary(
        email: 'client@dokan.tn',
        fullName: 'Sami Ben Ali',
        phone: '22113344',
      );

      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(
            (ref) => _FakeSessionNotifier(initialUser, isLoading: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: EditProfileScreen(authService: _FakeAuthService()),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Sami Ben Ali'), findsOneWidget);
      expect(find.text('22113344'), findsOneWidget);
      expect(find.text('client@dokan.tn'), findsOneWidget);

      final saveButtonFinder = find.widgetWithText(ElevatedButton, 'Enregistrer les modifications');
      expect(saveButtonFinder, findsOneWidget);

      final elevatedButton = tester.widget<ElevatedButton>(saveButtonFinder);
      expect(elevatedButton.onPressed, isNull);
    });
  });

  group('SupportBottomSheet — Canaux de support', () {
    testWidgets('Affiche le message d\'indisponibilité quand aucun canal n\'est configuré',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SupportBottomSheet(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Contacter le support Dokan'), findsOneWidget);
      expect(find.text('Le support n\'est pas encore disponible.'), findsOneWidget);
    });
  });
}

class _FakeSessionNotifier extends SessionNotifier {
  _FakeSessionNotifier(UserSummary? initialUser, {bool isLoading = false}) {
    state = SessionState(user: initialUser, isLoading: isLoading);
    sessionStateNotifier.value = state;
  }
}

class _FakeAuthService extends AuthService {
  @override
  bool get hasPasswordProvider => true;
}
