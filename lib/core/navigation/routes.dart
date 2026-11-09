/// ============================================================================
/// RÔLE DU FICHIER : Répertoire centralisé des chemins de navigation (URL strings) pour éviter les chaînes magiques.
/// INTERAGIT AVEC : app_router.dart, tous les boutons de redirection dans les écrans.
/// POUR L'ORAL : « AppRoutes évite les erreurs de frappe en centralisant toutes les URLs sous forme de constantes statiques. »
/// ============================================================================
/// ============================================================================
/// RÔLE DU FICHIER :
/// Centralise les chaînes de caractères représentant les chemins de navigation (URLs)
/// de toute l'application Dokan.
///
/// OBJECTIF :
/// Éviter les chaînes magiques ("magic strings") et les fautes de frappe lors des
/// transitions d'écrans (`context.go` ou `context.push`).
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/navigation/` (Navigation Déclarative).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : `app_router.dart`, `main_shell.dart`, et l'ensemble des écrans
///   pour déclencher les redirections.
/// - Dépend de : Dart pur.
/// ============================================================================
library;

/// Répertoire universel des routes de l'application Dokan.
class AppRoutes {
  AppRoutes._();

  // --- Routes associées aux écrans autonomes ou aux 5 onglets principaux ---
  static const String splash     = '/splash';     // Écran d'ouverture
  static const String home       = '/home';       // Onglet 1 : Accueil
  static const String categories = '/categories'; // Onglet 2 : Catégories
  static const String favorites  = '/favorites';  // Onglet 3 : Favoris (protégé)
  static const String cart       = '/cart';       // Onglet 4 : Panier d'achat
  static const String profile    = '/profile';    // Onglet 5 : Profil (visiteur/client)

  // --- Routes secondaires poussées au-dessus du shell (avec bouton retour) ---
  static const String catalog        = '/catalog';         // Catalogue général ou filtré
  static const String search         = '/search';          // Moteur de recherche
  static const String productDetail  = '/product/:id';     // Fiche produit avec paramètre dynamique
  static const String login          = '/login';           // Écran de connexion
  static const String register       = '/register';        // Écran d'inscription
  static const String forgotPassword = '/forgot-password'; // Récupération mot de passe

  // --- Flux de commande, adresses et suivi de livraison ---
  static const String checkout          = '/checkout';
  static const String orderConfirmation = '/order-confirmation';
  static const String myOrders          = '/orders';
  static const String orderDetail       = '/orders/:id';
  static const String orderTracking     = '/orders/:id/tracking';
  static const String orderQrScan       = '/orders/:id/scan-qr';
  static const String orderReview       = '/orders/:orderId/review/:productId';
  static const String addresses         = '/addresses';
  static const String addAddress        = '/addresses/add';
  static const String editAddress       = '/addresses/edit';

  // --- Profil, paramètres, aide et mentions légales ---
  static const String editProfile      = '/profile/edit';
  static const String changePassword   = '/profile/change-password';
  static const String settingsAndHelp  = '/settings';
  static const String faq              = '/help/faq';
  static const String terms            = '/legal/terms';
  static const String privacy          = '/legal/privacy';

  /// Construit l'URL paramétrée pour ouvrir l'écran d'avis d'un produit d'une commande.
  static String orderReviewPath(String orderId, String productId) =>
      '/orders/$orderId/review/$productId';

  /// FONCTIONNALITÉ :
  /// Construit l'URL paramétrée pour ouvrir la fiche détaillée d'un produit précis.
  ///
  /// PARAMÈTRE :
  /// - [id] : Identifiant du produit (ex: 'prod_1').
  ///
  /// RETOURNE :
  /// La chaîne de route formatée (ex: '/product/prod_1').
  static String productDetailPath(String id) => '/product/$id';
}
