import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_summary.dart';

/// ============================================================
///  SOUKNA — ÉTAT DE SESSION (VISITEUR VS CLIENT CONNECTÉ)
/// ============================================================
class SessionState {
  final UserSummary? user;
  final bool isLoading;
  final String? authError;
  final VoidCallback? pendingProtectedAction;

  const SessionState({
    this.user,
    this.isLoading = false,
    this.authError,
    this.pendingProtectedAction,
  });

  bool get isGuest => user == null;
  bool get isAuthenticated => user != null;

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

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(const SessionState());

  /// Bascule en mode client connecté
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

  /// Déconnexion : nettoie les informations personnelles et bascule en visiteur
  void logout() {
    state = const SessionState();
  }

  /// Définit une action protégée à exécuter après connexion réussie
  void setPendingAction(VoidCallback? action) {
    state = state.copyWith(pendingProtectedAction: () => action);
  }

  /// Déclenche l'état de chargement
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Enregistre une erreur d'authentification
  void setAuthError(String? error) {
    state = state.copyWith(authError: () => error);
  }

  /// Simulation d'une session expirée sans perte du panier
  void simulateSessionExpired() {
    state = state.copyWith(
      user: () => null,
      authError: () => 'Votre session a expiré. Connectez-vous pour continuer.',
    );
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier();
});
