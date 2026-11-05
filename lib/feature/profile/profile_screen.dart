/// ============================================================================
/// RÔLE DU FICHIER : Profil utilisateur basculant entre visiteur et client, avec raccourcis commandes/adresses et outil de démo de session.
/// INTERAGIT AVEC : sessionProvider, AuthService.signOut(), MyOrdersScreen, AddressesScreen.
/// POUR L'ORAL : « Le profil adapte son affichage selon que l'utilisateur est client ou invité et permet de tester l'expiration de session sans perdre le panier. »
/// ============================================================================
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_top_bar.dart';
import '../../services/auth_service.dart';

///  Dokan — ÉCRAN PROFIL ( VISITEUR VS CLIENT)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    final authService = AuthService();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter de votre compte Dokan ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnDark,
              minimumSize: const Size(100, 44),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              ref.read(sessionProvider.notifier).logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vous avez été déconnecté.'),
                  duration: Duration(seconds: 2),
                ),
              );
              await authService.signOut();
            },
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    // 1. Pendant la restauration de la session au démarrage : spinner, jamais d'écran client
    if (session.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppTopBar(title: 'Mon profil'),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // 2. Visiteur (non connecté) : écran de bienvenue uniquement
    if (session.isGuest || session.user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AppTopBar(title: 'Mon profil'),
        body: _buildGuestView(context),
      );
    }

    // 3. Client connecté : écran profil complet
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Mon profil'),
      body: _buildClientView(context, ref, session.user!),
    );
  }

  /// Vue d'accueil pour le visiteur non connecté (aucun menu, aucun nom/email, aucune donnée)
  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space32,
          vertical: AppDimens.space40,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '👋',
                  style: TextStyle(fontSize: 44),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space24),
            Text(
              'Bienvenue sur Dokan',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppDimens.space8),
            const Text(
              'Connectez-vous pour accéder à votre profil',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppDimens.space32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.login),
                child: const Text('Se connecter'),
              ),
            ),
            const SizedBox(height: AppDimens.space12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push(AppRoutes.register),
                child: const Text('Créer un compte'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vue pour le client connecté
  Widget _buildClientView(BuildContext context, WidgetRef ref, dynamic user) {
    final initials = user.fullName.isNotEmpty
        ? user.fullName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase()
        : 'S';

    return ListView(
      padding: const EdgeInsets.all(AppDimens.space16),
      children: [
        // Carte d'identité client
        Container(
          padding: const EdgeInsets.all(AppDimens.space20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radius16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimens.space4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (user.phone != null && (user.phone as String).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.phone as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.space24),

        // Menus du compte
        _buildMenuTile(
          context,
          icon: Icons.person_outline_rounded,
          title: 'Modifier le profil',
          onTap: () => context.push(AppRoutes.editProfile),
        ),
        _buildMenuTile(
          context,
          icon: Icons.receipt_long_outlined,
          title: 'Mes commandes',
          onTap: () => context.push(AppRoutes.myOrders),
        ),
        _buildMenuTile(
          context,
          icon: Icons.location_on_outlined,
          title: 'Mes adresses de livraison',
          onTap: () => context.push(AppRoutes.addresses),
        ),
        _buildMenuTile(
          context,
          icon: Icons.settings_outlined,
          title: 'Paramètres et aide',
          onTap: () => context.push(AppRoutes.settingsAndHelp),
        ),

        // Outil de simulation de session expirée (visible uniquement en mode debug)
        if (kDebugMode) ...[
          const SizedBox(height: AppDimens.space16),
          Container(
            margin: const EdgeInsets.only(bottom: AppDimens.space16),
            child: Material(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppDimens.radius12),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(
                  Icons.timer_outlined,
                  color: AppColors.warning,
                ),
                title: const Text(
                  'Simuler session expirée',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Test du hook onSessionExpired sans perte du panier',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.play_arrow_rounded, color: AppColors.warning),
                onTap: () {
                  ref.read(sessionProvider.notifier).simulateSessionExpired();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Votre session a expiré. Connectez-vous pour continuer.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        const SizedBox(height: AppDimens.space16),

        // Bouton de déconnexion
        OutlinedButton.icon(
          onPressed: () => _confirmLogout(context, ref),
          icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          label: const Text(
            'Se déconnecter',
            style: TextStyle(color: AppColors.error),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.error, width: 1.2),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space8),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radius12),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: AppColors.textPrimary, size: 22),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}