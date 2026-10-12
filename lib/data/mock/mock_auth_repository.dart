/// ============================================================================
/// RÔLE DU FICHIER :
/// Implémentation simulée du service d'authentification (`MockAuthRepository`).
/// Fournit des comptes de test fonctionnels et simule une latence réseau de 800 ms.
///
/// DONNÉES ET IDENTIFIANTS DE TEST :
/// - Compte Démo Valide : `demo@Dokan.com` / `Demo1234` (Connecte "Amine Ben Salem").
/// - Compte de Test d'Échec : `fail@Dokan.com` / n'importe quel mot de passe (Lève une Exception).
/// - Tout autre compte avec mot de passe >= 6 caractères : autorisé avec nom dérivé de l'email.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `data/mock/` (Source de Données Simulée).
///
/// RELATIONS ET DÉPENDANCES :
/// - Injecté par : `authRepositoryProvider`.
/// - Consommé par : `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen`.
/// - Dépend de : `data/repositories/auth_repository.dart` et `data/models/user_summary.dart`.
/// ============================================================================
// DONNÉES FICTIVES
// TODO API : Remplacer par ApiAuthRepository lors de l'intégration avec le serveur distant.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_summary.dart';
import '../repositories/auth_repository.dart';

/// Implémentation de test du repository d'authentification.
class MockAuthRepository implements AuthRepository {
  /// Délai artificiel simulant la transmission réseau vers le serveur.
  final Duration latency;

  MockAuthRepository({this.latency = const Duration(milliseconds: 800)});

  @override
  Future<UserSummary> login(String email, String password) async {
    // Simulation du temps de réponse réseau
    await Future.delayed(latency);

    final normalizedEmail = email.trim().toLowerCase();

    // Cas d'école de simulation d'erreur pour vérifier le message d'alerte UI
    if (normalizedEmail == 'fail@Dokan.com') {
      throw Exception('Compte temporairement bloqué ou identifiants erronés.');
    }

    // Compte officiel de démonstration
    if (normalizedEmail == 'demo@Dokan.com' && password == 'Demo1234') {
      return const UserSummary(
        fullName: 'Amine Ben Salem',
        email: 'demo@Dokan.com',
      );
    }

    // Souplesse pour les tests libres d'étudiants (mot de passe d'au moins 6 caractères)
    if (password.length >= 6 && !password.contains('wrong')) {
      final namePart = normalizedEmail.split('@').first;
      final capitalized =
          namePart.isEmpty ? 'Client Dokan' : namePart[0].toUpperCase() + namePart.substring(1);
      return UserSummary(
        fullName: capitalized,
        email: normalizedEmail,
      );
    }

    throw Exception('Identifiants incorrects. Veuillez vérifier votre adresse e-mail et mot de passe.');
  }

  @override
  Future<UserSummary> register(String fullName, String email, String password) async {
    await Future.delayed(latency);

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail == 'fail@Dokan.com') {
      throw Exception('Cette adresse e-mail est déjà associée à un compte.');
    }

    return UserSummary(
      fullName: fullName.trim(),
      email: normalizedEmail,
    );
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(latency);
    // Retourne toujours un succès neutre pour la sécurité (évite la divulgation d'emails)
  }
}

/// Provider d'injection du service d'authentification.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});
