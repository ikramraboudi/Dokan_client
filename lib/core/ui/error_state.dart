/// ============================================================================
/// RÔLE DU FICHIER :
/// Composant d'état d'erreur réseau ou logique (`ErrorState`).
/// Il affiche une icône d'alerte thémée, un message explicatif bienveillant
/// et un bouton avec icône pour permettre à l'utilisateur de réexécuter la requête.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/ui/` (Composant d'État d'Erreur).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par :
///   * `HomeScreen` (échec de chargement des sections).
///   * `CatalogScreen` (erreur de recherche ou filtre).
///   * `CategoriesScreen` et `FavoritesScreen`.
/// - Dépend de : `core/theme/app_colors.dart` et `core/theme/app_dimens.dart`.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Vue d'erreur avec bouton « Réessayer ».
class ErrorState extends StatelessWidget {
  /// Message d'erreur personnalisé ou message par défaut en français.
  final String? message;

  /// Fonction de rappel exécutée pour retenter l'opération échouée.
  final VoidCallback? onRetry;

  /// Libellé du bouton de réessai.
  final String retryButtonText;

  const ErrorState({
    super.key,
    this.message,
    this.onRetry,
    this.retryButtonText = 'Réessayer',
  });

  @override
  Widget build(BuildContext context) {
    final displayMessage = message ??
        'Impossible de charger ces informations. Vérifiez votre connexion puis réessayez.';

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
            // --- Cercle teinté rouge d'alerte avec icône hors-ligne ---
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.errorSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimens.space24),

            // --- Titre explicatif d'erreur ---
            Text(
              'Oups ! Une erreur est survenue',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppDimens.space8),

            // --- Description de la panne ---
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),

            // --- Bouton d'action pour retenter le chargement ---
            if (onRetry != null) ...[
              const SizedBox(height: AppDimens.space24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryButtonText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
