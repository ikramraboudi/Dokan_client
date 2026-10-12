/// ============================================================================
/// RÔLE DU FICHIER :
/// Widget racine de l'application (`DokanApp`).
/// Il configure les fondations de l'interface : le titre de l'application,
/// le thème Material 3 (couleurs claires chaleureuses) et le routeur GoRouter.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche Racine (Configuration Application).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : `main.dart` et les tests d'intégration (`widget_test.dart`).
/// - Dépend de :
///   * `core/config/app_config.dart` (nom de l'application).
///   * `core/theme/app_theme.dart` (thème Material 3).
///   * `core/navigation/app_router.dart` (configuration GoRouter).
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';

/// Widget racine de l'application Dokan.
///
/// MOT TECHNIQUE - StatelessWidget :
/// Widget immuable qui ne possède pas d'état interne variable dans le temps.
/// Il décrit simplement la structure statique de base.
class DokanApp extends StatelessWidget {
  const DokanApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MOT TECHNIQUE - MaterialApp.router :
    // Variante de MaterialApp qui délègue la gestion de la navigation et de
    // l'historique d'écrans à un contrôleur déclaratif moderne (GoRouter).
    return MaterialApp.router(
      // Nom de l'application affiché dans le gestionnaire de tâches Android
      title: AppConfig.appName,

      // Désactive le bandeau rouge "DEBUG" en haut à droite pour une interface soignée
      debugShowCheckedModeBanner: false,

      // Thème clair Material 3 basé exclusivement sur la palette de couleurs AppColors
      theme: AppTheme.lightTheme,

      // Instance singleton du routeur GoRouter gérant les 5 onglets et les redirections
      routerConfig: appRouter,
    );
  }
}
