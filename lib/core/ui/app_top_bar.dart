/// ============================================================================
/// RÔLE DU FICHIER :
/// Barre d'application supérieure personnalisée (`AppTopBar`) respectant le thème Dokan.
/// Elle standardise l'en-tête de tous les écrans en offrant un affichage adaptatif :
/// soit le logo boutique officiel ("Dokan"), soit un titre textuel avec bouton retour.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/ui/` (Composant Graphique Réutilisable).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : Pratiquement tous les écrans (`HomeScreen`, `CatalogScreen`,
///   `CartScreen`, `FavoritesScreen`, `ProfileScreen`, `LoginScreen`...).
/// - Dépend de :
///   * `core/config/app_config.dart` pour le nom de l'application.
///   * `core/theme/app_colors.dart` et `core/theme/app_dimens.dart`.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Barre d'application réutilisable implémentant PreferredSizeWidget.
///
/// MOT TECHNIQUE - PreferredSizeWidget :
/// Interface Flutter obligatoire pour tout widget placé dans la propriété `appBar`
/// d'un `Scaffold`. Elle permet au Scaffold de connaître la hauteur exacte requise.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Titre textuel optionnel affiché au centre de la barre.
  final String? title;

  /// Si vrai, affiche le logo boutique officiel Dokan plutôt qu'un simple texte.
  final bool showLogo;

  /// Si vrai, affiche une flèche de retour arrière discrète à gauche.
  final bool showBackButton;

  /// Action personnalisée exécutée lors d'un clic sur le bouton retour.
  final VoidCallback? onBackPressed;

  /// Liste de widgets d'actions positionnés à droite (ex: icône panier, bouton vider).
  final List<Widget>? actions;

  /// Widget optionnel positionné sous la barre (ex: onglets TabBar).
  final PreferredSizeWidget? bottom;

  const AppTopBar({
    super.key,
    this.title,
    this.showLogo = false,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    // --- Widget du bouton retour (Leading) ---
    Widget? leadingWidget;
    if (showBackButton) {
      // MOT TECHNIQUE - Semantics :
      // Annote le bouton pour les personnes utilisant un lecteur d'écran (TalkBack).
      leadingWidget = Semantics(
        label: 'Retour à l\'écran précédent',
        button: true,
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          tooltip: 'Retour',
          onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
        ),
      );
    }

    // --- Widget de Titre (Logo ou Texte) ---
    Widget? titleWidget;
    if (showLogo) {
      titleWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.space4),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppDimens.radius8),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimens.space8),
          const Text(
            AppConfig.appName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      );
    } else if (title != null) {
      titleWidget = Text(
        title!,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
            ),
      );
    }

    // --- Rendu de l'AppBar Material 3 ---
    return AppBar(
      title: titleWidget,
      leading: leadingWidget,
      centerTitle: !showLogo,
      actions: actions,
      bottom: bottom,
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
    );
  }
}
