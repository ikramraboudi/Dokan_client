import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Dokan_client/core/ui/widgets/bounce_nav_bar.dart';

void main() {
  final testItems = [
    const BounceNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Accueil',
    ),
    const BounceNavItem(
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
      label: 'Catégories',
    ),
    const BounceNavItem(
      icon: Icons.favorite_outline_rounded,
      selectedIcon: Icons.favorite_rounded,
      label: 'Favoris',
    ),
    const BounceNavItem(
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag_rounded,
      label: 'Panier',
      badgeCount: 3,
    ),
    const BounceNavItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  Widget buildTestableNavBar({
    required int currentIndex,
    required ValueChanged<int> onTap,
    List<BounceNavItem>? items,
    double width = 390.0,
    bool disableAnimations = false,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: Size(width, 844.0),
        padding: const EdgeInsets.only(bottom: 24.0),
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        home: Scaffold(
          body: const SizedBox(),
          bottomNavigationBar: BounceBottomNavBar(
            items: items ?? testItems,
            currentIndex: currentIndex,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  group('BounceBottomNavBar - Tests de Widget', () {
    testWidgets('1. Affichage initial des 5 onglets et vérification Semantics', (tester) async {
      int selected = 0;

      await tester.pumpWidget(
        buildTestableNavBar(
          currentIndex: selected,
          onTap: (index) => selected = index,
        ),
      );
      await tester.pumpAndSettle();

      // Vérification que les 5 libellés sont présents
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Catégories'), findsOneWidget);
      expect(find.text('Favoris'), findsOneWidget);
      expect(find.text('Panier'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Vérification des Semantics
      expect(
        tester.getSemantics(find.bySemanticsLabel('Accueil')),
        matchesSemantics(
          label: 'Accueil',
          isSelected: true,
          isButton: true,
          hasTapAction: true,
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Catégories')),
        matchesSemantics(
          label: 'Catégories',
          isSelected: false,
          isButton: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('2. Toucher un onglet appelle le callback onTap et déclenche la transition', (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        buildTestableNavBar(
          currentIndex: 0,
          onTap: (index) => tappedIndex = index,
        ),
      );
      await tester.pumpAndSettle();

      // Toucher l'onglet "Catégories" (index 1)
      await tester.tap(find.text('Catégories'));
      await tester.pump();

      expect(tappedIndex, 1);
    });

    testWidgets('3. Badge Panier présent quand Panier n\'est PAS sélectionné (sur l\'icône)', (tester) async {
      await tester.pumpWidget(
        buildTestableNavBar(
          currentIndex: 0, // Accueil actif, Panier inactif
          onTap: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      // Le texte du badge "3" doit être présent à l'écran
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('4. Badge Panier présent quand Panier EST sélectionné (sur la bulle flottante)', (tester) async {
      await tester.pumpWidget(
        buildTestableNavBar(
          currentIndex: 3, // Panier actif
          onTap: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      // Le texte du badge "3" reste affiché sur la bulle
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('5. Re-toucher l\'onglet actif déclenche le callback (retour racine)', (tester) async {
      int tappedCount = 0;

      await tester.pumpWidget(
        buildTestableNavBar(
          currentIndex: 2, // Favoris actif
          onTap: (index) {
            if (index == 2) tappedCount++;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Re-clic sur Favoris
      await tester.tap(find.text('Favoris'));
      await tester.pump();

      expect(tappedCount, 1);
    });

    testWidgets('6. Support petit écran 320 px sans overflow', (tester) async {
      await tester.pumpWidget(
        buildTestableNavBar(
          currentIndex: 0,
          onTap: (_) {},
          width: 320.0, // Largeur minimale d'un smartphone
        ),
      );
      await tester.pumpAndSettle();

      // Aucun overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('7. Mode sans animations (disableAnimations = true)', (tester) async {
      int active = 0;

      await tester.pumpWidget(
        buildTestableNavBar(
          currentIndex: active,
          onTap: (idx) => active = idx,
          disableAnimations: true,
        ),
      );
      await tester.pump();

      // Changement immédiat sans crash
      await tester.pumpWidget(
        buildTestableNavBar(
          currentIndex: 4,
          onTap: (idx) => active = idx,
          disableAnimations: true,
        ),
      );
      await tester.pump();

      expect(find.text('Profil'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
