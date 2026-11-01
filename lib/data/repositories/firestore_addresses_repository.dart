/// ============================================================================
/// RÔLE DU FICHIER :
/// Implémentation Firestore concrète de la gestion des adresses client.
/// Emplacement Firestore : `users/{uid}/addresses/{addressId}`.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche data/repositories/ (Source de Données Distante / Firestore).
///
/// RELATIONS ET DÉPENDANCES :
/// - Injecté par : `addressesRepositoryProvider` et `addressesStreamProvider`.
/// - Dépend de : cloud_firestore, flutter_riverpod, address_ui_model.dart.
/// ============================================================================
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../models/address_ui_model.dart';
import 'addresses_repository.dart';

/// Provider singleton du repository d'adresses Firestore.
final addressesRepositoryProvider = Provider<AddressesRepository>((ref) {
  return FirestoreAddressesRepository();
});

/// Provider Stream observant en direct les adresses du client connecté.
final addressesStreamProvider = StreamProvider<List<AddressUiModel>>((ref) {
  final authService = AuthService();
  final user = authService.currentUser;
  if (user == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(addressesRepositoryProvider);
  return repo.watchAddresses(user.uid);
});

class FirestoreAddressesRepository implements AddressesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userAddressesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('addresses');
  }

  @override
  Stream<List<AddressUiModel>> watchAddresses(String userId) {
    return _userAddressesRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => AddressUiModel.fromFirestore(doc)).toList();
      // Trier pour placer l'adresse par défaut en premier
      list.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return 0;
      });
      return list;
    });
  }

  @override
  Future<List<AddressUiModel>> getAddresses(String userId) async {
    final snapshot = await _userAddressesRef(userId)
        .orderBy('createdAt', descending: true)
        .get();
    final list =
        snapshot.docs.map((doc) => AddressUiModel.fromFirestore(doc)).toList();
    list.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return 0;
    });
    return list;
  }

  @override
  Future<String> addAddress(String userId, AddressUiModel address) async {
    final col = _userAddressesRef(userId);

    // Si c'est la toute première adresse ou si isDefault est vrai,
    // on désélectionne les autres adresses existantes.
    final existing = await col.get();
    final isFirst = existing.docs.isEmpty;
    final makeDefault = address.isDefault || isFirst;

    final batch = _firestore.batch();

    if (makeDefault) {
      for (final doc in existing.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }

    final newDoc = col.doc();
    final data = address.copyWith(isDefault: makeDefault).toFirestore();
    batch.set(newDoc, data);

    await batch.commit();
    return newDoc.id;
  }

  @override
  Future<void> updateAddress(String userId, AddressUiModel address) async {
    final col = _userAddressesRef(userId);
    final batch = _firestore.batch();

    if (address.isDefault) {
      final existing = await col.get();
      for (final doc in existing.docs) {
        if (doc.id != address.id) {
          batch.update(doc.reference, {'isDefault': false});
        }
      }
    }

    batch.update(col.doc(address.id), address.toFirestore());
    await batch.commit();
  }

  @override
  Future<void> deleteAddress(String userId, String addressId) async {
    final col = _userAddressesRef(userId);
    await col.doc(addressId).delete();

    // S'il reste des adresses mais aucune par défaut, définir la première comme par défaut
    final remaining = await col.get();
    if (remaining.docs.isNotEmpty) {
      final hasDefault = remaining.docs
          .any((d) => (d.data()['isDefault'] as bool?) == true);
      if (!hasDefault) {
        await remaining.docs.first.reference.update({'isDefault': true});
      }
    }
  }

  @override
  Future<void> setDefaultAddress(String userId, String addressId) async {
    final col = _userAddressesRef(userId);
    final existing = await col.get();
    final batch = _firestore.batch();

    for (final doc in existing.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == addressId});
    }

    await batch.commit();
  }
}
