/// ============================================================================
/// RÔLE DU FICHIER : Configuration racine de MaterialApp.router avec thème Material 3 et GoRouter.
/// INTERAGIT AVEC : main.dart, app_router.dart, app_theme.dart.
/// POUR L'ORAL : « Ce fichier configure notre application MaterialApp avec le routage déclaratif GoRouter et notre thème Material 3 global. »
/// ============================================================================
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/routes.dart';
import 'core/session/session_provider.dart';
import 'core/theme/app_theme.dart';
import 'services/notification_service.dart';

/// Widget racine de l'application Dokan.
///
/// MOT TECHNIQUE - ConsumerStatefulWidget :
/// Permet à DokanApp d'initialiser les services applicatifs au démarrage
/// (comme le NotificationService et l'écoute des notifications FCM).
class DokanApp extends ConsumerStatefulWidget {
  const DokanApp({super.key});

  @override
  ConsumerState<DokanApp> createState() => _DokanAppState();
}

class _DokanAppState extends ConsumerState<DokanApp> {
  @override
  void initState() {
    super.initState();
    final notifService = ref.read(notificationServiceProvider);
    notifService.initialize(
      onNavigateToOrder: (orderId) {
        final session = sessionStateNotifier.value;
        if (session.isGuest) {
          // Visiteur non connecté : redirige vers l'accueil du profil
          appRouter.go(AppRoutes.profile);
        } else {
          // Client connecté : navigation sécurisée vers le détail de la commande
          try {
            appRouter.push('${AppRoutes.myOrders}/$orderId');
          } catch (_) {
            appRouter.go(AppRoutes.myOrders);
          }
        }
      },
    );
    // Demande immédiate de la permission sur Android 13+ pour garantir la réception
    notifService.requestPermission();
  }

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
