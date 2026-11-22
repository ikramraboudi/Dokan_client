/// ============================================================================
/// RÔLE DU FICHIER : Squelette visuel de la barre de navigation inférieure (NavigationBar Material 3) avec badge panier réactif.
/// INTERAGIT AVEC : app_router.dart, cartCountProvider, CartNotifier.
/// POUR L'ORAL : « C'est la coquille visuelle affichant la barre inférieure à 5 onglets avec un badge dynamique qui s'incrémente selon le panier. »
/// ============================================================================
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
import '../ui/widgets/bounce_nav_bar.dart';

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

      // --- Barre de navigation flottante style « Bounce » (bulle de verre) ---
      bottomNavigationBar: BounceBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onDestinationSelected,
        items: [
          // Destination 0 : Accueil
          const BounceNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Accueil',
            tooltip: 'Onglet Accueil',
          ),

          // Destination 1 : Catégories
          const BounceNavItem(
            icon: Icons.grid_view_outlined,
            selectedIcon: Icons.grid_view_rounded,
            label: 'Catégories',
            tooltip: 'Onglet Catégories',
          ),

          // Destination 2 : Favoris
          const BounceNavItem(
            icon: Icons.favorite_outline_rounded,
            selectedIcon: Icons.favorite_rounded,
            label: 'Favoris',
            tooltip: 'Onglet Favoris',
          ),

          // Destination 3 : Panier (avec Badge numérique ambre réactif)
          BounceNavItem(
            icon: Icons.shopping_bag_outlined,
            selectedIcon: Icons.shopping_bag_rounded,
            label: 'Panier',
            tooltip: 'Onglet Panier',
            badgeCount: cartCount,
          ),

          // Destination 4 : Profil
          const BounceNavItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Profil',
            tooltip: 'Onglet Profil',
          ),
        ],
      ),
    );
  }
}
