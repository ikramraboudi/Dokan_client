/// ============================================================================
/// RÔLE DU FICHIER : Repository mock du catalogue fournissant des données de secours pour les tests et la démo hors-ligne.
/// INTERAGIT AVEC : catalogRepositoryProvider, HomeScreen, CatalogScreen.
/// POUR L'ORAL : « Ce mock sert de jeu de données de référence et de secours pour nos tests unitaires sans dépendre du réseau. »
/// ============================================================================
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/catalog_repository.dart';
import '../repositories/firestore_catalog_repository.dart';

// Replace the existing catalogRepositoryProvider definition with this:
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return FirestoreCatalogRepository(); // Uses Firestore instead of Mock catalog
});