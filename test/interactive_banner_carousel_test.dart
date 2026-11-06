import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Dokan_client/core/theme/app_colors.dart';
import 'package:Dokan_client/feature/home/widgets/interactive_banner_carousel.dart';

void main() {
  final testBanners = [
    const BannerItem(
      title: 'Nouvelle Collection',
      subtitle: 'Découvrez les dernières tendances',
      tag: 'NOUVEAU',
      colors: [AppColors.primaryDark, AppColors.primary],
    ),
    const BannerItem(
      title: 'Promotions Choc',
      subtitle: 'Jusqu\'à -50% sur le mobilier',
      tag: 'PROMO',
      colors: [AppColors.accent, AppColors.primary],
    ),
    const BannerItem(
      title: 'Maison & Décoration',
      subtitle: 'Les plus beaux styles pour votre intérieur',
      tag: 'TENDANCE',
      colors: [AppColors.primary, AppColors.primaryLight],
    ),
  ];

  Widget buildTestableCarousel({
    List<BannerItem>? banners,
    bool disableAnimations = false,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: InteractiveBannerCarousel(
            banners: banners ?? testBanners,
          ),
        ),
      ),
    );
  }

  group('InteractiveBannerCarousel Tests', () {
    testWidgets('(1) Le carrousel affiche toutes les bannières et l\'indicateur actif suit la page',
        (tester) async {
      await tester.pumpWidget(buildTestableCarousel());
      await tester.pump(const Duration(milliseconds: 500));

      // Première bannière visible
      expect(find.text('Nouvelle Collection'), findsOneWidget);
      expect(find.text('NOUVEAU'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);

      // Vérifie que l'indicateur 0 est sélectionné
      final firstIndicator = tester.widget<Semantics>(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.selected == true &&
            w.properties.label?.contains('Bannière 1 sur 3') == true),
      );
      expect(firstIndicator.properties.selected, isTrue);

      // Fait glisser vers la page suivante
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pump(const Duration(milliseconds: 700));

      // Deuxième bannière active
      expect(find.text('Promotions Choc'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);

      final secondIndicator = tester.widget<Semantics>(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.selected == true &&
            w.properties.label?.contains('Bannière 2 sur 3') == true),
      );
      expect(secondIndicator.properties.selected, isTrue);
    });

    testWidgets('(2) Toucher un point indicateur change de bannière', (tester) async {
      await tester.pumpWidget(buildTestableCarousel());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('1/3'), findsOneWidget);

      // Clic sur l'indicateur de la bannière 3
      final targetDot = find.byWidgetPredicate((w) =>
          w is Semantics &&
          w.properties.label?.contains('Bannière 3 sur 3') == true);
      expect(targetDot, findsOneWidget);

      await tester.tap(targetDot);
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // La bannière 3 devient active
      expect(find.text('Maison & Décoration'), findsOneWidget);
      expect(find.text('3/3'), findsOneWidget);
    });

    testWidgets('(3) Le défilement automatique est suspendu quand disableAnimations est vrai',
        (tester) async {
      await tester.pumpWidget(buildTestableCarousel(disableAnimations: true));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Nouvelle Collection'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);

      // Avance le temps de 10 secondes
      await tester.pump(const Duration(seconds: 10));

      // Aucune rotation automatique : la première bannière est toujours active
      expect(find.text('Nouvelle Collection'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('(4) L\'action au toucher d\'une bannière fonctionne toujours avec retour tactile',
        (tester) async {
      bool bannerTapped = false;
      final bannersWithCallback = [
        BannerItem(
          title: 'Offre Spéciale',
          subtitle: 'Cliquez ici pour en profiter',
          tag: 'EXCLU',
          colors: const [AppColors.primary, AppColors.primaryDark],
          onTap: () {
            bannerTapped = true;
          },
        ),
      ];

      await tester.pumpWidget(buildTestableCarousel(banners: bannersWithCallback));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Offre Spéciale'), findsOneWidget);

      // Tap sur la bannière
      await tester.tap(find.text('Offre Spéciale'));
      await tester.pump(const Duration(milliseconds: 150));

      expect(bannerTapped, isTrue);
    });

    testWidgets('(5) Accessibilité : cibles tactiles >= 48 dp et sémantiques présentes',
        (tester) async {
      await tester.pumpWidget(buildTestableCarousel());
      await tester.pump(const Duration(milliseconds: 500));

      // Vérifie les zones tactiles des points indicateurs (minTouchTarget = 48 dp)
      final inkWells = find.descendant(
        of: find.bySemanticsLabel(RegExp(r'Bannière \d sur 3')),
        matching: find.byType(Container),
      );

      for (final element in inkWells.evaluate()) {
        final renderBox = element.renderObject as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          expect(renderBox.size.width >= 48.0, isTrue);
          expect(renderBox.size.height >= 48.0, isTrue);
        }
      }
    });

    testWidgets('(6) Le défilement automatique avance après 2 secondes quand animations actives',
        (tester) async {
      await tester.pumpWidget(buildTestableCarousel());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('1/3'), findsOneWidget);

      // Avance de 2s pour compléter la barre de progression
      await tester.pump(const Duration(seconds: 2));
      // Pompe l'animation de transition vers la page suivante
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // La deuxième bannière devient active
      expect(find.text('2/3'), findsOneWidget);
      expect(find.text('Promotions Choc'), findsOneWidget);
    });
  });
}
