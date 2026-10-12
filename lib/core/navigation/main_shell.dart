/// ============================================================================
/// RÔLE DU FICHIER :
/// Squelette visuel de la barre de navigation inférieure persistante à 5 onglets.
/// Il héberge le widget `navigationShell` fourni par GoRouter et affiche le
/// composant Material 3 `NavigationBar` enrichi d'un badge dynamique pour le panier.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/navigation/` (Interface Structurelle).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : `app_router.dart` comme widget conteneur du `StatefulShellRoute`.
/// - Dépend de :
///   * `package:flutter_riverpod` pour observer le badge d'articles.
///   * `package:go_router` pour commuter entre les branches d'onglets.
///   * `core/theme/app_colors.dart` pour le style des icônes et du badge.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// PROVIDER DU COMPTEUR D'ARTICLES DANS LE PANIER
///
/// MOT TECHNIQUE - `StateProvider<int>` :
/// Provider Riverpod simplifié stockant une valeur élémentaire (ici un entier).
/// Il est mis à jour chaque fois qu'un article est ajouté, supprimé ou ajusté
/// dans le panier, et met à jour instantanément le badge rouge sur l'icône du panier.
final cartCountProvider = StateProvider<int>((ref) => 0);

/// Coquille de navigation principale (MainShell).
///
/// MOT TECHNIQUE - ConsumerWidget :
/// Widget sans état interne local (comme StatelessWidget), mais capable d'écouter
/// des providers Riverpod grâce au paramètre `WidgetRef ref` injecté dans `build`.
class MainShell extends ConsumerWidget {
  /// Objet de contrôle fourni par GoRouter représentant l'état des branches d'onglets.
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  /// FONCTIONNALITÉ :
  /// Bascule l'affichage vers l'onglet sélectionné.
  /// Si l'utilisateur ré-appuie sur l'onglet déjà actif, le ramène au début de la page.
  ///
  /// PARAMÈTRE :
  /// - [index] : Numéro de l'onglet touché (0 à 4).

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Si l'onglet est déjà sélectionné, réinitialise la pile à sa racine
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoute réactive du nombre total d'articles présents dans le panier
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      // Affiche le contenu de l'écran correspondant à l'onglet sélectionné
      body: navigationShell,

      // --- Barre de navigation inférieure Material 3 ---
      // Fixe en bas de l'écran sur tous les 5 onglets principaux
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        destinations: [
          // Destination 0 : Accueil
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Accueil',
            tooltip: 'Onglet Accueil',
          ),

          // Destination 1 : Catégories
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.primary),
            label: 'Catégories',
            tooltip: 'Onglet Catégories',
          ),

          // Destination 2 : Favoris
          const NavigationDestination(
            icon: Icon(Icons.favorite_outline_rounded),
            selectedIcon: Icon(Icons.favorite_rounded, color: AppColors.favorite),
            label: 'Favoris',
            tooltip: 'Onglet Favoris',
          ),

          // Destination 3 : Panier (avec Badge numérique ambre)
          // MOT TECHNIQUE - Badge :
          // Composant Material 3 superposant une pastille informative sur une icône.
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

          // Destination 4 : Profil
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
