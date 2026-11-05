/// ============================================================================
/// RÔLE DU FICHIER : Données des Questions Fréquentes (FAQ) de Dokan.
/// Chaque question dispose de son propre emoji, d'une réponse en une seule phrase courte,
/// et d'un index de couleur pastel dédié (0 à 7).
/// INTERAGIT AVEC : faq_screen.dart, app_colors.dart.
/// ============================================================================
library;

/// Modèle immuable d'un élément de FAQ.
class FaqItem {
  final String emoji;
  final String question;
  final String answer;
  final int colorIndex;

  const FaqItem({
    required this.emoji,
    required this.question,
    required this.answer,
    required this.colorIndex,
  });
}

/// Liste centralisée des 8 questions/réponses de la FAQ Dokan.
const List<FaqItem> dokanFaqItems = [
  FaqItem(
    emoji: '🛍️',
    question: 'Comment commander ?',
    answer: 'Ajoutez au panier, puis touchez « Continuer la commande ».',
    colorIndex: 0,
  ),
  FaqItem(
    emoji: '📍',
    question: 'Comment ajouter une adresse ?',
    answer: 'Profil › Mes adresses › Ajouter.',
    colorIndex: 1,
  ),
  FaqItem(
    emoji: '🚚',
    question: 'Et la livraison ?',
    answer: 'Elle se fait à votre adresse, les détails sont affichés avant de confirmer.',
    colorIndex: 2,
  ),
  FaqItem(
    emoji: '💵',
    question: 'Comment payer ?',
    answer: 'En espèces, à la réception de votre commande.',
    colorIndex: 3,
  ),
  FaqItem(
    emoji: '📦',
    question: 'Où est ma commande ?',
    answer: 'Profil › Mes commandes : le suivi se met à jour en direct.',
    colorIndex: 4,
  ),
  FaqItem(
    emoji: '❌',
    question: 'Puis-je annuler ?',
    answer: 'Oui, tant que la commande est « En attente ».',
    colorIndex: 5,
  ),
  FaqItem(
    emoji: '🔑',
    question: 'Mot de passe oublié ?',
    answer: 'Touchez « Mot de passe oublié » sur l\'écran de connexion.',
    colorIndex: 6,
  ),
  FaqItem(
    emoji: '✏️',
    question: 'Modifier mon profil ?',
    answer: 'Profil › Modifier le profil.',
    colorIndex: 7,
  ),
];
