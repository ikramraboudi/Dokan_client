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

  const OrderDeliveryAddress({
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    required this.city,
    this.zone,
    this.additionalInfo,
    this.deliveryInstructions,
  });

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
    };
  }
}

/// Informations du livreur renseignées plus tard par l'Admin ou le Livreur.
class DriverInfo {
  final String? driverId;
  final String name;
  final String phone;

  const DriverInfo({
    this.driverId,
    required this.name,
    required this.phone,
  });

  factory DriverInfo.fromMap(Map<String, dynamic> map) {
    return DriverInfo(
      driverId: map['driverId'] as String?,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (driverId != null) 'driverId': driverId,
      'name': name,
      'phone': phone,
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
  final double discount;
  final String? promoCode;
  final double deliveryFee;
  final double total;
  final String currency;
  final OrderDeliveryAddress deliveryAddress;
  final String deliveryMode;
  final String paymentMethod;
  final String paymentStatus;
  final Timestamp? estimatedDelivery;
  final DriverInfo? driver;
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
    this.deliveryMode = 'standard',
    this.paymentMethod = 'cash_on_delivery',
    this.paymentStatus = 'unpaid',
    this.estimatedDelivery,
    this.driver,
    required this.createdAt,
    required this.updatedAt,
  });

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

    // Reconstruction de l'adresse
    final rawAddress = data['deliveryAddress'] as Map<String, dynamic>? ?? {};
    final address = OrderDeliveryAddress.fromMap(rawAddress);

    // Reconstruction du livreur si présent
    final rawDriver = data['driver'] as Map<String, dynamic>?;
    final driver = rawDriver != null ? DriverInfo.fromMap(rawDriver) : null;

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
      deliveryMode: data['deliveryMode'] as String? ?? 'standard',
      paymentMethod: data['paymentMethod'] as String? ?? 'cash_on_delivery',
      paymentStatus: data['paymentStatus'] as String? ?? 'unpaid',
      estimatedDelivery: data['estimatedDelivery'] as Timestamp?,
      driver: driver,
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
      'deliveryAddress': deliveryAddress.toMap(),
      'deliveryMode': deliveryMode,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'estimatedDelivery': estimatedDelivery,
      if (driver != null) 'driver': driver!.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
