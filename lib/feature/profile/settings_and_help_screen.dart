/// ============================================================================
/// RÔLE DU FICHIER : Écran « Paramètres et aide » structuré en sections de cartes réelles (Compte, Aide, Légal, À propos).
/// INTERAGIT AVEC : AuthService, package_info_plus, AppRoutes, SupportBottomSheet.
/// POUR L'ORAL : « Cette page regroupe les paramètres utiles et l'assistance client sans aucun faux réglage fictif. »
/// ============================================================================
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/config/app_config.dart';
import '../../core/navigation/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_top_bar.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../orders/notification_permission_dialog.dart';
import 'support_bottom_sheet.dart';

class SettingsAndHelpScreen extends ConsumerStatefulWidget {
  final AuthService? authService;

  const SettingsAndHelpScreen({super.key, this.authService});

  @override
  ConsumerState<SettingsAndHelpScreen> createState() =>
      _SettingsAndHelpScreenState();
}

class _SettingsAndHelpScreenState extends ConsumerState<SettingsAndHelpScreen> {
  late final AuthService _authService;
  String _versionInfo = '1.0.0';

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _versionInfo = '${info.version} (build ${info.buildNumber})';
        });
      }
    } catch (_) {
      // Fallback gracieux si PackageInfo échoue (ex: test unitaire)
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPassword = _authService.hasPasswordProvider;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(
        title: 'Paramètres et aide',
        showBackButton: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.space16),
          children: [
            // ── Section 1 : COMPTE ───────────────────────────────────────────
            _buildSectionHeader('COMPTE'),
            Material(
              color: AppColors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radius16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Modifier le profil',
                    subtitle: 'Nom complet et numéro de téléphone',
                    onTap: () => context.push(AppRoutes.editProfile),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  if (hasPassword) ...[
                    _buildListTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Changer le mot de passe',
                      subtitle: 'Sécurité et accès au compte',
                      onTap: () => context.push(AppRoutes.changePassword),
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                  ],
                  _buildListTile(
                    icon: Icons.location_on_outlined,
                    title: 'Mes adresses de livraison',
                    subtitle: 'Gérer vos lieux de réception',
                    onTap: () => context.push(AppRoutes.addresses),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildListTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications de commande',
                    subtitle: 'Alertes en direct sur vos livraisons',
                    onTap: () => _handleNotificationsTap(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space12),

            // Carte d'optimisation batterie « Pour ne rien rater »
            _buildBatteryOptimizationCard(),
            const SizedBox(height: AppDimens.space24),

            // ── Section 2 : AIDE ET ASSISTANCE ──────────────────────────────
            _buildSectionHeader('AIDE'),
            Material(
              color: AppColors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radius16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Questions fréquentes',
                    subtitle: 'Commandes, livraison, paiement et annulation',
                    onTap: () => context.push(AppRoutes.faq),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildListTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Contacter le support',
                    subtitle: 'Téléphone, WhatsApp ou e-mail',
                    onTap: () => SupportBottomSheet.show(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space24),

            // ── Section 3 : INFORMATIONS LÉGALES ────────────────────────────
            _buildSectionHeader('INFORMATIONS LÉGALES'),
            Material(
              color: AppColors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radius16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.description_outlined,
                    title: 'Conditions d\'utilisation',
                    subtitle: 'Modalités de vente et d\'utilisation du service',
                    onTap: () => context.push(AppRoutes.terms),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildListTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Politique de confidentialité',
                    subtitle: 'Traitement et protection de vos données',
                    onTap: () => context.push(AppRoutes.privacy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space24),

            // ── Section 4 : À PROPOS ─────────────────────────────────────────
            _buildSectionHeader('À PROPOS'),
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radius16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppDimens.radius12),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimens.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConfig.appName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Version $_versionInfo',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimens.space8,
        bottom: AppDimens.space8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppDimens.space8),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppDimens.radius8),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
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
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildBatteryOptimizationCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimens.radius12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.bolt_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppDimens.space12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pour ne rien rater',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pour recevoir vos alertes même lorsque l\'application est fermée, désactivez l\'optimisation de batterie pour Dokan (Paramètres › Applications › Dokan › Batterie › Non restreinte).',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNotificationsTap(BuildContext context) async {
    final notifService = ref.read(notificationServiceProvider);
    final isGranted = await notifService.isPermissionGranted();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (!mounted) return;

    if (isGranted) {
      showDialog(
        context: this.context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radius20),
          ),
          backgroundColor: AppColors.surface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.successSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppDimens.space16),
              const Text(
                'Notifications actives',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimens.space8),
              const Text(
                'Les alertes de suivi de commande et d\'arrivée du coursier sont bien activées sur votre téléphone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppDimens.space16),
              Container(
                padding: const EdgeInsets.all(AppDimens.space12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppDimens.radius12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.bolt_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pour ne rien rater même app fermée, désactivez l\'optimisation de batterie pour Dokan.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radius12),
                    ),
                  ),
                  child: const Text('Compris'),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final activated = await NotificationPermissionDialog.show(
        this.context,
        notificationService: notifService,
        userId: uid,
      );

      if (!activated && mounted) {
        showDialog(
          context: this.context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radius20),
            ),
            backgroundColor: AppColors.surface,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.statusPendingSoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.notifications_off_outlined,
                    color: AppColors.warning,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppDimens.space16),
                const Text(
                  'Activer dans les réglages',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimens.space8),
                const Text(
                  'Pour recevoir les alertes sur votre commande en direct, activez les notifications dans :\n\n'
                  'Paramètres du téléphone › Applications › Dokan › Notifications.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppDimens.space20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radius12),
                      ),
                    ),
                    child: const Text('J\'ai compris'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }
}
