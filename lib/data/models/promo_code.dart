/// ============================================================================
/// RÔLE DU FICHIER :
/// Définition du modèle et du registre centralisé des codes promotionnels Dokan.
///
/// CENTRALISATION MÉTIER :
/// Ce fichier constitue l'UNIQUE source de vérité pour tous les codes promotionnels
/// acceptés par l'application cliente Dokan. Toute modification, ajout ou retrait
/// d'un code promo doit être effectuée exclusivement ici.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `data/models/` (Modèle de Données & Registre Métier).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : `lib/data/mock/mock_cart_repository.dart` et les tests unitaires.
/// ============================================================================
library;

/// Type de réduction accordée par un code promotionnel.
enum PromoDiscountType {
  /// Pourcentage déduit sur le sous-total brut (ex: 10 %).
  percentage,
}

/// Modèle immuable représentant une règle de code promotionnel.
class PromoCode {
  /// Code normalisé en majuscules utilisé pour la comparaison insensible à la casse.
  final String normalizedCode;

  /// Libellé canonique officiel affiché à l'utilisateur (ex: 'Dokan10').
  final String displayCode;

  /// Type de réduction appliquée.
  final PromoDiscountType discountType;

  /// Valeur numérique de la réduction (ex: 10.0 pour 10 %).
  final double discountValue;

  /// Description textuelle courte de l'avantage (ex: '-10 %').
  final String description;

  const PromoCode({
    required this.normalizedCode,
    required this.displayCode,
    required this.discountType,
    required this.discountValue,
    required this.description,
  });

  /// FONCTIONNALITÉ :
  /// Calcule le montant absolu de la remise en fonction du sous-total brut.
  ///
  /// PARAMÈTRES :
  /// - [subtotal] : Montant brut des articles en Dinars Tunisiens (DT).
  ///
  /// RETOURNE :
  /// Le montant de la réduction déduit en DT (0.0 si le sous-total est nul ou négatif).
  double calculateDiscount(double subtotal) {
    if (subtotal <= 0) return 0.0;
    switch (discountType) {
      case PromoDiscountType.percentage:
        return subtotal * (discountValue / 100.0);
    }
  }
}

// TODO Firebase : les codes promo seront gérés par l'Admin dans Firestore
class PromoRules {
  PromoRules._();

  /// Registre officiel et unique des codes promotionnels autorisés dans l'application.
  static const List<PromoCode> validPromoCodes = [
    PromoCode(
      normalizedCode: 'DOKAN10',
      displayCode: 'Dokan10',
      discountType: PromoDiscountType.percentage,
      discountValue: 10.0,
      description: '-10 %',
    ),
  ];

  /// FONCTIONNALITÉ :
  /// Recherche un code promotionnel avec normalisation complète :
  /// 1. Suppression des espaces superflus en début et fin (`trim()`).
  /// 2. Comparaison insensible à la casse (`toUpperCase()`).
  ///
  /// EXEMPLES :
  /// - `find("Dokan10")`  -> PromoCode(Dokan10, 10%)
  /// - `find("dokan10")`  -> PromoCode(Dokan10, 10%)
  /// - `find("DOKAN10")`  -> PromoCode(Dokan10, 10%)
  /// - `find(" Dokan10 ")`-> PromoCode(Dokan10, 10%)
  /// - `find("INCONNU")`  -> null
  /// - `find("")`         -> null
  static PromoCode? find(String rawInput) {
    final clean = rawInput.trim().toUpperCase();
    if (clean.isEmpty) return null;

    for (final promo in validPromoCodes) {
      if (promo.normalizedCode == clean) {
        return promo;
      }
    }
    return null;
  }
}
