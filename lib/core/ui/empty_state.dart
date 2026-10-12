/// ============================================================================
/// RÔLE DU FICHIER :
/// Composant d'état d'interface affiché lorsqu'une liste est vide (`EmptyState`).
/// Il présente une icône thémée chaleureuse, un titre explicatif, un sous-titre
/// réconfortant et un bouton d'action contextuel (ex: "Découvrir les produits").
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/ui/` (Composant d'État Vide).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par :
///   * `CartScreen` (quand le panier ne contient aucun article).
///   * `FavoritesScreen` (quand le client n'a pas encore ajouté de favoris).
///   * `ProductGrid` et `SearchScreen` (en l'absence de résultats de recherche).
/// - Dépend de : `core/theme/app_colors.dart` et `core/theme/app_dimens.dart`.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Vue centrée et soignée pour les états sans données.
class EmptyState extends StatelessWidget {
  /// Icône vectorielle représentative (ex: panier vide, cœur vide, recherche sans résultat).
  final IconData icon;

  /// Titre principal en gras.
  final String title;

  /// Explication pédagogique pour guider l'utilisateur vers une action.
  final String message;

  /// Texte du bouton d'action principal optionnel.
  final String? buttonText;

  /// Action exécutée lors de l'appui sur le bouton.
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space32,
          vertical: AppDimens.space40,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Cercle d'illustration coloré avec icône ---
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimens.space24),

            // --- Titre de l'état vide ---
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppDimens.space8),

            // --- Message explicatif ---
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),

            // --- Bouton de relance optionnel ---
            if (buttonText != null && onAction != null) ...[
              const SizedBox(height: AppDimens.space24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
