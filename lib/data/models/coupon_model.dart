/// ============================================================================
/// RÔLE DU FICHIER : Modèle de données immuable représentant un code promo / coupon dans Firestore (`coupons/{couponId}`).
/// INTERAGIT AVEC : mock_cart_repository.dart (CartNotifier), firestore_orders_repository.dart, CartScreen.
/// POUR L'ORAL : « CouponModel modélise les promotions créées par l'Admin avec support des types de réduction, montants minimaux et plafonds d'utilisation. »
/// ============================================================================
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle d'un code promotionnel Dokan stocké dans la collection Firestore `coupons`.
class CouponModel {
  /// Identifiant unique du document Firestore (ex: "PROMO70" ou docId auto).
  final String id;

  /// Code promo en majuscules (ex: "PROMO70", "BIENVENUE10").
  final String code;

  /// Type de réduction : 'percentage' (%) ou 'fixed' (montant fixe en DT).
  final String discountType;

  /// Valeur de la réduction (ex: 15 pour 15% ou 20.0 pour 20 DT).
  final double discountValue;

  /// Plafond maximal de réduction en DT pour les pourcentages (optionnel).
  final double? maxDiscountAmount;

  /// Montant minimum d'achats requis pour appliquer le coupon (en DT).
  final double minCartAmount;

  /// Si true, coupon réservé aux clients passant leur première commande.
  final bool isFirstOrderOnly;

  /// Type de restriction d'usage : 'unlimited', 'oncePerUser', 'totalLimit', 'singleUse'.
  final String usageLimitType;

  /// Quota maximum d'utilisations si usageLimitType == 'totalLimit'.
  final int? maxUsageCount;

  /// Nombre total de fois où le coupon a été utilisé.
  final int currentUsageCount;

  /// Liste des UID des utilisateurs ayant déjà utilisé ce coupon.
  final List<String> usedByUsers;

  /// Date de début de validité du coupon.
  final Timestamp startDate;

  /// Date d'expiration optionnelle.
  final Timestamp? endDate;

  /// Statut d'activation défini par l'administrateur.
  final bool isActive;

  const CouponModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountAmount,
    this.minCartAmount = 0.0,
    this.isFirstOrderOnly = false,
    this.usageLimitType = 'unlimited',
    this.maxUsageCount,
    this.currentUsageCount = 0,
    this.usedByUsers = const [],
    required this.startDate,
    this.endDate,
    this.isActive = true,
  });

  /// Désérialisation depuis un document Firestore de la collection `coupons`.
  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final rawUsers = data['usedByUsers'];
    List<String> users = [];
    if (rawUsers is List) {
      users = rawUsers.map((e) => e.toString()).toList();
    }

    final start = data['startDate'] is Timestamp
        ? data['startDate'] as Timestamp
        : Timestamp.now();

    final end = data['endDate'] is Timestamp
        ? data['endDate'] as Timestamp
        : null;

    final rawCode = data['code'] as String? ?? doc.id;

    return CouponModel(
      id: doc.id,
      code: rawCode.trim().toUpperCase(),
      discountType: data['discountType'] as String? ?? 'percentage',
      discountValue: (data['discountValue'] as num?)?.toDouble() ?? 0.0,
      maxDiscountAmount: (data['maxDiscountAmount'] as num?)?.toDouble(),
      minCartAmount: (data['minCartAmount'] as num?)?.toDouble() ?? 0.0,
      isFirstOrderOnly: data['isFirstOrderOnly'] as bool? ?? false,
      usageLimitType: data['usageLimitType'] as String? ?? 'unlimited',
      maxUsageCount: (data['maxUsageCount'] as num?)?.toInt(),
      currentUsageCount: (data['currentUsageCount'] as num?)?.toInt() ?? 0,
      usedByUsers: users,
      startDate: start,
      endDate: end,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Calcule le montant de la réduction pour un sous-total donné.
  double calculateDiscount(double subtotal) {
    if (subtotal <= 0) return 0.0;

    if (discountType == 'percentage') {
      var amount = subtotal * (discountValue / 100.0);
      if (maxDiscountAmount != null && amount > maxDiscountAmount!) {
        amount = maxDiscountAmount!;
      }
      return amount > subtotal ? subtotal : amount;
    } else {
      // 'fixed'
      return discountValue > subtotal ? subtotal : discountValue;
    }
  }

  /// Validation métier complète du coupon selon les règles Dokan.
  /// Renvoie null si le coupon est valide, ou une chaîne d'erreur explicative sinon.
  String? validate({
    required double subtotal,
    String? userId,
    int userPreviousOrdersCount = 0,
  }) {
    // 1. Statut d'activation
    if (!isActive) {
      return 'Code promo invalide ou désactivé.';
    }

    // 2. Date d'expiration
    final now = DateTime.now();
    if (endDate != null && now.isAfter(endDate!.toDate())) {
      return 'Ce code promo a expiré.';
    }

    // 3. Montant minimum du panier
    if (subtotal < minCartAmount) {
      return 'Le panier doit être d\'au moins ${minCartAmount.toStringAsFixed(0)} DT pour ce code.';
    }

    // 4. Règle première commande
    if (isFirstOrderOnly) {
      if (userId == null || userId.isEmpty) {
        return 'Veuillez vous connecter pour utiliser ce code réservé aux nouveaux clients.';
      }
      if (userPreviousOrdersCount > 0) {
        return 'Ce code promo est réservé à votre première commande.';
      }
    }

    // 5. Limites d'utilisation
    if (usageLimitType == 'oncePerUser') {
      if (userId != null && userId.isNotEmpty && usedByUsers.contains(userId)) {
        return 'Vous avez déjà utilisé ce code promo.';
      }
    } else if (usageLimitType == 'singleUse') {
      if (currentUsageCount >= 1) {
        return 'Ce code promo a déjà été utilisé.';
      }
    } else if (usageLimitType == 'totalLimit') {
      if (maxUsageCount != null && currentUsageCount >= maxUsageCount!) {
        return "Ce code promo a atteint sa limite maximale d'utilisations.";
      }
    }

    return null;
  }
}
