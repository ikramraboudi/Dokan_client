/// ============================================================================
/// RÔLE DU FICHIER : Configuration déclarative GoRouter avec StatefulShellRoute pour 5 onglets et routes secondaires.
/// INTERAGIT AVEC : main_shell.dart, routes.dart, tous les écrans de feature/.
/// POUR L'ORAL : « Nous utilisons GoRouter avec StatefulShellRoute pour conserver l'état et le défilement de nos 5 onglets sans rechargement. »
/// ============================================================================
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
import '../../feature/profile/change_password_screen.dart';
import '../../feature/profile/edit_profile_screen.dart';
import '../../feature/profile/faq_screen.dart';
import '../../feature/profile/legal_screen.dart';
import '../../feature/profile/profile_screen.dart';
import '../../feature/profile/settings_and_help_screen.dart';
import '../../feature/splash/splash_screen.dart';
import '../../feature/address/add_edit_address_screen.dart';
import '../../feature/address/addresses_screen.dart';
import '../../feature/checkout/checkout_screen.dart';
import '../../feature/checkout/order_confirmation_screen.dart';
import '../../feature/orders/my_orders_screen.dart';
import '../../feature/orders/order_detail_screen.dart';
import '../../feature/orders/order_tracking_screen.dart';
import '../../feature/orders/review_screen.dart';
import '../session/session_provider.dart';
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
  refreshListenable: sessionStateNotifier,
  redirect: (context, state) {
    final session = sessionStateNotifier.value;
    final path = state.uri.path;

    // Pendant le chargement initial de session au démarrage, ne rien intercepter
    if (session.isLoading) return null;

    // Routes protégées réservées strictement aux clients connectés
    final isProtectedRoute = path == AppRoutes.editProfile ||
        path == AppRoutes.changePassword ||
        path == AppRoutes.settingsAndHelp ||
        path == AppRoutes.myOrders ||
        path.startsWith('/orders') ||
        path == AppRoutes.addresses ||
        path.startsWith('/addresses') ||
        path == AppRoutes.checkout;

    // Exceptions publiques explicites (accessibles aux visiteurs sans connexion)
    final isPublicException = path == AppRoutes.terms ||
        path == AppRoutes.privacy ||
        path == AppRoutes.faq;

    if (session.isGuest && isProtectedRoute && !isPublicException) {
      // Redirige le visiteur non connecté vers l'écran d'accueil du profil
      return AppRoutes.profile;
    }

    return null;
  },
  routes: [
    // --- Écran de démarrage (Splash Screen) ---
    // Affiché en plein écran au lancement pendant 3 secondes
    GoRoute(
      path: AppRoutes.splash,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
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

    // --- Écrans du flux de commande, adresses et suivi ---
    GoRoute(
      path: AppRoutes.checkout,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.orderConfirmation}/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => OrderConfirmationScreen(
        orderId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: AppRoutes.myOrders,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MyOrdersScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.myOrders}/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => OrderDetailScreen(
        orderId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '${AppRoutes.myOrders}/:id/tracking',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => OrderTrackingScreen(
        orderId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: AppRoutes.orderReview,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final orderId = state.pathParameters['orderId'] ?? '';
        final productId = state.pathParameters['productId'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;
        return ReviewScreen(
          orderId: orderId,
          productId: productId,
          productName: extra?['productName'] as String?,
          productImageUrl: extra?['productImageUrl'] as String?,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.addresses,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddressesScreen(),
    ),
    GoRoute(
      path: AppRoutes.addAddress,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddEditAddressScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.editAddress}/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AddEditAddressScreen(
        addressId: state.pathParameters['id'],
      ),
    ),

    // --- Écrans du profil, sécurité, paramètres et aide ---
    GoRoute(
      path: AppRoutes.editProfile,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.changePassword,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsAndHelp,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsAndHelpScreen(),
    ),
    GoRoute(
      path: AppRoutes.faq,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FaqScreen(),
    ),
    GoRoute(
      path: AppRoutes.terms,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LegalScreen(type: LegalType.terms),
    ),
    GoRoute(
      path: AppRoutes.privacy,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LegalScreen(type: LegalType.privacy),
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
