import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_summary.dart';
import '../repositories/auth_repository.dart';

/// ============================================================
///  SOUKNA — AUTHENTIFICATION FICTIVE (MOCK)
///  Compte de démonstration : demo@soukna.com / Demo1234
///  Compte de test d'échec  : fail@soukna.com / n'importe quel mdp
/// ============================================================
class MockAuthRepository implements AuthRepository {
  final Duration latency;

  MockAuthRepository({this.latency = const Duration(milliseconds: 800)});

  @override
  Future<UserSummary> login(String email, String password) async {
    await Future.delayed(latency);

    final normalizedEmail = email.trim().toLowerCase();

    // Cas de test d'échec
    if (normalizedEmail == 'fail@soukna.com') {
      throw Exception('Compte temporairement bloqué ou identifiants erronés.');
    }

    // Compte de démonstration officiel
    if (normalizedEmail == 'demo@soukna.com' && password == 'Demo1234') {
      return const UserSummary(
        fullName: 'Amine Ben Salem',
        email: 'demo@soukna.com',
      );
    }

    // Autoriser aussi toute connexion avec un mot de passe valide (min 6 caractères) pour la souplesse du test
    if (password.length >= 6 && !password.contains('wrong')) {
      final namePart = normalizedEmail.split('@').first;
      final capitalized =
          namePart.isEmpty ? 'Client Soukna' : namePart[0].toUpperCase() + namePart.substring(1);
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
    if (normalizedEmail == 'fail@soukna.com') {
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
    // Retourne toujours un succès neutre pour la sécurité
  }
}

/// Provider pour injecter le repository d'authentification
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});
