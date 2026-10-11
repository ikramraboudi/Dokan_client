import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_top_bar.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/product_grid.dart';
import '../../data/mock/mock_favorites_repository.dart';

/// ============================================================
///  SOUKNA — ÉCRAN FAVORIS COMPLET (ÉTAPE 5)
///  Visiteur : protection stricte « connexion requise »
///  Client   : liste en temps réel avec retrait immédiat
/// ============================================================
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Mes favoris',
      ),
      body: session.isGuest
          ? _buildGuestView(context)
          : _buildClientView(context, ref),
    );
  }

  /// Vue pour le visiteur non connecté (accès bloqué conforme au cahier des charges)
  Widget _buildGuestView(BuildContext context) {
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
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.favoriteSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 44,
                color: AppColors.favorite,
              ),
            ),
            const SizedBox(height: AppDimens.space24),
            Text(
              'Vos articles favoris',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppDimens.space8),
            const Text(
              'Connectez-vous pour retrouver vos articles favoris.',
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

  /// Vue pour le client connecté avec grille réactive
  Widget _buildClientView(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return favoritesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, _) => ErrorState(
        onRetry: () => ref.read(favoritesProvider.notifier).loadFavorites(),
      ),
      data: (favorites) {
        if (favorites.isEmpty) {
          return EmptyState(
            icon: Icons.favorite_outline_rounded,
            title: 'Aucun favori enregistré',
            message:
                'Vous n\'avez pas encore de favoris. Explorez le catalogue pour trouver vos articles préférés.',
            buttonText: 'Découvrir les produits',
            onAction: () => context.go(AppRoutes.home),
          );
        }

        // Le ProductGrid est lui-même un CustomScrollView, donc on
        // l'utilise directement comme corps du Scaffold (pas de Column
        // intermédiaire) pour un défilement fluide.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.space16,
                AppDimens.space12,
                AppDimens.space16,
                AppDimens.space4,
              ),
              child: Text(
                '${favorites.length} article${favorites.length > 1 ? 's' : ''} dans vos favoris',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: ProductGrid(
                products: favorites,
                isFavorite: (_) => true,
                onProductTap: (product) {
                  context.push(AppRoutes.productDetailPath(product.id));
                },
                onFavoriteTap: (product) {
                  ref.read(favoritesProvider.notifier).removeFavorite(product.id);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} retiré des favoris.'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
