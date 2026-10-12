/// ============================================================================
/// RÔLE DU FICHIER :
/// Construction du thème global `ThemeData` (clair uniquement) pour Material 3.
/// Ce fichier applique les règles du système de design à tous les widgets de base
/// de Flutter (boutons, champs, barre d'onglets, cartes, dialogues) en consommant
/// EXCLUSIVEMENT les constantes de `AppColors` et `AppDimens`.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/theme/` (Design System / ThemeData).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : `lib/app.dart` qui l'injecte dans `MaterialApp.router`.
/// - Dépend de :
///   * `app_colors.dart` pour toutes les couleurs.
///   * `app_dimens.dart` pour les tailles et rayons d'arrondis.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimens.dart';

/// Fabrique du thème Material 3 de l'application Dokan.
class AppTheme {
  AppTheme._();


  /// FONCTIONNALITÉ :
  /// Génère l'instance complète de `ThemeData` configurée pour le mode clair.
  ///
  /// CHOIX TECHNIQUE :
  /// En configurant globalement les sous-thèmes (`elevatedButtonTheme`, `cardTheme`,
  /// `inputDecorationTheme`), les développeurs n'ont plus besoin de redéfinir
  /// la couleur de fond, la hauteur ou l'arrondi de chaque bouton individuel dans
  /// leurs écrans : un simple `ElevatedButton(...)` adoptera immédiatement l'aspect
  /// officiel de la marque Dokan.

  static ThemeData get lightTheme {
    // MOT TECHNIQUE - ColorScheme :
    // La palette sémantique Material 3 associant des rôles visuels précis
    // (primary = action principale, surface = fond de carte, error = alerte...).
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      secondaryContainer: AppColors.accentSoft,
      onSecondaryContainer: AppColors.onAccent,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceAlt,
      error: AppColors.error,
      onError: AppColors.textOnDark,
      errorContainer: AppColors.errorSoft,
      onErrorContainer: AppColors.error,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
      shadow: AppColors.shadow,
      scrim: AppColors.overlay,
    );

    // MOT TECHNIQUE - TextTheme :
    // La hiérarchie typographique (titres de rubriques, corps de texte, légendes).
    const textTheme = TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.35,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textHint,
      ),
    );

    return ThemeData(
      // Active les composants et les spécifications visuelles Material 3
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,

      // --- Barre supérieure (AppBar) ---
      // Fond blanc uni sans ombre agressive, titre centré et texte contrasté
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        surfaceTintColor: AppColors.surface,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),

      // --- Bouton Principal Plein (ElevatedButton) ---
      // Hauteur standardisée de 52 dp, coins arrondis à 14 dp et désactivation gérée
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textHint,
          minimumSize: const Size.fromHeight(AppDimens.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radius14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // --- Bouton Secondaire Contour (OutlinedButton) ---
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(AppDimens.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radius14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // --- Bouton Lien Texte (TextButton) ---
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radius8),
          ),
        ),
      ),

      // --- Champs de formulaire (InputDecoration) ---
      // Bords arrondis, fond blanc, bordure d'accentuation teal en cas de focus
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space16,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radius12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radius12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radius12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radius12),
          borderSide: const BorderSide(color: AppColors.error, width: 2.0),
        ),
        errorStyle: const TextStyle(
          color: AppColors.error,
          fontSize: 12,
        ),
      ),

      // --- Cartes de présentation (CardThemeData) ---
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radius16),
          side: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),

      // --- Puces et pastilles (ChipThemeData) ---
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.primarySoft,
        disabledColor: AppColors.surfaceAlt,
        side: const BorderSide(color: AppColors.border, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radius20),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space12,
          vertical: AppDimens.space8,
        ),
      ),

      // --- Barre de navigation inférieure (NavigationBarThemeData) ---
      // MOT TECHNIQUE - WidgetStateProperty :
      // Définit le style dynamique selon l'état de l'onglet (sélectionné ou non).
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        surfaceTintColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.textSecondary, size: 24);
        }),
      ),

      // --- Notifications temporaires (SnackBar) ---
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: AppColors.textOnDark,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radius12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // --- Feuilles modales surgissant du bas (BottomSheetThemeData) ---
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radius24),
          ),
        ),
      ),

      // --- Boîtes de dialogue modales (DialogThemeData) ---
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radius20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),

      // --- Séparateurs de liste (DividerThemeData) ---
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
