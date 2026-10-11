/// ============================================================
///  SOUKNA — ROUTES DE L'APPLICATION
/// ============================================================
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/home';
  static const String categories = '/categories';
  static const String favorites = '/favorites';
  static const String cart = '/cart';
  static const String profile = '/profile';

  // Routes poussées par-dessus le shell ou dans les branches
  static const String catalog = '/catalog';
  static const String search = '/search';
  static const String productDetail = '/product/:id';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static String productDetailPath(String id) => '/product/$id';
}
