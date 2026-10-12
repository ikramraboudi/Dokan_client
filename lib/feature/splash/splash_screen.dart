/// ============================================================================
/// RÔLE DU FICHIER :
/// Écran de démarrage officiel de l'application Dokan (`SplashScreen`).
///
/// COMPORTEMENTS CLÉS :
/// 1) Affiche l'icône boutique, le titre "Dokan" et un indicateur de chargement.
/// 2) Maintient l'affichage pendant exactement 3 secondes (`AppConfig.splashDuration`).
/// 3) Redirige automatiquement vers l'Accueil (`AppRoutes.home`) à l'échéance.
/// 4) En cas d'erreur de session, réinitialise en mode visiteur et redirige vers l'accueil.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `feature/splash/` (Écran de Lancement).
///
/// RELATIONS ET DÉPENDANCES :
/// - Déclaré par : `core/navigation/app_router.dart` comme route initiale.
/// - Dépend de :
///   * `core/config/app_config.dart` pour `splashDuration`.
///   * `core/session/session_provider.dart` pour la session.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/navigation/routes.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Écran de lancement initial (Splash Screen).
///
/// MOT TECHNIQUE - ConsumerStatefulWidget :
/// Widget avec état interne (Stateful) ayant accès au cycle de vie (`initState`, `dispose`)
/// et aux providers Riverpod via l'objet `ref`.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Lance la temporisation asynchrone dès l'insertion du widget dans l'arbre
    _checkInitialSession();
  }

  /// SCÉNARIO MÉTIER : CYCLE DE VIE DU SPLASH SCREEN
  /// 1) L'application démarre et affiche le logo de la marque.
  /// 2) Attend la durée configurée (3 secondes) sans bloquer le thread graphique.
  /// 3) Si le widget est toujours affiché (`mounted`), navigue vers `/home`.
  /// 4) Si une exception survient, bascule en visiteur par précaution et navigue vers `/home`.
  Future<void> _checkInitialSession() async {
    try {
      // Simulation de la vérification de session pendant la durée officielle
      await Future.delayed(AppConfig.splashDuration);

      // MOT TECHNIQUE - mounted :
      // Vérifie que l'écran existe encore avant d'appeler context.go() pour éviter tout plantage.
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (_) {
      // En cas d'erreur inattendue, réinitialisation sécurisée et redirection vers l'accueil
      if (mounted) {
        ref.read(sessionProvider.notifier).logout();
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Logo de la boutique dans un cercle teinté doux ---
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimens.space24),

            // --- Nom officiel de la marque Dokan ---
            const Text(
              AppConfig.appName,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.8,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimens.space8),

            // --- Slogan de l'application ---
            const Text(
              'Votre commerce en ligne au quotidien',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.space40),

            // --- Spinner de chargement circulaire miniature ---
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
