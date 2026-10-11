/// ============================================================
///  SOUKNA — CONFIGURATION DE L'APPLICATION
/// ============================================================
class AppConfig {
  AppConfig._();

  static const String appName = 'Soukna';

  // --- Durée du splash screen ---
  static const Duration splashDuration = Duration(seconds: 3);

  // --- Monnaie et devise ---
  static const String currencyCode = 'TND';
  static const String currencySymbol = 'DT';

  /// Fonction unique utilisée partout dans l'application pour formater un prix.
  /// Exemple : 49.9 -> "49,900 DT"
  static String formatPrice(double price) {
    // 3 décimales pour le dinar tunisien
    final parts = price.toStringAsFixed(3).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    return '$integerPart,$decimalPart $currencySymbol';
  }
}
