import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_top_bar.dart';

///  Dokan — ÉCRAN PROFIL ( VISITEUR VS CLIENT)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showComingSoonSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cette fonctionnalité sera disponible prochainement.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
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
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(sessionProvider.notifier).logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vous avez été déconnecté.'),
                  duration: Duration(seconds: 2),
                ),
              );
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

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Mon profil',
      ),
      body: session.isGuest
          ? _buildGuestView(context)
          : _buildClientView(context, ref, session.user!),
    );
  }

  /// Vue pour le visiteur
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
              child: const Icon(
                Icons.person_outline_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimens.space24),
            Text(
              'Bienvenue sur Dokan',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppDimens.space8),
            const Text(
              'Connectez-vous pour gérer votre compte, vos favoris et vos commandes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppDimens.space32),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.login),
              child: const Text('Se connecter'),
            ),
            const SizedBox(height: AppDimens.space12),
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.register),
              child: const Text('Créer un compte'),
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
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.space24),

        // Raccourcis hors périmètre avec SnackBar prochainement
        _buildMenuTile(
          context,
          icon: Icons.person_outline_rounded,
          title: 'Modifier le profil',
          onTap: () => _showComingSoonSnackBar(context),
        ),
        _buildMenuTile(
          context,
          icon: Icons.receipt_long_outlined,
          title: 'Mes commandes',
          onTap: () => _showComingSoonSnackBar(context),
        ),
        _buildMenuTile(
          context,
          icon: Icons.location_on_outlined,
          title: 'Mes adresses de livraison',
          onTap: () => _showComingSoonSnackBar(context),
        ),
        _buildMenuTile(
          context,
          icon: Icons.settings_outlined,
          title: 'Paramètres et aide',
          onTap: () => _showComingSoonSnackBar(context),
        ),

        const SizedBox(height: AppDimens.space16),
        // Outil de simulation de session expirée (§6)
        Container(
          margin: const EdgeInsets.only(bottom: AppDimens.space16),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppDimens.radius12),
          ),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius12),
        border: Border.all(color: AppColors.border),
      ),
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
    );
  }
}
