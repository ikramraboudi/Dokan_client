/// ============================================================================
/// RÔLE DU FICHIER : Repository Firestore gérant la création atomique (WriteBatch), la relecture des prix, l'écoute snapshots() et l'annulation en transaction.
/// INTERAGIT AVEC : CheckoutScreen, MyOrdersScreen, OrderDetailScreen, coupons.
/// POUR L'ORAL : « Ce repository est le cœur du flux de commande : il relit les prix dans Firestore, applique les coupons de manière atomique avec WriteBatch et gère l'annulation en transaction. »
/// ============================================================================
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/tunisia_regions.dart';
import '../../services/auth_service.dart';
import '../models/cart_item_ui_model.dart';
import '../models/order_model.dart';
import '../models/order_status.dart';
import 'orders_repository.dart';

/// Provider singleton du repository des commandes.
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return FirestoreOrdersRepository();
});

/// Provider Stream observant en direct toutes les commandes du client connecté.
final myOrdersStreamProvider = StreamProvider<List<OrderUiModel>>((ref) {
  final authService = AuthService();
  final user = authService.currentUser;
  if (user == null) {
    return Stream.value(const []);
  }
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.watchMyOrders(user.uid);
});

/// Provider Stream observant une commande unique par son ID Firestore (suivi direct).
final singleOrderStreamProvider =
    StreamProvider.family<OrderUiModel?, String>((ref, orderId) {
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.watchOrder(orderId);
});

class FirestoreOrdersRepository implements OrdersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  @override
  Future<OrderUiModel> createOrder({
    required String userId,
    required String customerName,
    required String customerPhone,
    required List<CartItemUiModel> cartItems,
    required OrderDeliveryAddress deliveryAddress,
    required double deliveryFee,
    String? promoCode,
    double discountAmount = 0.0,
  }) async {
    if (cartItems.isEmpty) {
      throw ArgumentError('Le panier ne peut pas être vide.');
    }

    // ────────────────────────────────────────────────────────────────────────
    // ÉTAPE 1 : VÉRIFICATION EN DIRECT DES PRODUITS DANS FIRESTORE
    // Relecture des prix et du stock directement depuis la base
    // pour ne pas faire confiance aveuglément au panier local.
    // ────────────────────────────────────────────────────────────────────────
    final List<OrderItemUiModel> verifiedItems = [];
    double calculatedSubtotal = 0.0;

    for (final item in cartItems) {
      final doc = await _productsRef.doc(item.productId).get();
      if (!doc.exists) {
        throw ProductUnavailableException(
          item.name,
          'Cet article n\'existe plus dans le catalogue.',
        );
      }

      final data = doc.data() ?? {};
      final availability = data['availability'] as String? ?? 'inStock';
      final inStockBool = data['inStock'] as bool? ?? true;

      if (availability == 'outOfStock' || !inStockBool) {
        throw ProductUnavailableException(
          item.name,
          'Cet article est actuellement en rupture de stock.',
        );
      }

      // Prix officiel Firestore (priorité au prix courant)
      final firestorePrice = (data['price'] as num?)?.toDouble() ?? item.unitPrice;
      final lineTotal = firestorePrice * item.quantity;
      calculatedSubtotal += lineTotal;

      // Poids officiel Firestore (priorité à data['poids'] puis item.poids)
      final firestorePoids = (data['poids'] as num?)?.toDouble() ??
          (data['weight'] as num?)?.toDouble() ??
          item.poids;

      verifiedItems.add(
        OrderItemUiModel(
          productId: item.productId,
          name: (data['name'] as String?) ??
              (data['title'] as String?) ??
              item.name,
          imageUrl: (data['imageUrl'] as String?) ??
              (data['imageUrls'] is List && (data['imageUrls'] as List).isNotEmpty
                  ? (data['imageUrls'] as List).first.toString()
                  : item.imageUrl),
          unitPrice: firestorePrice,
          quantity: item.quantity,
          variantLabel: item.variantLabel,
          lineTotal: lineTotal,
          poids: firestorePoids,
        ),
      );
    }

    // ────────────────────────────────────────────────────────────────────────
    // ÉTAPE 2 : CALCUL DES MONTANTS FINANCIERS DÉFINITIFS & TÉLÉMÉTRIE POIDS
    // Total = sous-total des articles vérifiés - réduction coupon + frais de livraison.
    // Camion requis si totalPoids > 50 kg OU maxItemPoids > 30 kg.
    // ────────────────────────────────────────────────────────────────────────
    final totalPoids =
        verifiedItems.fold<double>(0.0, (acc, i) => acc + i.linePoids);
    final maxItemPoids = verifiedItems.isEmpty
        ? 0.0
        : verifiedItems.map((e) => e.poids).reduce((a, b) => a > b ? a : b);
    final requiresTruck = totalPoids > 50.0 || maxItemPoids > 30.0;
    final requiredVehicleType = requiresTruck ? 'camion' : 'voiture';

    final cleanPromo = (promoCode != null && promoCode.trim().isNotEmpty)
        ? promoCode.trim().toUpperCase()
        : null;
    final effectiveDiscount = cleanPromo != null ? discountAmount : 0.0;

    final calculatedTotal =
        (calculatedSubtotal - effectiveDiscount + deliveryFee).clamp(0.0, double.infinity);

    final displayNumber = OrderUiModel.generateDisplayNumber();

    final initialHistory = [
      StatusHistoryEntry(
        status: OrderStatus.pending,
        at: Timestamp.now(),
      ),
    ];

    final newDoc = _ordersRef.doc();
    final nowTimestamp = Timestamp.now();

    final resolved = TunisiaRegions.resolveRegionAndCity(
      city: deliveryAddress.city,
      zone: deliveryAddress.zone,
      addressLine: deliveryAddress.addressLine,
    );
    final regionId = resolved.regionId;
    final cleanCity = resolved.city;

    final addressSummary = deliveryAddress.addressLine.isNotEmpty
        ? (deliveryAddress.zone != null && deliveryAddress.zone!.isNotEmpty
            ? '${deliveryAddress.addressLine}, ${deliveryAddress.zone}, $cleanCity'
            : (cleanCity.isNotEmpty
                ? '${deliveryAddress.addressLine}, $cleanCity'
                : deliveryAddress.addressLine))
        : deliveryAddress.summary;

    final orderData = {
      'displayNumber': displayNumber,
      'status': 'en attente',
      'statut': 'en attente',
      'customerId': userId,
      'userId': userId,
      'clientId': userId,
      'customerName': customerName.trim(),
      'customerPhone': customerPhone.trim(),
      'deliveryAddress': {
        'address': deliveryAddress.addressLine.isNotEmpty
            ? deliveryAddress.addressLine
            : addressSummary,
        'city': cleanCity,
        'regionId': regionId,
        'addressLine': deliveryAddress.addressLine,
        'zone': deliveryAddress.zone,
        'summary': addressSummary,
        'recipientName': deliveryAddress.recipientName,
        'phone': deliveryAddress.phone,
        'latitude': deliveryAddress.latitude,
        'longitude': deliveryAddress.longitude,
      },
      'deliveryAddressText': addressSummary,
      'city': cleanCity,
      'regionId': regionId,
      'deliveryAddressDetails': deliveryAddress.toMap(),
      'statusHistory': initialHistory.map((h) => h.toMap()).toList(),
      'items': verifiedItems.map((i) => {
        'productId': i.productId,
        'id': i.productId,
        'name': i.name,
        'price': i.unitPrice,
        'unitPrice': i.unitPrice,
        'quantity': i.quantity,
        'poids': i.poids,
        'totalPoids': i.linePoids,
        'lineTotal': i.lineTotal,
        'imageUrl': i.imageUrl,
        if (i.variantLabel != null) 'variantLabel': i.variantLabel,
      }).toList(),
      'itemCount': verifiedItems.fold<int>(0, (acc, i) => acc + i.quantity),
      'subtotal': calculatedSubtotal,
      'discount': effectiveDiscount,
      'promoCode': cleanPromo,
      'deliveryFee': deliveryFee,
      'total': calculatedTotal,
      'totalPrice': calculatedTotal,
      'totalAmount': calculatedTotal,
      'totalPoids': totalPoids,
      'requiresTruck': requiresTruck,
      'requiredVehicleType': requiredVehicleType,
      'currency': 'TND',
      'deliveryMode': 'standard',
      'paymentMethod': 'cash_on_delivery',
      'paymentStatus': 'unpaid',
      'estimatedDelivery': null,
      'driver': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // ────────────────────────────────────────────────────────────────────────
    // ÉTAPE 3 : ÉCRITURE ATOMIQUE DANS FIRESTORE
    // Enregistrement de la commande et incrément des statistiques du coupon
    // ────────────────────────────────────────────────────────────────────────
    final batch = _firestore.batch();
    batch.set(newDoc, orderData);

    // Si un coupon a été appliqué, mettre à jour atomiquement coupons/{cleanCode}
    if (cleanPromo != null) {
      DocumentReference<Map<String, dynamic>>? couponRef;
      final directDoc = await _firestore.collection('coupons').doc(cleanPromo).get();
      if (directDoc.exists) {
        couponRef = directDoc.reference;
      } else {
        final querySnap = await _firestore
            .collection('coupons')
            .where('code', isEqualTo: cleanPromo)
            .limit(1)
            .get();
        if (querySnap.docs.isNotEmpty) {
          couponRef = querySnap.docs.first.reference;
        }
      }

      if (couponRef != null) {
        batch.update(couponRef, {
          'currentUsageCount': FieldValue.increment(1),
          'usedByUsers': FieldValue.arrayUnion([userId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();

    return OrderUiModel(
      id: newDoc.id,
      displayNumber: displayNumber,
      userId: userId,
      customerName: customerName,
      customerPhone: customerPhone,
      status: OrderStatus.pending,
      statusHistory: initialHistory,
      items: verifiedItems,
      itemCount: verifiedItems.fold<int>(0, (acc, i) => acc + i.quantity),
      subtotal: calculatedSubtotal,
      discount: effectiveDiscount,
      promoCode: cleanPromo,
      deliveryFee: deliveryFee,
      total: calculatedTotal,
      currency: 'TND',
      deliveryAddress: deliveryAddress,
      city: cleanCity,
      regionId: regionId,
      deliveryMode: 'standard',
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'unpaid',
      totalPoids: totalPoids,
      requiresTruck: requiresTruck,
      requiredVehicleType: requiredVehicleType,
      createdAt: nowTimestamp,
      updatedAt: nowTimestamp,
    );
  }

  @override
  Stream<List<OrderUiModel>> watchMyOrders(String userId) {
    // Écoute temps réel des commandes du client triées de la plus récente à la plus ancienne
    return _ordersRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderUiModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Stream<OrderUiModel?> watchOrder(String orderId) {
    return _ordersRef.doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return OrderUiModel.fromFirestore(doc);
    });
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    final docRef = _ordersRef.doc(orderId);

    // Annulation sécurisée par Transaction atomique Firestore
    // 1) Démarrage de la transaction isolée
    await _firestore.runTransaction((transaction) async {
      // 2) Relecture de l'état actuel du document dans Firestore
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Commande introuvable.');
      }

      final data = snapshot.data();
      final currentStatusStr = data?['status'] as String?;
      final currentStatus = OrderStatus.fromString(currentStatusStr);

      // 3) Règle métier : seule une commande au statut "pending" peut être annulée par le client
      if (currentStatus != OrderStatus.pending) {
        throw StateError(
          'Impossible d\'annuler une commande déjà prise en charge (statut actuel : ${currentStatus.label}).',
        );
      }

      // 4) Préparation du nouvel historique avec le statut annulé
      final rawHistory = data?['statusHistory'];
      List<Map<String, dynamic>> updatedHistory = [];
      if (rawHistory is List) {
        updatedHistory = rawHistory
            .whereType<Map<String, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      updatedHistory.add({
        'status': 'annule',
        'statut': 'annule',
        'at': Timestamp.now(),
      });

      // 5) Mise à jour atomique du statut et de l'historique
      transaction.update(docRef, {
        'status': 'annule',
        'statut': 'annule',
        'statusHistory': updatedHistory,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> confirmDelivery({
    required String orderId,
    required String confirmationMethod,
    int? driverRating,
    String? driverFeedback,
  }) async {
    final docRef = _ordersRef.doc(orderId);
    final snap = await docRef.get();

    final data = snap.data();
    final rawHistory = data?['statusHistory'];
    List<Map<String, dynamic>> updatedHistory = [];
    if (rawHistory is List) {
      updatedHistory = rawHistory
          .whereType<Map<String, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    updatedHistory.add({
      'status': 'livre',
      'statut': 'livre',
      'at': Timestamp.now(),
      'note': confirmationMethod == 'client_qr_scan'
          ? 'Réception certifiée par scan QR Code livreur'
          : 'Réception certifiée par code PIN de secours',
    });

    final updatePayload = <String, dynamic>{
      'status': 'livre',
      'statut': 'livre',
      'deliveredAt': FieldValue.serverTimestamp(),
      'deliveryConfirmedBy': confirmationMethod,
      'paymentStatus': 'paid',
      'statusHistory': updatedHistory,
      'updatedAt': FieldValue.serverTimestamp(),
      ...?driverRating != null ? {'driverRating': driverRating} : null,
      if (driverFeedback != null && driverFeedback.trim().isNotEmpty)
        'driverFeedback': driverFeedback.trim(),
    };

    if (snap.exists) {
      await docRef.update(updatePayload);
    }

    // Compatibilité si répliqué dans 'commandes'
    try {
      final cmdRef = _firestore.collection('commandes').doc(orderId);
      final cmdSnap = await cmdRef.get();
      if (cmdSnap.exists) {
        await cmdRef.update(updatePayload);
      }
    } catch (_) {}
  }
}
