/// ============================================================================
/// RÔLE DU FICHIER :
/// Bibliothèque de validateurs réutilisables pour les formulaires de l'application
/// (connexion, inscription, mot de passe oublié).
///
/// OBJECTIF :
/// Fournir des règles de vérification de saisie cohérentes et des messages d'erreur
/// explicites en français répondant aux standards `FormFieldValidator<String>` de Flutter.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/utils/` (Utilitaires & Validation).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par :
///   * `lib/feature/auth/login_screen.dart`
///   * `lib/feature/auth/register_screen.dart`
///   * `lib/feature/auth/forgot_password_screen.dart`
/// - Dépend de : Dart pur (expressions régulières RegExp).
/// ============================================================================
library;

/// Classe utilitaire contenant les fonctions de validation de chaînes.
class Validators {
  Validators._();

  /// FONCTIONNALITÉ :
  /// Vérifie qu'un champ textuel n'est ni nul ni constitué uniquement d'espaces blancs.
  ///
  /// PARAMÈTRES :
  /// - [value] : Texte saisi par l'utilisateur.
  /// - [message] : Message d'erreur optionnel personnalisé.
  ///
  /// RETOURNE :
  /// `null` si le champ est valide, ou le message d'erreur sinon.

  static String? required(String? value, [String message = 'Ce champ est obligatoire']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  /// FONCTIONNALITÉ :
  /// Valide le format d'une adresse de courrier électronique via expression régulière.
  ///
  /// RÈGLES :
  /// Doit contenir des caractères valides, un arobase `@`, un nom de domaine et
  /// une extension de 2 à 4 lettres (ex: nom@domaine.com).

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez renseigner votre adresse e-mail';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Veuillez saisir une adresse e-mail valide';
    }
    return null;
  }

  /// FONCTIONNALITÉ :
  /// Vérifie qu'un mot de passe respecte la longueur minimale de sécurité (6 caractères).

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez renseigner votre mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit comporter au moins 6 caractères';
    }
    return null;
  }

  /// FONCTIONNALITÉ :
  /// Vérifie que le mot de passe de confirmation correspond fidèlement au mot de passe saisi.

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }
  
  /// FONCTIONNALITÉ :
  /// Valide la saisie d'un nom complet (au moins 3 caractères).

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez renseigner votre nom complet';
    }
    if (value.trim().length < 3) {
      return 'Le nom doit comporter au moins 3 caractères';
    }
    return null;
  }
}
