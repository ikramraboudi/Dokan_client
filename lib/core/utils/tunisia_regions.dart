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

  /// Détecte si un texte contient une mention explicite de région logistique ('nord', 'centre', 'sud').
  static String? extractExplicitRegion(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final clean = _clean(text);

    // Mots exacts ou expressions courantes
    if (clean == 'sud' ||
        clean.contains('regionsud') ||
        clean.contains('zonesud') ||
        clean.contains('grandsud') ||
        clean.contains('sudest') ||
        clean.contains('sudouest') ||
        RegExp(r'\bsud\b', caseSensitive: false).hasMatch(text)) {
      return sud;
    }

    if (clean == 'centre' ||
        clean.contains('regioncentre') ||
        clean.contains('zonecentre') ||
        clean.contains('centreest') ||
        clean.contains('centreouest') ||
        clean.contains('sahel') ||
        RegExp(r'\bcentre\b', caseSensitive: false).hasMatch(text)) {
      return centre;
    }

    if (clean == 'nord' ||
        clean.contains('regionnord') ||
        clean.contains('zonenord') ||
        clean.contains('grandnord') ||
        clean.contains('grandtunis') ||
        clean.contains('nordest') ||
        clean.contains('nordouest') ||
        RegExp(r'\bnord\b', caseSensitive: false).hasMatch(text)) {
      return nord;
    }

    return null;
  }

  /// Cherche si l'un des gouvernorats ou villes clés tunisiens est mentionné dans le texte.
  static String? findRecognizedCity(String? text) {
    if (text == null || text.trim().isEmpty) return null;

    // On vérifie d'abord les villes prioritaires en respectant les frontières de mots
    // pour éviter les pièges comme "Tunis" dans "Tunisie".
    for (final city in allCities) {
      final pattern =
          RegExp(r'\b' + RegExp.escape(city) + r'\b', caseSensitive: false);
      if (pattern.hasMatch(text)) {
        return city;
      }
    }

    // Villes avec graphies alternatives (sans accent ou variantes)
    final accentsMap = {
      'Béja': ['beja'],
      'Gabès': ['gabes'],
      'Médenine': ['medenine'],
      'Kébili': ['kebili'],
      'Le Kef': ['kef'],
      'Ben Arous': ['benarous'],
      'Sidi Bouzid': ['bouzid'],
    };

    for (final entry in accentsMap.entries) {
      for (final alias in entry.value) {
        final pattern =
            RegExp(r'\b' + RegExp.escape(alias) + r'\b', caseSensitive: false);
        if (pattern.hasMatch(text)) {
          return entry.key;
        }
      }
    }

    // Sous-localités célèbres
    final localMap = {
      'Djerba': 'Médenine',
      'Zarzis': 'Médenine',
      'Ben Gardane': 'Médenine',
      'Douz': 'Kébili',
      'Matmata': 'Gabès',
      'Hammamet': 'Nabeul',
      'La Marsa': 'Tunis',
      'Carthage': 'Tunis',
      'Kelibia': 'Nabeul',
      'Tabarka': 'Jendouba',
      'El Kantaoui': 'Sousse',
      'Moknine': 'Monastir',
      'Jemmel': 'Monastir',
      'Kerkennah': 'Sfax',
      'Chebba': 'Mahdia',
    };

    for (final entry in localMap.entries) {
      final pattern =
          RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false);
      if (pattern.hasMatch(text)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Résout intelligemment la région ('nord', 'centre', 'sud') et le nom de la ville
  /// en combinant la ville, la zone/quartier et la ligne d'adresse.
  ///
  /// Priorité :
  /// 1. Si la zone ou la ville spécifie explicitement une région ('sud', 'centre', 'nord'),
  ///    cette région est privilégiée (ex: zone = "SUD").
  /// 2. Si l'adresse contient un gouvernorat reconnu différent de "Tunis" (ex: "Sfax"),
  ///    ce gouvernorat devient la ville effective.
  /// 3. La région est déduite de la ville si aucune région explicite n'a été spécifiée.
  static ({String regionId, String city}) resolveRegionAndCity({
    String? city,
    String? zone,
    String? addressLine,
  }) {
    // 1. Détection de région explicite dans zone, city ou addressLine
    final explicitZoneRegion = extractExplicitRegion(zone);
    final explicitCityRegion = extractExplicitRegion(city);
    final explicitAddressRegion = extractExplicitRegion(addressLine);
    final explicitRegion =
        explicitZoneRegion ?? explicitCityRegion ?? explicitAddressRegion;

    // 2. Détection de la ville la plus pertinente
    final cityInField =
        (city != null && city.trim().isNotEmpty) ? city.trim() : null;
    final recognizedInCityField = findRecognizedCity(cityInField);
    final recognizedInAddressLine = findRecognizedCity(addressLine);
    final recognizedInZone = findRecognizedCity(zone);

    // Si l'adresse ou la zone mentionne une ville spécifique (ex: Sfax) alors que le champ ville
    // est "Tunis" (valeur d'exemple) ou vide ou égal à la région, on privilégie la ville trouvée.
    String effectiveCity = 'Tunis';
    if (cityInField != null &&
        cityInField.toLowerCase() != 'tunis' &&
        cityInField.toLowerCase() != 'sud' &&
        cityInField.toLowerCase() != 'centre' &&
        cityInField.toLowerCase() != 'nord') {
      effectiveCity = recognizedInCityField ?? cityInField;
    } else if (recognizedInAddressLine != null) {
      effectiveCity = recognizedInAddressLine;
    } else if (recognizedInZone != null) {
      effectiveCity = recognizedInZone;
    } else if (recognizedInCityField != null) {
      effectiveCity = recognizedInCityField;
    } else if (cityInField != null && cityInField.isNotEmpty) {
      effectiveCity = cityInField;
    }

    // 3. Détermination finale de la région
    final finalRegion = explicitRegion ?? getRegionId(effectiveCity);

    return (regionId: finalRegion, city: effectiveCity);
  }

  /// Détermine automatiquement la région ('nord', 'centre', 'sud') à partir d'une ville.
  /// Fonctionne de manière tolérante aux majuscules, accents et sous-localités.
  static String getRegionId(String? city) {
    if (city == null || city.trim().isEmpty) {
      return nord;
    }

    // 1. Détection directe si l'utilisateur a saisi directement un identifiant de région
    final explicit = extractExplicitRegion(city);
    if (explicit != null) {
      return explicit;
    }

    final cleanInput = _clean(city);

    // 2. Recherche par correspondance exacte ou inclusion des villes officielles
    for (final entry in regionCities.entries) {
      for (final refCity in entry.value) {
        final cleanRef = _clean(refCity);
        if (cleanInput == cleanRef ||
            cleanInput.contains(cleanRef) ||
            (cleanInput.length >= 4 && cleanRef.contains(cleanInput))) {
          return entry.key;
        }
      }
    }

    // 3. Mots-clés géographiques courants
    if (cleanInput.contains('djerba') ||
        cleanInput.contains('zarzis') ||
        cleanInput.contains('bengardane') ||
        cleanInput.contains('douz') ||
        cleanInput.contains('matmata') ||
        cleanInput.contains('sud')) {
      return sud;
    }

    if (cleanInput.contains('hammamet') ||
        cleanInput.contains('marsa') ||
        cleanInput.contains('carthage') ||
        cleanInput.contains('kelibia') ||
        cleanInput.contains('tabarka') ||
        cleanInput.contains('nord')) {
      return nord;
    }

    if (cleanInput.contains('kantaoui') ||
        cleanInput.contains('moknine') ||
        cleanInput.contains('jemmel') ||
        cleanInput.contains('kerkenah') ||
        cleanInput.contains('chebba') ||
        cleanInput.contains('centre')) {
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
