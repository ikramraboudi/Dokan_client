/// ============================================================================
/// RÔLE DU FICHIER : Feuille modale de contact support (Email, Téléphone, WhatsApp) avec fallback presse-papier.
/// INTERAGIT AVEC : AppConfig, url_launcher, SettingsAndHelpScreen.
/// POUR L'ORAL : « Cette feuille propose les canaux de contact configurés et copie automatiquement la coordonnée en presse-papiers si l'app native échoue. »
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

class SupportBottomSheet extends StatelessWidget {
  const SupportBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radius24),
        ),
      ),
      builder: (_) => const SupportBottomSheet(),
    );
  }

  Future<void> _launchChannel({
    required BuildContext context,
    required Uri uri,
    required String valueToCopy,
    required String successCopyLabel,
  }) async {
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        await _copyToClipboard(context, valueToCopy, successCopyLabel);
      }
    } catch (_) {
      if (context.mounted) {
        await _copyToClipboard(context, valueToCopy, successCopyLabel);
      }
    }
  }

  Future<void> _copyToClipboard(
    BuildContext context,
    String value,
    String label,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copié : $value'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasEmail = AppConfig.supportEmail.trim().isNotEmpty;
    final hasPhone = AppConfig.supportPhone.trim().isNotEmpty;
    final hasWhatsApp = AppConfig.supportWhatsApp.trim().isNotEmpty;
    final hasAnyChannel = hasEmail || hasPhone || hasWhatsApp;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space20,
          vertical: AppDimens.space16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barre de préhension (drag handle)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppDimens.space16),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Contacter le support Dokan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              hasAnyChannel
                  ? 'Notre équipe est à votre écoute pour vous accompagner dans vos commandes.'
                  : 'Notre service client est en cours de configuration.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.space20),

            if (!hasAnyChannel) ...[
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppDimens.radius14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: Text(
                        'Le support n\'est pas encore disponible.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space16),
            ] else ...[
              // Canal 1 : Téléphone
              if (hasPhone)
                _buildChannelTile(
                  context,
                  icon: Icons.phone_outlined,
                  title: 'Appel téléphonique',
                  subtitle: AppConfig.supportPhone,
                  onTap: () {
                    final cleanPhone = AppConfig.supportPhone.replaceAll(' ', '');
                    _launchChannel(
                      context: context,
                      uri: Uri(scheme: 'tel', path: cleanPhone),
                      valueToCopy: AppConfig.supportPhone,
                      successCopyLabel: 'Numéro de téléphone',
                    );
                  },
                ),

              // Canal 2 : WhatsApp
              if (hasWhatsApp)
                _buildChannelTile(
                  context,
                  icon: Icons.chat_outlined,
                  title: 'WhatsApp',
                  subtitle: AppConfig.supportWhatsApp,
                  onTap: () {
                    final cleanNum =
                        AppConfig.supportWhatsApp.replaceAll(RegExp(r'[^0-9]'), '');
                    _launchChannel(
                      context: context,
                      uri: Uri.parse('https://wa.me/$cleanNum'),
                      valueToCopy: AppConfig.supportWhatsApp,
                      successCopyLabel: 'Numéro WhatsApp',
                    );
                  },
                ),

              // Canal 3 : E-mail
              if (hasEmail)
                _buildChannelTile(
                  context,
                  icon: Icons.email_outlined,
                  title: 'E-mail',
                  subtitle: AppConfig.supportEmail,
                  onTap: () {
                    _launchChannel(
                      context: context,
                      uri: Uri(
                        scheme: 'mailto',
                        path: AppConfig.supportEmail,
                        query: 'subject=Support Client Dokan',
                      ),
                      valueToCopy: AppConfig.supportEmail,
                      successCopyLabel: 'Adresse e-mail',
                    );
                  },
                ),
            ],

            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppDimens.space8),
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
