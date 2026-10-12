/// ============================================================================
/// RÔLE DU FICHIER :
/// Interface abstraite définissant le contrat technique du service d'authentification.
///
/// PATTERN ARCHITECTURAL :
/// Repository Pattern (Inversion de Dépendance).
/// Définit "CE QUE" l'application peut faire sans préciser "COMMENT" c'est fait
/// (actuellement simulé par `MockAuthRepository`, plus tard relié à l'API backend).
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `data/repositories/` (Contrats Abstraits).
///
/// RELATIONS ET DÉPENDANCES :
/// - Implémenté par : `lib/data/mock/mock_auth_repository.dart`
///   (et prochainement par `lib/data/repositories/api_auth_repository.dart`).
/// - Dépend de : `data/models/user_summary.dart`.
/// ============================================================================
library;

import '../models/user_summary.dart';

/// Contrat d'authentification et de gestion de compte Dokan.
abstract class AuthRepository {
  /// Authentifie un utilisateur avec son email et mot de passe.
  Future<UserSummary> login(String email, String password);

  /// Inscrit un nouvel utilisateur et initialise son compte client.
  Future<UserSummary> register(String fullName, String email, String password);

  /// Envoie un e-mail contenant les instructions de réinitialisation de mot de passe.
  Future<void> sendPasswordReset(String email);
}
