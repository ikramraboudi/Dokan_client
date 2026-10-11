import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../navigation/routes.dart';
import '../session/session_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// ============================================================
///  SOUKNA — DIALOGUE / MODAL D'ACTION PROTÉGÉE (CONNEXION REQUISE)
///  Empêche l'empilement multiple avec _isShowing
/// ============================================================
class AuthRequiredDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onContinueVisiting;

  const AuthRequiredDialog({
    super.key,
    required this.title,
    required this.message,
    this.onContinueVisiting,
  });

  static bool _isShowing = false;

  /// Affiche l'invite modale unique avec enregistrement optionnel de l'action en attente
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    String title = 'Connexion requise',
    required String message,
    VoidCallback? pendingAction,
  }) async {
    if (_isShowing) return;
    _isShowing = true;

    if (pendingAction != null) {
      ref.read(sessionProvider.notifier).setPendingAction(pendingAction);
    }

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => AuthRequiredDialog(
          title: title,
          message: message,
          onContinueVisiting: () => Navigator.of(ctx).pop(),
        ),
      );
    } finally {
      _isShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space24,
          vertical: AppDimens.space20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indicateur supérieur
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space20),

            // Icône
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Titre
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppDimens.space8),

            // Message explicatif
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppDimens.space24),

            // Bouton Se connecter
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.login);
              },
              child: const Text('Se connecter'),
            ),
            const SizedBox(height: AppDimens.space12),

            // Bouton Créer un compte
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.register);
              },
              child: const Text('Créer un compte'),
            ),
            const SizedBox(height: AppDimens.space8),

            // Action secondaire : Continuer la visite
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onContinueVisiting?.call();
              },
              child: const Text(
                'Continuer la visite',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
