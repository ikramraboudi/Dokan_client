/// ============================================================================
/// RÔLE DU FICHIER :
/// Modèle de données immuable représentant l'identité sommaire d'un client connecté.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `data/models/` (Modèle Métier / Utilisateur).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par :
///   * `lib/core/session/session_provider.dart` (stocké dans `SessionState`).
///   * `lib/feature/profile/profile_screen.dart` (affichage du nom et email).
///   * `lib/data/repositories/auth_repository.dart` (retourné par login/register).
/// - Dépend de : Dart pur.
/// ============================================================================
library;

/// Représentation des informations de base du compte client.
class UserSummary {
  /// Nom et prénom du client (ex: "Amine Ben Salem").
  final String fullName;

  /// Adresse e-mail du compte client (ex: "demo@Dokan.com").
  final String email;

  const UserSummary({
    required this.fullName,
    required this.email,
  });

  // MOT TECHNIQUE - Surcharge operator == et hashCode :
  // Permet de comparer deux instances de UserSummary par leur contenu
  // (valeur) plutôt que par leur adresse mémoire physique.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSummary &&
          runtimeType == other.runtimeType &&
          fullName == other.fullName &&
          email == other.email;

  @override
  int get hashCode => fullName.hashCode ^ email.hashCode;
}
