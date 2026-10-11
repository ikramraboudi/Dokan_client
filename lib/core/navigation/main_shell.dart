import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// Provider réactif pour le badge d'articles dans le panier (mis à jour à l'étape 5)
final cartCountProvider = StateProvider<int>((ref) => 0);

/// ============================================================
///  SOUKNA — COQUILLE DE NAVIGATION PERSISTANTE (5 ONGLETS)
/// ============================================================
class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Accueil',
            tooltip: 'Onglet Accueil',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.primary),
            label: 'Catégories',
            tooltip: 'Onglet Catégories',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_outline_rounded),
            selectedIcon: Icon(Icons.favorite_rounded, color: AppColors.favorite),
            label: 'Favoris',
            tooltip: 'Onglet Favoris',
          ),
          NavigationDestination(
            icon: cartCount > 0
                ? Badge(
                    label: Text(
                      cartCount > 99 ? '99+' : '$cartCount',
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: AppColors.accent,
                    child: const Icon(Icons.shopping_bag_outlined),
                  )
                : const Icon(Icons.shopping_bag_outlined),
            selectedIcon: cartCount > 0
                ? Badge(
                    label: Text(
                      cartCount > 99 ? '99+' : '$cartCount',
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: AppColors.accent,
                    child: const Icon(Icons.shopping_bag_rounded, color: AppColors.primary),
                  )
                : const Icon(Icons.shopping_bag_rounded, color: AppColors.primary),
            label: 'Panier',
            tooltip: 'Onglet Panier',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Profil',
            tooltip: 'Onglet Profil',
          ),
        ],
      ),
    );
  }
}
