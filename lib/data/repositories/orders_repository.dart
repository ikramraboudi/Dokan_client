/// ============================================================================
/// RÔLE DU FICHIER : Interface abstraite définissant la création, l'écoute et l'annulation de commandes.
/// INTERAGIT AVEC : firestore_orders_repository.dart, ordersRepositoryProvider.
/// POUR L'ORAL : « OrdersRepository isole nos écrans de commande de l'implémentation Firestore concrète. »
/// ============================================================================
library;

import '../models/cart_item_ui_model.dart';
import '../models/order_model.dart';

/// Exception levée si un produit du panier est devenu introuvable ou indisponible.
class ProductUnavailableException implements Exception {
  final String productName;
  final String reason;

  ProductUnavailableException(this.productName, this.reason);

  @override
  String toString() => 'Article indisponible ($productName) : $reason';
}

abstract class OrdersRepository {
  /// Crée une commande de façon atomique dans Firestore après vérification
  /// en direct des prix, de la disponibilité des produits et application des promotions.
  Future<OrderUiModel> createOrder({
    required String userId,
    required String customerName,
    required String customerPhone,
    required List<CartItemUiModel> cartItems,
    required OrderDeliveryAddress deliveryAddress,
    required double deliveryFee,
    String? promoCode,
    double discountAmount = 0.0,
  });

  /// Écoute en temps réel toutes les commandes du client (tri antichronologique).
  Stream<List<OrderUiModel>> watchMyOrders(String userId);

  /// Écoute en temps réel une commande spécifique (suivi en direct du statut).
  Stream<OrderUiModel?> watchOrder(String orderId);

  /// Annule une commande en attente (autorisé côté client uniquement si status == pending).
  Future<void> cancelOrder(String orderId);

  /// Valide la réception de la commande par le client (via scan QR Code ou code PIN de secours)
  /// et bascule son statut officiel à "livre".
  Future<void> confirmDelivery({
    required String orderId,
    required String confirmationMethod, // 'client_qr_scan' | 'client_pin_code'
    int? driverRating,
    String? driverFeedback,
  });
}
