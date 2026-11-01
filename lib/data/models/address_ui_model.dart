/// ============================================================================
/// RÔLE DU FICHIER : Modèle d'adresse de livraison client avec sérialisation Firestore (fromFirestore, toMap).
/// INTERAGIT AVEC : firestore_addresses_repository.dart, AddressesScreen, CheckoutScreen.
/// POUR L'ORAL : « AddressUiModel représente l'adresse physique du client et gère la conversion bidirectionnelle avec Cloud Firestore. »
/// ============================================================================
/// ============================================================================
/// RÔLE DU FICHIER :
/// Modèle de données immuable représentant une adresse de livraison client.
/// Stockée dans Firestore sous : users/{uid}/addresses/{addressId}.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche data/models/ (Modèle Métier / Adresse).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : AddressesRepository, CheckoutScreen, AddressesScreen.
/// - Dépend de : cloud_firestore pour DocumentSnapshot et Timestamp.
/// ============================================================================
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Représentation d'une adresse de livraison enregistrée par le client.
class AddressUiModel {
  final String id;
  final String recipientName;
  final String phone;
  final String addressLine;
  final String city;
  final String? zone;
  final String? additionalInfo;
  final String? deliveryInstructions;
  final bool isDefault;
  final Timestamp? createdAt;

  const AddressUiModel({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    required this.city,
    this.zone,
    this.additionalInfo,
    this.deliveryInstructions,
    this.isDefault = false,
    this.createdAt,
  });

  /// Libellé résumé sur une ligne (ex: "Avenue Habib Bourguiba, Tunis").
  String get summary => zone != null && zone!.isNotEmpty
      ? '$addressLine, $zone, $city'
      : '$addressLine, $city';

  /// Désérialisation depuis un document Firestore.
  factory AddressUiModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AddressUiModel(
      id: doc.id,
      recipientName: data['recipientName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      addressLine: data['addressLine'] as String? ?? '',
      city: data['city'] as String? ?? '',
      zone: data['zone'] as String?,
      additionalInfo: data['additionalInfo'] as String?,
      deliveryInstructions: data['deliveryInstructions'] as String?,
      isDefault: data['isDefault'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  /// Sérialisation pour Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'recipientName': recipientName.trim(),
      'phone': phone.trim(),
      'addressLine': addressLine.trim(),
      'city': city.trim(),
      if (zone != null && zone!.trim().isNotEmpty) 'zone': zone!.trim(),
      if (additionalInfo != null && additionalInfo!.trim().isNotEmpty)
        'additionalInfo': additionalInfo!.trim(),
      if (deliveryInstructions != null && deliveryInstructions!.trim().isNotEmpty)
        'deliveryInstructions': deliveryInstructions!.trim(),
      'isDefault': isDefault,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  AddressUiModel copyWith({
    String? id,
    String? recipientName,
    String? phone,
    String? addressLine,
    String? city,
    String? Function()? zone,
    String? Function()? additionalInfo,
    String? Function()? deliveryInstructions,
    bool? isDefault,
    Timestamp? createdAt,
  }) {
    return AddressUiModel(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      zone: zone != null ? zone() : this.zone,
      additionalInfo:
          additionalInfo != null ? additionalInfo() : this.additionalInfo,
      deliveryInstructions: deliveryInstructions != null
          ? deliveryInstructions()
          : this.deliveryInstructions,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
