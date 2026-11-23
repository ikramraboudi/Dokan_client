/// ============================================================================
/// RÔLE DU FICHIER :
/// Tests de widgets et de rendu vectoriel pour le nouvel écran de démarrage
/// animé (SplashScreen) et son peintre cinématique (SplashCinematicPainter).
/// ============================================================================
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Dokan_client/feature/splash/splash_screen.dart';
import 'package:Dokan_client/feature/splash/widgets/splash_cinematic_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('A. SplashScreen & SplashCinematicPainter — Constantes et Rendu', () {
    test('1. Constantes temporelles et slogan officiel', () {
      expect(kSplashDurationMs, equals(4500));
      expect(kSplashTagline, equals('Vos achats, livrés chez vous'));
    });

    test('2. Rendu continu du peintre sans aucune exception (0 assertions, 0 erreurs rouges)', () {
      const size = Size(390, 844); // Format smartphone standard

      // Tester 100 pas de progression de 0.0 à 1.0
      for (int step = 0; step <= 100; step++) {
        final progress = step / 100.0;
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        final painter = SplashCinematicPainter(
          progress: progress,
          bagRiseY: progress > 0.84 ? -28.0 : 0.0,
        );

        // Ne doit lever aucune exception ni assertion
        expect(() => painter.paint(canvas, size), returnsNormally);
        final picture = recorder.endRecording();
        picture.dispose();
      }
    });

    testWidgets('3. Mode "Réduire les animations" (disableAnimations) : affichage direct',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: SplashScreen(),
            ),
          ),
        ),
      );

      // Pomper les 300 ms de fondu
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dokan'), findsOneWidget);
      expect(find.text('Vos achats, livrés chez vous'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('4. Déroulement cinématique standard (4500 ms) et typographie',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // 0 ms : Écran initial sans texte
      expect(find.text('Dokan'), findsNothing);
      expect(find.byType(CustomPaint), findsWidgets);

      // 1500 ms : Phase des objets en vol (toujours pas de texte)
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('Dokan'), findsNothing);

      // 2800 ms : Phase du sac en cours
      await tester.pump(const Duration(milliseconds: 1300));
      expect(find.text('Dokan'), findsNothing);

      // 4000 ms : Typographie Dokan apparue
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('D'), findsOneWidget);
      expect(find.text('o'), findsOneWidget);
      expect(find.text('k'), findsOneWidget);
      expect(find.text('a'), findsOneWidget);
      expect(find.text('n'), findsOneWidget);
      expect(find.text(kSplashTagline), findsOneWidget);

      // 4500 ms : Fin de la cinématique
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(kSplashTagline), findsOneWidget);
    });
  });
}
