import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soukna_client/app.dart';

void main() {
  testWidgets('Soukna app smoke test – splash then home',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SouknaApp(),
      ),
    );

    // Vérifie la présence du nom Soukna au démarrage (splash)
    expect(find.text('Soukna'), findsWidgets);

    // Écoulement du délai de vérification de session du splash (3 s)
    await tester.pump(const Duration(milliseconds: 3100));

    // Pompe trame par trame pour laisser le router naviguer vers home
    // sans pumpAndSettle (les Images réseau créent des timers infinis)
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Vérifie l'arrivée sur l'accueil — section visible
    expect(find.text('Nouvelle Collection'), findsOneWidget);

    // Navigation bar présente
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
