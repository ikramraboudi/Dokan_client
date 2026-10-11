import '../models/user_summary.dart';

/// ============================================================
///  SOUKNA — INTERFACE DU REPOSITORY D'AUTHENTIFICATION
/// ============================================================
abstract class AuthRepository {
  /// Connexion utilisateur
  Future<UserSummary> login(String email, String password);

  /// Inscription d'un nouvel utilisateur
  Future<UserSummary> register(String fullName, String email, String password);

  /// Demande de réinitialisation de mot de passe
  Future<void> sendPasswordReset(String email);
}
