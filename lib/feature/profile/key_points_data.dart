/// ============================================================================
/// RÔLE DU FICHIER : Données interactives synthétiques pour les Conditions d'utilisation
/// et la Politique de confidentialité (format cartes courtes « points clés »).
/// Texte provisoire à faire valider par Dokan.
/// INTERAGIT AVEC : legal_screen.dart, app_colors.dart.
/// ============================================================================
library;

/// Modèle d'un point clé juridique interactif.
class KeyPointItem {
  final String emoji;
  final String title;
  final String sentence;
  final int colorIndex;

  const KeyPointItem({
    required this.emoji,
    required this.title,
    required this.sentence,
    required this.colorIndex,
  });
}

/// Modèle regroupant les points clés d'une section légale complète.
class LegalKeyPointsSection {
  final String title;
  final String headerEmoji;
  final List<KeyPointItem> points;

  const LegalKeyPointsSection({
    required this.title,
    required this.headerEmoji,
    required this.points,
  });
}

/// Données des Conditions d'utilisation (Texte provisoire à faire valider par Dokan).
const LegalKeyPointsSection termsOfUseSection = LegalKeyPointsSection(
  title: 'Conditions d\'utilisation',
  headerEmoji: '📜',
  points: [
    KeyPointItem(
      emoji: '👤',
      title: 'Votre compte',
      sentence: 'Un compte par client, avec des informations exactes.',
      colorIndex: 0,
    ),
    KeyPointItem(
      emoji: '🛍️',
      title: 'Vos commandes',
      sentence: 'Elles sont confirmées par l\'équipe Dokan.',
      colorIndex: 1,
    ),
    KeyPointItem(
      emoji: '💵',
      title: 'Le paiement',
      sentence: 'Vous payez en espèces à la réception.',
      colorIndex: 2,
    ),
    KeyPointItem(
      emoji: '🚚',
      title: 'La livraison',
      sentence: 'Soyez joignable à l\'adresse indiquée.',
      colorIndex: 3,
    ),
    KeyPointItem(
      emoji: '❌',
      title: 'L\'annulation',
      sentence: 'Possible tant que la commande est « En attente ».',
      colorIndex: 4,
    ),
    KeyPointItem(
      emoji: '🔑',
      title: 'Votre mot de passe',
      sentence: 'Gardez-le secret, vous en êtes responsable.',
      colorIndex: 5,
    ),
  ],
);

/// Données de la Politique de confidentialité (Texte provisoire à faire valider par Dokan).
const LegalKeyPointsSection privacyPolicySection = LegalKeyPointsSection(
  title: 'Confidentialité',
  headerEmoji: '🔒',
  points: [
    KeyPointItem(
      emoji: '📋',
      title: 'Ce que nous collectons',
      sentence: 'Votre nom, e-mail, téléphone et adresses.',
      colorIndex: 0,
    ),
    KeyPointItem(
      emoji: '🎯',
      title: 'Pourquoi',
      sentence: 'Uniquement pour traiter et livrer vos commandes.',
      colorIndex: 1,
    ),
    KeyPointItem(
      emoji: '☁️',
      title: 'Où c\'est stocké',
      sentence: 'De façon sécurisée, avec Firebase.',
      colorIndex: 2,
    ),
    KeyPointItem(
      emoji: '🤝',
      title: 'Le partage',
      sentence: 'Le livreur reçoit seulement ce qui sert à la livraison.',
      colorIndex: 3,
    ),
    KeyPointItem(
      emoji: '✏️',
      title: 'Vos droits',
      sentence: 'Modifiez vos informations depuis votre profil.',
      colorIndex: 4,
    ),
    KeyPointItem(
      emoji: '📩',
      title: 'Une question ?',
      sentence: 'Contactez-nous depuis Paramètres et aide.',
      colorIndex: 5,
    ),
  ],
);
