/// ============================================================================
/// RÔLE DU FICHIER : Référentiel des régions et villes de Tunisie (Dokan).
/// Découpage logistique en 3 zones : 'nord', 'centre', 'sud'.
/// INTERAGIT AVEC : AddressUiModel, AddEditAddressScreen, CheckoutScreen, FirestoreOrdersRepository.
/// POUR L'ORAL : « TunisiaRegions classe automatiquement les 24 gouvernorats tunisiens en 3 zones
/// logistiques (nord, centre, sud) pour le dispatching des commandes. »
/// ============================================================================
library;

class TunisiaRegions {
  TunisiaRegions._();

  static const String nord = 'nord';
  static const String centre = 'centre';
  static const String sud = 'sud';

  /// Villes et gouvernorats officiels classés par région logistique
  static const Map<String, List<String>> regionCities = {
    nord: [
      'Tunis',
      'Ariana',
      'Ben Arous',
      'Manouba',
      'Nabeul',
      'Bizerte',
      'Zaghouan',
      'Béja',
      'Jendouba',
      'Le Kef',
      'Siliana',
    ],
    centre: [
      'Sousse',
      'Monastir',
      'Mahdia',
      'Sfax',
      'Kairouan',
      'Kasserine',
      'Sidi Bouzid',
    ],
    sud: [
      'Gabès',
      'Médenine',
      'Tataouine',
      'Gafsa',
      'Tozeur',
      'Kébili',
    ],
  };

  /// Liste complète des 24 gouvernorats tunisiens
  static const List<String> allCities = [
    'Tunis',
    'Ariana',
    'Ben Arous',
    'Manouba',
    'Nabeul',
    'Bizerte',
    'Zaghouan',
    'Béja',
    'Jendouba',
    'Le Kef',
    'Siliana',
    'Sousse',
    'Monastir',
    'Mahdia',
    'Sfax',
    'Kairouan',
    'Kasserine',
    'Sidi Bouzid',
    'Gabès',
    'Médenine',
    'Tataouine',
    'Gafsa',
    'Tozeur',
    'Kébili',
  ];

  /// Détermine automatiquement la région ('nord', 'centre', 'sud') à partir d'une ville.
  /// Fonctionne de manière tolérante aux majuscules, accents et sous-localités.
  static String getRegionId(String? city) {
    if (city == null || city.trim().isEmpty) {
      return nord;
    }

    final cleanInput = _clean(city);

    // 1. Recherche par correspondance exacte ou inclusion des villes officielles
    for (final entry in regionCities.entries) {
      for (final refCity in entry.value) {
        final cleanRef = _clean(refCity);
        if (cleanInput == cleanRef ||
            cleanInput.contains(cleanRef) ||
            cleanRef.contains(cleanInput)) {
          return entry.key;
        }
      }
    }

    // 2. Mots-clés géographiques courants
    if (cleanInput.contains('djerba') ||
        cleanInput.contains('zarzis') ||
        cleanInput.contains('bengardane') ||
        cleanInput.contains('douz') ||
        cleanInput.contains('matmata')) {
      return sud;
    }

    if (cleanInput.contains('hammamet') ||
        cleanInput.contains('marsa') ||
        cleanInput.contains('carthage') ||
        cleanInput.contains('kelibia') ||
        cleanInput.contains('tabarka')) {
      return nord;
    }

    if (cleanInput.contains('kantaoui') ||
        cleanInput.contains('moknine') ||
        cleanInput.contains('jemmel') ||
        cleanInput.contains('kerkenah') ||
        cleanInput.contains('chebba')) {
      return centre;
    }

    // Valeur de repli par défaut : nord
    return nord;
  }

  /// Nettoie une chaîne : minuscules, suppression des accents et caractères non alphanumériques.
  static String _clean(String s) {
    return s
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
