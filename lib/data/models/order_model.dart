/// ============================================================================
/// RÔLE DU FICHIER : Modèles complets de commande (OrderUiModel, OrderItemUiModel, OrderDeliveryAddress, StatusHistoryEntry, DriverInfo).
/// INTERAGIT AVEC : firestore_orders_repository.dart, MyOrdersScreen, OrderDetailScreen, CheckoutScreen.
/// POUR L'ORAL : « OrderUiModel structure toutes les données d'une commande et produit notre numéro formaté DK-AAMMJJ-XXXX. »
/// ============================================================================
/// ============================================================================
/// RÔLE DU FICHIER :
/// Modèle de données immuable représentant une commande Dokan dans Firestore.
/// Contient le modèle principal OrderUiModel et ses sous-composants :
/// - OrderItemUiModel (snapshot figé de la ligne d'article)
/// - OrderDeliveryAddress (snapshot figé de l'adresse choisie)
/// - DriverInfo (informations du livreur assigné par l'Admin)
/// - StatusHistoryEntry (journal horodaté de l'évolution du statut)
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche data/models/ (Modèle Métier / Commandes).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : OrdersRepository, CheckoutScreen, MyOrdersScreen, OrderDetailScreen.
/// - Dépend de : cloud_firestore et data/models/order_status.dart.
/// ============================================================================
library;

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/utils/tunisia_regions.dart';
import 'order_status.dart';

/// Ligne d'article commandé (copie figée / snapshot au moment de l'achat).
class OrderItemUiModel {
  final String productId;
  final String name;
  final String imageUrl;
  final double unitPrice;
  final int quantity;
  final String? variantLabel;
  final double lineTotal;

  const OrderItemUiModel({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    this.variantLabel,
    required this.lineTotal,
  });

  factory OrderItemUiModel.fromMap(Map<String, dynamic> map) {
    return OrderItemUiModel(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? 'Article',
      imageUrl: map['imageUrl'] as String? ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      variantLabel: map['variantLabel'] as String?,
      lineTotal: (map['lineTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'unitPrice': unitPrice,
      'quantity': quantity,
      if (variantLabel != null) 'variantLabel': variantLabel,
      'lineTotal': lineTotal,
    };
  }
}

/// Adresse de livraison figée (snapshot) au moment de la commande.
class OrderDeliveryAddress {
  final String recipientName;
  final String phone;
  final String addressLine;
  final String city;
  final String? zone;
  final String? additionalInfo;
  final String? deliveryInstructions;
  final double? latitude;
  final double? longitude;

  const OrderDeliveryAddress({
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    required this.city,
    this.zone,
    this.additionalInfo,
    this.deliveryInstructions,
    this.latitude,
    this.longitude,
  });

  /// Indique si l'adresse dispose de coordonnées GPS pour le suivi cartographique
  bool get hasCoordinates => latitude != null && longitude != null;

  String get summary => zone != null && zone!.isNotEmpty
      ? '$addressLine, $zone, $city'
      : '$addressLine, $city';

  factory OrderDeliveryAddress.fromMap(Map<String, dynamic> map) {
    return OrderDeliveryAddress(
      recipientName: map['recipientName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      addressLine: map['addressLine'] as String? ?? '',
      city: map['city'] as String? ?? '',
      zone: map['zone'] as String?,
      additionalInfo: map['additionalInfo'] as String?,
      deliveryInstructions: map['deliveryInstructions'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientName': recipientName,
      'phone': phone,
      'addressLine': addressLine,
      'city': city,
      if (zone != null) 'zone': zone,
      if (additionalInfo != null) 'additionalInfo': additionalInfo,
      if (deliveryInstructions != null)
        'deliveryInstructions': deliveryInstructions,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

/// Informations du livreur renseignées plus tard par l'Admin ou le Livreur.
class DriverInfo {
  final String? driverId;
  final String name;
  final String phone;
  final String? assignedVehiclePlate;
  final String? vehicleType;

  const DriverInfo({
    this.driverId,
    required this.name,
    required this.phone,
    this.assignedVehiclePlate,
    this.vehicleType,
  });

  /// Indique s'il s'agit d'un camion officiel Dokan (camion / truck)
  bool get isTruck {
    final t = (vehicleType ?? '').toLowerCase().trim();
    return t.contains('camion') || t.contains('truck');
  }

  /// Libellé du véhicule officiel (Camion officiel ou Voiture officielle)
  String get vehicleLabel => isTruck ? 'Camion officiel' : 'Voiture officielle';

  /// Émoji du véhicule officiel Dokan (aucun véhicule personnel)
  String get vehicleEmoji => isTruck ? '🚚' : '🚗';

  /// Icône Flutter officielle
  IconData get vehicleIcon =>
      isTruck ? Icons.local_shipping_rounded : Icons.directions_car_rounded;

  factory DriverInfo.fromMap(
    Map<String, dynamic> map, {
    String? fallbackPlate,
    String? fallbackType,
    String? fallbackDriverId,
  }) {
    final plate = map['assignedVehiclePlate'] as String? ??
        map['driverVehiclePlate'] as String? ??
        map['vehiclePlate'] as String? ??
        map['plate'] as String? ??
        fallbackPlate;
    final type = map['vehicleType'] as String? ??
        map['driverVehicleType'] as String? ??
        map['type'] as String? ??
        fallbackType;
    final id = map['driverId'] as String? ??
        map['delivererId'] as String? ??
        map['uid'] as String? ??
        map['id'] as String? ??
        fallbackDriverId;

    return DriverInfo(
      driverId: id,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      assignedVehiclePlate: plate,
      vehicleType: type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (driverId != null) 'driverId': driverId,
      'name': name,
      'phone': phone,
      if (assignedVehiclePlate != null)
        'assignedVehiclePlate': assignedVehiclePlate,
      if (vehicleType != null) 'vehicleType': vehicleType,
    };
  }
}

/// Entrée d'historique de statut pour la chronologie (timeline).
class StatusHistoryEntry {
  final OrderStatus status;
  final Timestamp at;

  const StatusHistoryEntry({
    required this.status,
    required this.at,
  });

  factory StatusHistoryEntry.fromMap(Map<String, dynamic> map) {
    return StatusHistoryEntry(
      status: OrderStatus.fromString(map['status'] as String?),
      at: map['at'] is Timestamp ? map['at'] as Timestamp : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.value,
      'at': at,
    };
  }
}

/// Modèle complet d'une commande client Dokan dans Firestore (`orders/{orderId}`).
class OrderUiModel {
  final String id;
  final String displayNumber;
  final String userId;
  final String customerName;
  final String customerPhone;
  final OrderStatus status;
  final List<StatusHistoryEntry> statusHistory;
  final List<OrderItemUiModel> items;
  final int itemCount;
  final double subtotal;

  /// Les promotions sont gérées par l'app Admin ; le Client n'écrit jamais de code promo.
  final double discount;

  /// Les promotions sont gérées par l'app Admin ; le Client n'écrit jamais de code promo.
  final String? promoCode;

  final double deliveryFee;
  final double total;
  final String currency;
  final OrderDeliveryAddress deliveryAddress;

  /// Ville de destination (ex: "Nabeul", "Sousse", "Tunis").
  final String city;

  /// Région logistique Dokan ('nord' | 'centre' | 'sud').
  final String regionId;

  final String deliveryMode;
  final String paymentMethod;
  final String paymentStatus;
  final Timestamp? estimatedDelivery;
  final DriverInfo? driver;

  /// Matricule officiel du véhicule assigné au niveau racine du document.
  final String? driverVehiclePlate;

  /// Type de véhicule officiel Dokan ('camion' | 'voiture').
  final String? driverVehicleType;

  final Timestamp? driverArrivedAt;
  final String? cancelledBy;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const OrderUiModel({
    required this.id,
    required this.displayNumber,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    required this.statusHistory,
    required this.items,
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    this.promoCode,
    required this.deliveryFee,
    required this.total,
    this.currency = 'TND',
    required this.deliveryAddress,
    this.city = 'Tunis',
    this.regionId = 'nord',
    this.deliveryMode = 'standard',
    this.paymentMethod = 'cash_on_delivery',
    this.paymentStatus = 'unpaid',
    this.estimatedDelivery,
    this.driver,
    this.driverVehiclePlate,
    this.driverVehicleType,
    this.driverArrivedAt,
    this.cancelledBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Matricule officiel du véhicule Dokan (priorité aux infos du livreur puis racine).
  String? get effectiveVehiclePlate {
    if (driver?.assignedVehiclePlate != null &&
        driver!.assignedVehiclePlate!.trim().isNotEmpty) {
      return driver!.assignedVehiclePlate!.trim();
    }
    if (driverVehiclePlate != null && driverVehiclePlate!.trim().isNotEmpty) {
      return driverVehiclePlate!.trim();
    }
    return null;
  }

  /// Type de véhicule officiel Dokan (camion ou voiture).
  String? get effectiveVehicleType {
    if (driver?.vehicleType != null &&
        driver!.vehicleType!.trim().isNotEmpty) {
      return driver!.vehicleType!.trim();
    }
    if (driverVehicleType != null && driverVehicleType!.trim().isNotEmpty) {
      return driverVehicleType!.trim();
    }
    return null;
  }

  /// Libellé officiel du véhicule (Camion officiel ou Voiture officielle).
  String get vehicleLabel {
    final type = (effectiveVehicleType ?? '').toLowerCase().trim();
    return (type.contains('camion') || type.contains('truck'))
        ? 'Camion officiel'
        : 'Voiture officielle';
  }

  /// Émoji du véhicule officiel Dokan (🚚 ou 🚗).
  String get vehicleEmoji {
    final type = (effectiveVehicleType ?? '').toLowerCase().trim();
    return (type.contains('camion') || type.contains('truck')) ? '🚚' : '🚗';
  }

  /// Icône Flutter officielle Dokan (Camion ou Voiture).
  IconData get vehicleIcon {
    final type = (effectiveVehicleType ?? '').toLowerCase().trim();
    return (type.contains('camion') || type.contains('truck'))
        ? Icons.local_shipping_rounded
        : Icons.directions_car_rounded;
  }

  /// Indique si un livreur ou un véhicule officiel est assigné à la commande.
  bool get hasDriverOrVehicle =>
      driver != null ||
      (effectiveVehiclePlate != null && effectiveVehiclePlate!.isNotEmpty);

  /// Identifiant du livreur assigné pour le suivi GPS en temps réel
  String? get delivererId => driver?.driverId;

  /// Génère un numéro de commande lisible de la forme DK-AAMMJJ-XXXX.
  /// (4 caractères alphanumériques sans caractères ambigus 0, O, 1, I).
  static String generateDisplayNumber() {
    final now = DateTime.now();
    final year = (now.year % 100).toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final random = Random();
    final randomSuffix =
        List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();

    return 'DK-$year$month$day-$randomSuffix';
  }

  /// Désérialisation depuis un document Firestore de la collection `orders`.
  factory OrderUiModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Reconstruction de l'historique
    final rawHistory = data['statusHistory'];
    List<StatusHistoryEntry> history = [];
    if (rawHistory is List) {
      history = rawHistory
          .whereType<Map<String, dynamic>>()
          .map((m) => StatusHistoryEntry.fromMap(m))
          .toList();
    }

    // Reconstruction des articles
    final rawItems = data['items'];
    List<OrderItemUiModel> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems
          .whereType<Map<String, dynamic>>()
          .map((m) => OrderItemUiModel.fromMap(m))
          .toList();
    }

    // Reconstruction de l'adresse (tolérant : format Map ou format String)
    final rawAddress = data['deliveryAddress'];
    final OrderDeliveryAddress address;
    if (rawAddress is Map<String, dynamic>) {
      address = OrderDeliveryAddress.fromMap(rawAddress);
    } else if (rawAddress is String) {
      address = OrderDeliveryAddress(
        recipientName: data['customerName'] as String? ?? '',
        phone: data['customerPhone'] as String? ?? '',
        addressLine: rawAddress,
        city: data['city'] as String? ?? '',
      );
    } else {
      final rawDetails =
          data['deliveryAddressDetails'] as Map<String, dynamic>? ?? {};
      address = OrderDeliveryAddress.fromMap(rawDetails);
    }

    // Région et Ville obligatoires
    final rawCity = (data['city'] as String?)?.trim();
    final city = (rawCity != null && rawCity.isNotEmpty)
        ? rawCity
        : (address.city.isNotEmpty ? address.city : 'Tunis');
    final rawRegion = (data['regionId'] as String?)?.trim().toLowerCase();
    final regionId = (rawRegion != null &&
            (rawRegion == 'nord' ||
                rawRegion == 'centre' ||
                rawRegion == 'sud'))
        ? rawRegion
        : TunisiaRegions.getRegionId(city);

    // Extraction des plaques et types de véhicule (racine ou driver)
    final rootPlate = data['driverVehiclePlate'] as String? ??
        data['assignedVehiclePlate'] as String? ??
        data['vehiclePlate'] as String?;
    final rootType = data['driverVehicleType'] as String? ??
        data['vehicleType'] as String?;
    final rootDelivererId = data['driverId'] as String? ??
        data['delivererId'] as String?;

    // Reconstruction du livreur si présent
    final rawDriver = data['driver'];
    DriverInfo? driver;
    if (rawDriver is Map<String, dynamic>) {
      driver = DriverInfo.fromMap(
        rawDriver,
        fallbackPlate: rootPlate,
        fallbackType: rootType,
        fallbackDriverId: rootDelivererId,
      );
    } else if (rootPlate != null ||
        rootType != null ||
        rootDelivererId != null ||
        data['driverName'] != null) {
      driver = DriverInfo(
        driverId: rootDelivererId,
        name: data['driverName'] as String? ?? '',
        phone: data['driverPhone'] as String? ?? '',
        assignedVehiclePlate: rootPlate,
        vehicleType: rootType,
      );
    }

    final createdAt = data['createdAt'] is Timestamp
        ? data['createdAt'] as Timestamp
        : Timestamp.now();
    final updatedAt = data['updatedAt'] is Timestamp
        ? data['updatedAt'] as Timestamp
        : createdAt;

    return OrderUiModel(
      id: doc.id,
      displayNumber: data['displayNumber'] as String? ?? 'DK-000000-0000',
      userId: data['userId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      customerPhone: data['customerPhone'] as String? ?? '',
      status: OrderStatus.fromString(data['status'] as String?),
      statusHistory: history,
      items: itemsList,
      itemCount: (data['itemCount'] as num?)?.toInt() ?? itemsList.length,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      promoCode: data['promoCode'] as String?,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'TND',
      deliveryAddress: address,
      city: city,
      regionId: regionId,
      deliveryMode: data['deliveryMode'] as String? ?? 'standard',
      paymentMethod: data['paymentMethod'] as String? ?? 'cash_on_delivery',
      paymentStatus: data['paymentStatus'] as String? ?? 'unpaid',
      estimatedDelivery: data['estimatedDelivery'] as Timestamp?,
      driver: driver,
      driverVehiclePlate: rootPlate,
      driverVehicleType: rootType,
      driverArrivedAt: data['driverArrivedAt'] as Timestamp?,
      cancelledBy: data['cancelledBy'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Sérialisation pour Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'displayNumber': displayNumber,
      'userId': userId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress.addressLine.isNotEmpty
          ? (deliveryAddress.city.isNotEmpty
              ? '${deliveryAddress.addressLine}, ${deliveryAddress.city}'
              : deliveryAddress.addressLine)
          : deliveryAddress.summary,
      'city': city,
      'regionId': regionId,
      'deliveryAddressDetails': deliveryAddress.toMap(),
      'status': status.value,
      'statusHistory': statusHistory.map((h) => h.toMap()).toList(),
      'items': items.map((i) => i.toMap()).toList(),
      'itemCount': itemCount,
      'subtotal': subtotal,
      'discount': discount,
      'promoCode': promoCode,
      'deliveryFee': deliveryFee,
      'total': total,
      'currency': currency,
      'deliveryMode': deliveryMode,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'estimatedDelivery': estimatedDelivery,
      if (driver != null) 'driver': driver!.toMap(),
      if (effectiveVehiclePlate != null)
        'driverVehiclePlate': effectiveVehiclePlate,
      if (effectiveVehicleType != null)
        'driverVehicleType': effectiveVehicleType,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
