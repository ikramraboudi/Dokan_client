/// ============================================================================
/// RÔLE DU FICHIER :
/// Constantes de dimensions, espacements, arrondis et contraintes d'ergonomie
/// de l'application mobile Dokan.
///
/// OBJECTIF :
/// Harmoniser les marges et les formes géométriques pour garantir une cohérence
/// visuelle stricte entre tous les écrans et respecter les normes d'accessibilité.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/theme/` (Design System / Métriques).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : L'ensemble des composants `core/ui/` et des écrans `feature/`.
/// - Dépend de : Dart pur (aucun package externe).
/// ============================================================================
library;

class AppDimens {
  /// Constructeur privé pour empêcher l'instanciation.
  AppDimens._();

  // --- Espacements harmonisés (Grille basée sur un multiple de 4 dp) ---
  static const double space4  = 4.0;
  static const double space8  = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0; // Espacement standard par défaut des paddings
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;

  // --- Rayons de bordure (Coins arrondis généreux et modernes) ---
  static const double radius8    = 8.0;
  static const double radius12   = 12.0;
  static const double radius14   = 14.0; // Arrondi spécifique des boutons principaux
  static const double radius16   = 16.0; // Arrondi standard des cartes de produits
  static const double radius20   = 20.0; // Arrondi des boîtes de dialogue
  static const double radius24   = 24.0; // Arrondi des feuilles modales glissantes
  static const double radiusFull = 999.0; // Cercle parfait ou pilule (badges, indicateurs)

  // --- Accessibilité & zones tactiles (Standards Google Material 3) ---
  /// Zone tactile minimale recommandée de 48 dp pour faciliter l'appui au doigt.
  static const double minTouchTarget = 48.0;

  /// Hauteur confortable des boutons d'action principaux (52 dp).
  static const double buttonHeight = 52.0;

  // --- Durées d'animation fluides ---
  static const Duration animFast   = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 300);
  static const Duration animSlow   = Duration(milliseconds: 500);
}
