import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/navigation/routes.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// ============================================================
///  SOUKNA — ÉCRAN DE DÉMARRAGE (SPLASH SCREEN)
/// ============================================================
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    try {
      // Simulation de la vérification de session
      await Future.delayed(AppConfig.splashDuration);
      // Par défaut, l'utilisateur démarre en mode visiteur
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (_) {
      // En cas d'erreur inattendue, ne jamais rester bloqué : redirection vers l'accueil
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
            const Text(
              'Votre commerce en ligne au quotidien',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.space40),
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
