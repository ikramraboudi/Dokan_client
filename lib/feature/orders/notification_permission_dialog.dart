/// ============================================================================
/// RÔLE DU FICHIER : Dialogue d'explication et de demande d'autorisation
/// pour les notifications de suivi de commandes et d'arrivée du coursier.
/// INTERAGIT AVEC : NotificationService, LoginScreen, CheckoutScreen, SettingsAndHelpScreen.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../services/notification_service.dart';

class NotificationPermissionDialog extends StatelessWidget {
  final NotificationService notificationService;
  final String? userId;

  const NotificationPermissionDialog({
    super.key,
    required this.notificationService,
    this.userId,
  });

  /// Méthode d'ouverture utilitaire
  static Future<bool> show(
    BuildContext context, {
    required NotificationService notificationService,
    String? userId,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => NotificationPermissionDialog(
        notificationService: notificationService,
        userId: userId,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radius20),
      ),
      backgroundColor: AppColors.surface,
      contentPadding: const EdgeInsets.all(AppDimens.space24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône d'en-tête
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppDimens.radius16),
            ),
            alignment: Alignment.center,
            child: const ExcludeSemantics(
              child: Text(
                '🔔',
                style: TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space16),

          // Titre explicatif
          const Text(
            'Recevez des alertes sur votre commande',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppDimens.space10),

          // Message
          const Text(
            'Dokan vous informe en direct de la préparation de votre colis, '
            'de son départ en livraison et de l\'arrivée du livreur devant chez vous.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppDimens.space24),

          // Bouton principal : Activer
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final granted = await notificationService.requestPermission();
                if (granted && userId != null && userId!.isNotEmpty) {
                  await notificationService.registerDeviceToken(userId!);
                }
                if (context.mounted) {
                  Navigator.of(context).pop(granted);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radius14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Activer les alertes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space10),

          // Bouton secondaire : Plus tard
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radius14),
                ),
              ),
              child: const Text(
                'Plus tard',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
