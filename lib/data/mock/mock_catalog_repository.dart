import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/catalog_repository.dart';
import '../repositories/firestore_catalog_repository.dart';

// Replace the existing catalogRepositoryProvider definition with this:
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return FirestoreCatalogRepository(); // Uses Firestore instead of Mock catalog
});