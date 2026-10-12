/// ============================================================================
/// RÔLE DU FICHIER :
/// Feuille modale / Dialogue d'invitation à l'authentification (`AuthRequiredDialog`).
/// Affiché chaque fois qu'un visiteur non connecté tente d'exécuter une action
/// réservée aux clients (ex: ajouter un favori, finaliser une commande).
///
/// COMPORTEMENTS CLÉS :
/// 1) Mémorise l'action souhaitée via `pendingAction` pour la rejouer après connexion.
/// 2) Empêche l'empilement multiple de dialogues grâce à un verrou statique `_isShowing`.
/// 3) Offre des boutons distincts : "Se connecter", "Créer un compte", "Continuer la visite".
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/ui/` (Dialogue Modal d'Autorisation).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par :
///   * `HomeScreen`, `CatalogScreen`, `SearchScreen`, `ProductDetailScreen` (clic favori visiteur).
///   * `CartScreen` (clic bouton commander pour un visiteur).
/// - Dépend de :
///   * `core/session/session_provider.dart` pour enregistrer l'action en attente.
///   * `core/navigation/routes.dart` pour la redirection vers `/login` ou `/register`.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../navigation/routes.dart';
import '../session/session_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Dialogue modal surgissant invitant le visiteur à s'authentifier.
class AuthRequiredDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onContinueVisiting;

  const AuthRequiredDialog({
    super.key,
    required this.title,
    required this.message,
    this.onContinueVisiting,
  });

  /// Verrou de sécurité empêchant l'ouverture simultanée de plusieurs dialogues
  /// si l'utilisateur appuie de manière répétée et frénétique.
  static bool _isShowing = false;

  /// FONCTIONNALITÉ STATIQUE : AFFICHER LA MODALE
  ///
  /// PARAMÈTRES :
  /// - [context] : Contexte de navigation.
  /// - [ref] : Référence Riverpod pour enregistrer l'action protégée.
  /// - [title] : Titre du dialogue (par défaut "Connexion requise").
  /// - [message] : Raison claire expliquant pourquoi l'authentification est nécessaire.
  /// - [pendingAction] : Fonction de rappel à exécuter automatiquement après connexion.
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    String title = 'Connexion requise',
    required String message,
    VoidCallback? pendingAction,
  }) async {
    // Si un dialogue est déjà ouvert, ignore la nouvelle demande (anti-cumul)
    if (_isShowing) return;
    _isShowing = true;

    // Enregistre l'action souhaitée dans le SessionNotifier
    if (pendingAction != null) {
      ref.read(sessionProvider.notifier).setPendingAction(pendingAction);
    }

    try {
      // MOT TECHNIQUE - showModalBottomSheet :
      // Ouvre une feuille modale glissant depuis le bas de l'écran avec coins supérieurs arrondis.
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => AuthRequiredDialog(
          title: title,
          message: message,
          onContinueVisiting: () => Navigator.of(ctx).pop(),
        ),
      );
    } finally {
      // Libère le verrou lors de la fermeture de la feuille
      _isShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space24,
          vertical: AppDimens.space20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Barre de préhension supérieure (Handle) ---
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space20),

            // --- Icône de cadenas teinté dans un cercle ---
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // --- Titre ---
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
            const SizedBox(height: AppDimens.space24),

            // --- Bouton d'action principal : Se connecter ---
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.login);
              },
              child: const Text('Se connecter'),
            ),
            const SizedBox(height: AppDimens.space12),

            // --- Bouton secondaire : Créer un compte ---
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.register);
              },
              child: const Text('Créer un compte'),
            ),
            const SizedBox(height: AppDimens.space8),

            // --- Action neutre : Poursuivre en tant que simple visiteur ---
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onContinueVisiting?.call();
              },
              child: const Text(
                'Continuer la visite',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
