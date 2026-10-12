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
