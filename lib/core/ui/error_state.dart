import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// ============================================================
///  SOUKNA — COMPOSANT D'ÉTAT D'ERREUR
/// ============================================================
class ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final String retryButtonText;

  const ErrorState({
    super.key,
    this.message,
    this.onRetry,
    this.retryButtonText = 'Réessayer',
  });

  @override
  Widget build(BuildContext context) {
    final displayMessage = message ??
        'Impossible de charger ces informations. Vérifiez votre connexion puis réessayez.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space32,
          vertical: AppDimens.space40,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.errorSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimens.space24),
            Text(
              'Oups ! Une erreur est survenue',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimens.space24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryButtonText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
