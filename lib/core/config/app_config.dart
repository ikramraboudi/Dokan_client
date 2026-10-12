/// ============================================================================
/// RÔLE DU FICHIER :
/// Configuration globale et centralisée des paramètres applicatifs du produit Dokan.
/// Il regroupe le nom officiel de l'application, la durée du splash screen,
/// la devise nationale (Dinar Tunisien "DT") et la fonction universelle de
/// formatage de prix utilisée sur tous les écrans.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/config/` (Configuration Transverse).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par :
///   * `lib/app.dart` (nom de l'application).
///   * `lib/feature/splash/splash_screen.dart` (durée du splash).
///   * `lib/core/ui/product_card.dart`, `lib/core/ui/price_summary.dart`,
///     `lib/feature/catalog/catalog_screen.dart`, `lib/feature/cart/cart_screen.dart`,
///     `lib/feature/product/product_detail_screen.dart` (formatage des prix).
/// - Dépend de : Aucune dépendance externe (Dart pur).
/// ============================================================================
library;

class AppConfig {
  /// Constructeur privé pour empêcher l'instanciation de cette classe utilitaire.
  AppConfig._();

  /// Nom public officiel de l'application affiché dans les en-têtes et le système Android.
  static const String appName = 'Dokan';

  /// Durée fixe d'affichage de l'écran d'accueil (Splash Screen) avant redirection.
  /// Modifiable uniquement depuis cette constante.
  static const Duration splashDuration = Duration(seconds: 3);

  /// Code ISO de la devise monétaire (Dinar Tunisien).
  static const String currencyCode = 'TND';

  /// Symbole affiché à côté des montants financiers dans toute l'interface.
  static const String currencySymbol = 'DT';

  /// FONCTIONNALITÉ :
  /// Formate un montant numérique décimal en une chaîne textuelle conforme aux
  /// standards tunisiens (séparateur décimal virgule et 3 chiffres après la virgule).
  ///
  /// CHOIX TECHNIQUE :
  /// Centraliser cette fonction garantit qu'aucun prix n'est affiché avec un format
  /// divergent (ex: point au lieu de virgule, ou 2 décimales au lieu de 3).
  ///
  /// PARAMÈTRES :
  /// - [price] : Le montant en double (ex: 49.9 ou 120.0).
  ///
  /// RETOURNE :
  /// Une chaîne formatée (ex: "49,900 DT").
  /// ============================================================================
  static String formatPrice(double price) {
    // Le dinar tunisien utilise historiquement 3 décimales (les millimes)
    final parts = price.toStringAsFixed(3).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    return '$integerPart,$decimalPart $currencySymbol';
  }
}
