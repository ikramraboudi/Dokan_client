/// ============================================================
///  SOUKNA — VALIDATEURS DE FORMULAIRES
/// ============================================================
class Validators {
  Validators._();

  static String? required(String? value, [String message = 'Ce champ est obligatoire']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

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

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez renseigner votre mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit comporter au moins 6 caractères';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

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
