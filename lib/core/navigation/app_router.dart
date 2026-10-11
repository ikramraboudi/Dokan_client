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

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'rootNav');

/// ============================================================
///  SOUKNA — CONFIGURATION DU ROUTEUR GO_ROUTER
/// ============================================================
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    // --- Écran de démarrage (Splash) ---
    GoRoute(
      path: AppRoutes.splash,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),

    // --- Routes poussées par-dessus la barre de navigation ---
    GoRoute(
      path: AppRoutes.catalog,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
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
        final id = state.pathParameters['id'] ?? '';
        return ProductDetailScreen(productId: id);
      },
    ),

    // --- Routes d'authentification ---
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

    // --- Coquille avec barre de navigation inférieure persistante ---
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // Branche 0 : Accueil
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Branche 1 : Catégories
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.categories,
              builder: (context, state) => const CategoriesScreen(),
            ),
          ],
        ),

        // Branche 2 : Favoris
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.favorites,
              builder: (context, state) => const FavoritesScreen(),
            ),
          ],
        ),

        // Branche 3 : Panier
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.cart,
              builder: (context, state) => const CartScreen(),
            ),
          ],
        ),

        // Branche 4 : Profil
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
