/// ============================================================================
/// RÔLE DU FICHIER : Écran « Paramètres et aide » structuré en sections de cartes réelles (Compte, Aide, Légal, À propos).
/// INTERAGIT AVEC : AuthService, package_info_plus, AppRoutes, SupportBottomSheet.
/// POUR L'ORAL : « Cette page regroupe les paramètres utiles et l'assistance client sans aucun faux réglage fictif. »
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/config/app_config.dart';
import '../../core/navigation/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_top_bar.dart';
import '../../services/auth_service.dart';
import 'support_bottom_sheet.dart';

class SettingsAndHelpScreen extends StatefulWidget {
  final AuthService? authService;

  const SettingsAndHelpScreen({super.key, this.authService});

  @override
  State<SettingsAndHelpScreen> createState() => _SettingsAndHelpScreenState();
}

class _SettingsAndHelpScreenState extends State<SettingsAndHelpScreen> {
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
                ],
              ),
            ),
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
}
