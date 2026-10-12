/// ============================================================================
/// RÔLE DU FICHIER :
/// Configuration principale du routeur déclaratif GoRouter.
/// Il organise l'arbre complet des routes de l'application, configure la clé de
/// navigation racine et met en place le découpage en 5 branches d'onglets
/// persistants via `StatefulShellRoute`.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/navigation/` (Configuration Routeur).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : `lib/app.dart` qui l'injecte dans `MaterialApp.router`.
/// - Dépend de :
///   * `package:go_router/go_router.dart`.
///   * `main_shell.dart` pour le conteneur visuel des onglets.
///   * `routes.dart` pour les constantes de chemins.
///   * Tous les écrans de `feature/`.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../feature/auth/forgot_password_screen.dart';
import '../../feature/auth/login_screen.dart';
import '../../feature/auth/register_screen.dart';
import '../../feature/cart/cart_screen.dart';
import '../../feature/catalog/catalog_screen.dart';
import '../../feature/catalog/categories_screen.dart';
import '../../feature/catalog/search_screen.dart';
import '../../feature/favorites/favorites_screen.dart';
import '../../feature/home/home_screen.dart';
import '../../feature/product/product_detail_screen.dart';
import '../../feature/profile/profile_screen.dart';
import '../../feature/splash/splash_screen.dart';
import 'main_shell.dart';
import 'routes.dart';

/// Clé globale du navigateur racine permettant d'afficher des dialogues ou
/// d'ouvrir des écrans plein écran par-dessus la barre de navigation inférieure.
final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'rootNav');

/// INSTANCE GLOBALE DU ROUTEUR GOROUTER
///
/// MOT TECHNIQUE - GoRouter :
/// Contrôleur de navigation déclarative permettant d'associer des chemins URLs
/// à des widgets et de gérer l'historique de manière robuste.

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    // --- Écran de démarrage (Splash Screen) ---
    // Affiché en plein écran au lancement pendant 3 secondes
    GoRoute(
      path: AppRoutes.splash,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),

    // --- Écrans secondaires empilés par-dessus la barre d'onglets (avec bouton retour) ---
    GoRoute(
      path: AppRoutes.catalog,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        // Extraction des paramètres d'URL (ex: /catalog?category=Mode&q=Robe)
        final category = state.uri.queryParameters['category'];
        final query = state.uri.queryParameters['q'];
        return CatalogScreen(
          categoryName: category,
          searchQuery: query,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.search,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: AppRoutes.productDetail,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        // Extraction du paramètre dynamique de chemin (ex: :id)
        final id = state.pathParameters['id'] ?? '';
        return ProductDetailScreen(productId: id);
      },
    ),

    // --- Écrans du module d'authentification ---
    GoRoute(
      path: AppRoutes.login,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // COQUILLE DE NAVIGATION PERSISTANTE À 5 ONGLETS
    //
    // MOT TECHNIQUE - StatefulShellRoute.indexedStack :
    // Chaque branche (`StatefulShellBranch`) maintient sa propre pile d'écrans
    // et sa propre position de défilement en mémoire, même lorsqu'on change d'onglet.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // MainShell affiche la barre inférieure NavigationBar avec le badge du panier
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // Branche 0 : Onglet Accueil
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Branche 1 : Onglet Catégories
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.categories,
              builder: (context, state) => const CategoriesScreen(),
            ),
          ],
        ),

        // Branche 2 : Onglet Favoris (affiche invite connexion ou liste client)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.favorites,
              builder: (context, state) => const FavoritesScreen(),
            ),
          ],
        ),

        // Branche 3 : Onglet Panier d'achat
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.cart,
              builder: (context, state) => const CartScreen(),
            ),
          ],
        ),

        // Branche 4 : Onglet Profil utilisateur
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
