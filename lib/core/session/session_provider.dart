/// ============================================================================
/// RÔLE DU FICHIER :
/// Gestionnaire d'état de la session utilisateur (authentification et profil).
/// Il maintient la distinction fondamentale entre un Visiteur anonyme (`isGuest`)
/// et un Client authentifié (`isAuthenticated`). Il gère également le mécanisme
/// de reprise automatique d'une action protégée en attente (`pendingProtectedAction`).
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/session/` (Gestion d'État Transverse / Session).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par :
///   * `AuthRequiredDialog` pour mémoriser l'action en attente.
///   * `LoginScreen` et `RegisterScreen` pour valider la connexion.
///   * `ProfileScreen` pour afficher les données client ou la déconnexion.
///   * `FavoritesScreen` et `CartScreen` pour adapter leur comportement.
/// - Dépend de :
///   * `package:flutter_riverpod` pour `StateNotifier`.
///   * `data/models/user_summary.dart` pour le modèle de profil client.
/// ============================================================================
library;

import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_summary.dart';


/// ÉTAT IMMUABLE DE LA SESSION (SessionState)
///
/// MOT TECHNIQUE - Immutabilité :
/// Les propriétés d'un objet immuable ne peuvent pas être modifiées après création.
/// Toute modification produit une nouvelle instance via la méthode `copyWith`.

class SessionState {
  /// Profil de l'utilisateur connecté, ou `null` si la personne est un visiteur.
  final UserSummary? user;

  /// Indique si une requête de connexion ou déconnexion est en cours.
  final bool isLoading;

  /// Message d'erreur éventuel survenu lors d'une tentative d'authentification.
  final String? authError;

  /// Action protégée mise en mémoire lorsqu'un visiteur a tenté une action restreinte
  /// (ex: ajouter un article précis aux favoris avant de se connecter).
  final VoidCallback? pendingProtectedAction;

  const SessionState({
    this.user,
    this.isLoading = false,
    this.authError,
    this.pendingProtectedAction,
  });

  /// Indique si l'utilisateur est un simple visiteur non connecté.
  bool get isGuest => user == null;

  /// Indique si l'utilisateur est un client formellement authentifié.
  bool get isAuthenticated => user != null;

  /// MOT TECHNIQUE - copyWith :
  /// Produit une nouvelle copie de l'état en remplaçant uniquement les valeurs fournies.
  SessionState copyWith({
    UserSummary? Function()? user,
    bool? isLoading,
    String? Function()? authError,
    VoidCallback? Function()? pendingProtectedAction,
  }) {
    return SessionState(
      user: user != null ? user() : this.user,
      isLoading: isLoading ?? this.isLoading,
      authError: authError != null ? authError() : this.authError,
      pendingProtectedAction: pendingProtectedAction != null
          ? pendingProtectedAction()
          : this.pendingProtectedAction,
    );
  }
}


/// NOTIFIER DE SESSION (SessionNotifier)
///
/// MOT TECHNIQUE - StateNotifier :
/// Classe Riverpod propriétaire de la variable `state`. Elle expose des méthodes
/// pour modifier l'état de façon contrôlée et notifier tous les widgets écouteurs.

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(const SessionState());


  /// SCÉNARIO MÉTIER : CONNEXION RÉUSSIE ET REPRISE D'ACTION
  /// 1) L'utilisateur valide ses identifiants avec succès.
  /// 2) Le profil `user` est enregistré dans l'état de session.
  /// 3) Si une action protégée était en attente (ex: ajout de favori initié en mode invité),
  ///    cette action est exécutée immédiatement UNE SEULE FOIS.
  /// 4) `pendingProtectedAction` est remis à null pour empêcher tout double déclenchement.

  void loginSuccess(UserSummary user) {
    final pending = state.pendingProtectedAction;
    state = state.copyWith(
      user: () => user,
      isLoading: false,
      authError: () => null,
      pendingProtectedAction: () => null,
    );

    // Reprise sécurisée de l'action protégée sans doublon
    if (pending != null) {
      pending();
    }
  }

  /// Déconnexion du client : réinitialise la session à l'état visiteur anonyme.
  void logout() {
    state = const SessionState();
  }

  /// Mémorise une action protégée lorsqu'un visiteur clique sur une fonctionnalité restreinte.
  void setPendingAction(VoidCallback? action) {
    state = state.copyWith(pendingProtectedAction: () => action);
  }

  /// Active ou désactive le spinner de chargement lors de l'authentification.
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Enregistre un message d'erreur d'authentification.
  void setAuthError(String? error) {
    state = state.copyWith(authError: () => error);
  }


  /// SCÉNARIO DE TEST : SIMULATION DE SESSION EXPIRÉE
  /// Permet de tester le comportement de l'application lorsque le jeton expire :
  /// le client repasse en mode visiteur avec un message d'avertissement,
  /// MAIS le contenu de son panier d'achat reste préservé en mémoire !
  
  void simulateSessionExpired() {
    state = state.copyWith(
      user: () => null,
      authError: () => 'Votre session a expiré. Connectez-vous pour continuer.',
    );
  }
}

/// Provider global de session accessible via `ref.watch(sessionProvider)`.
final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier();
});
