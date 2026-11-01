/// ============================================================================
/// RÔLE DU FICHIER : Interface abstraite (contrat) pour la gestion CRUD et l'écoute en flux des adresses client.
/// INTERAGIT AVEC : firestore_addresses_repository.dart.
/// POUR L'ORAL : « Cette interface définit les méthodes de gestion d'adresses pour découpler l'UI de la base Firestore. »
/// ============================================================================
/// ============================================================================
/// RÔLE DU FICHIER :
/// Interface abstraite définissant les opérations sur les adresses de livraison client.
/// Stockées dans Firestore sous la sous-collection `users/{uid}/addresses`.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche data/repositories/ (Contrats Abstraits).
///
/// RELATIONS ET DÉPENDANCES :
/// - Implémenté par : lib/data/repositories/firestore_addresses_repository.dart.
/// - Dépend de : data/models/address_ui_model.dart.
/// ============================================================================
library;

import '../models/address_ui_model.dart';

abstract class AddressesRepository {
  /// Écoute en temps réel la liste des adresses du client connecté.
  Stream<List<AddressUiModel>> watchAddresses(String userId);

  /// Récupère la liste des adresses en une seule requête.
  Future<List<AddressUiModel>> getAddresses(String userId);

  /// Ajoute une nouvelle adresse (et gère la logique de l'adresse par défaut).
  Future<String> addAddress(String userId, AddressUiModel address);

  /// Met à jour une adresse existante.
  Future<void> updateAddress(String userId, AddressUiModel address);

  /// Supprime une adresse.
  Future<void> deleteAddress(String userId, String addressId);

  /// Définit une adresse comme adresse par défaut du client.
  Future<void> setDefaultAddress(String userId, String addressId);
}
