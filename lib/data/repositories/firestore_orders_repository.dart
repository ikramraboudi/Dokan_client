/// ============================================================================
/// RÔLE DU FICHIER :
/// Implémentation Firestore concrète du repository des commandes Dokan.
/// Gère la création atomique, la re-vérification des prix côté serveur,
/// l'écoute en flux continu (Stream) et l'annulation sécurisée en transaction.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche data/repositories/ (Source de Données Distante / Firestore).
///
/// RELATIONS ET DÉPENDANCES :
/// - Injecté par : `ordersRepositoryProvider` et `myOrdersStreamProvider`.
/// - Dépend de : cloud_firestore, flutter_riverpod, order_model.dart,
///   order_status.dart, cart_item_ui_model.dart, orders_repository.dart.
/// ============================================================================
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    required String? promoCode,
    required double discountPercent,
    required double deliveryFee,
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
        ),
      );
    }

    // ────────────────────────────────────────────────────────────────────────
    // ÉTAPE 2 : CALCUL DES MONTANTS FINANCIERS DÉFINITIFS
    // ────────────────────────────────────────────────────────────────────────
    final discountAmount = calculatedSubtotal * (discountPercent / 100.0);
    final calculatedTotal =
        (calculatedSubtotal - discountAmount + deliveryFee).clamp(0.0, double.infinity);

    final displayNumber = OrderUiModel.generateDisplayNumber();

    // NOTE TECHNIQUE : FieldValue.serverTimestamp() n'est pas autorisé dans
    // un élément de tableau (array) Firestore. On utilise Timestamp.now()
    // pour la première entrée de statusHistory, et serverTimestamp() pour createdAt.
    final initialHistory = [
      StatusHistoryEntry(
        status: OrderStatus.pending,
        at: Timestamp.now(),
      ),
    ];

    final newDoc = _ordersRef.doc();
    final nowTimestamp = Timestamp.now();

    final orderData = {
      'displayNumber': displayNumber,
      'userId': userId,
      'customerName': customerName.trim(),
      'customerPhone': customerPhone.trim(),
      'status': OrderStatus.pending.value,
      'statusHistory': initialHistory.map((h) => h.toMap()).toList(),
      'items': verifiedItems.map((i) => i.toMap()).toList(),
      'itemCount': verifiedItems.fold<int>(0, (acc, i) => acc + i.quantity),
      'subtotal': calculatedSubtotal,
      'discount': discountAmount,
      'promoCode': promoCode,
      'deliveryFee': deliveryFee,
      'total': calculatedTotal,
      'currency': 'TND',
      'deliveryAddress': deliveryAddress.toMap(),
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
    // TODO : le stock est géré par l'Admin / une Cloud Function (pas côté Client).
    // ────────────────────────────────────────────────────────────────────────
    final batch = _firestore.batch();
    batch.set(newDoc, orderData);
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
      discount: discountAmount,
      promoCode: promoCode,
      deliveryFee: deliveryFee,
      total: calculatedTotal,
      currency: 'TND',
      deliveryAddress: deliveryAddress,
      deliveryMode: 'standard',
      paymentMethod: 'cash_on_delivery',
      paymentStatus: 'unpaid',
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

    // Annulation sécurisée par Transaction atomique
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Commande introuvable.');
      }

      final data = snapshot.data() ?? {};
      final currentStatus = data['status'] as String? ?? '';

      if (currentStatus != OrderStatus.pending.value) {
        throw Exception(
          'Seule une commande encore "En attente" peut être annulée.',
        );
      }

      final rawHistory = data['statusHistory'];
      List<dynamic> history = rawHistory is List ? List.from(rawHistory) : [];
      history.add({
        'status': OrderStatus.cancelled.value,
        'at': Timestamp.now(),
      });

      transaction.update(docRef, {
        'status': OrderStatus.cancelled.value,
        'statusHistory': history,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
