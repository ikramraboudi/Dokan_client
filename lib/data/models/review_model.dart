/// ============================================================================
/// RÔLE DU FICHIER : Modèle de données UI et de synthèse pour les avis clients (reviews).
/// INTERAGIT AVEC : review_repository.dart, product_detail_screen.dart, review_screen.dart.
/// ============================================================================
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Représente un avis client vérifié sur un produit reçu après livraison.
class ReviewUiModel {
  /// Identifiant déterministe sous la forme : "${orderId}_${productId}"
  final String id;

  /// Identifiant du produit noté.
  final String productId;

  /// Identifiant de la commande livrée d'origine.
  final String orderId;

  /// Identifiant de l'auteur (Firebase UID).
  final String userId;

  /// Nom d'affichage anonymisé : "Prénom + initiale du nom" (ex: "Karim M.").
  /// Jamais l'e-mail, ni le numéro de téléphone, ni le nom complet.
  final String authorName;

  /// Note attribuée entre 1 et 5.
  final int rating;

  /// Commentaire facultatif (0 à 500 caractères, nettoyé).
  final String comment;

  /// Date de création.
  final DateTime? createdAt;

  /// Date de dernière mise à jour.
  final DateTime? updatedAt;

  /// Indique si l'achat a été vérifié (toujours vrai car lié à une commande livrée).
  final bool isVerifiedPurchase;

  const ReviewUiModel({
    required this.id,
    required this.productId,
    required this.orderId,
    required this.userId,
    required this.authorName,
    required this.rating,
    this.comment = '',
    this.createdAt,
    this.updatedAt,
    this.isVerifiedPurchase = true,
  });

  /// Calcule l'identifiant déterministe standard.
  static String buildId({required String orderId, required String productId}) =>
      '${orderId}_$productId';

  /// Anonymise un nom complet en "Prénom + initiale du nom" (ex. "Karim M.").
  /// Ne conserve aucun e-mail, téléphone ni caractère sensible.
  static String sanitizeAuthorName(String? rawName) {
    if (rawName == null) return 'Client Dokan';
    var text = rawName.trim();
    if (text.isEmpty) return 'Client Dokan';

    // Si c'est un format email accidentel (ex: karim.mansour@gmail.com)
    if (text.contains('@')) {
      text = text.split('@').first.replaceAll(RegExp(r'[._\-]'), ' ').trim();
    }

    final parts = text.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'Client Dokan';
    if (parts.length == 1) {
      final name = parts[0];
      return name[0].toUpperCase() + (name.length > 1 ? name.substring(1) : '');
    }

    final firstName = parts[0][0].toUpperCase() +
        (parts[0].length > 1 ? parts[0].substring(1) : '');
    final lastInitial = parts[1][0].toUpperCase();
    return '$firstName $lastInitial.';
  }

  /// Formate une date relative en français (ex: "Aujourd'hui", "Hier", "Il y a 3 jours").
  String get relativeDate {
    final date = createdAt ?? updatedAt ?? DateTime.now();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return "À l'instant";
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24 && now.day == date.day) {
      return "Aujourd'hui";
    } else if (difference.inHours < 48 && (now.day - date.day == 1 || (now.day == 1 && date.day >= 28))) {
      return 'Hier';
    } else if (difference.inDays < 30) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    }
  }

  /// Fabrique un modèle depuis un document Firestore.
  factory ReviewUiModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ReviewUiModel.fromJson(data, doc.id);
  }

  /// Fabrique un modèle depuis une map JSON et un identifiant.
  factory ReviewUiModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    return ReviewUiModel(
      id: id,
      productId: (json['productId'] as String?) ?? '',
      orderId: (json['orderId'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
      authorName: (json['authorName'] as String?) ?? 'Client Dokan',
      rating: ((json['rating'] as num?)?.toInt() ?? 5).clamp(1, 5),
      comment: (json['comment'] as String?)?.trim() ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      isVerifiedPurchase: true,
    );
  }

  /// Convertit pour un stockage Firestore ou JSON.
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'orderId': orderId,
      'userId': userId,
      'authorName': authorName,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  ReviewUiModel copyWith({
    String? id,
    String? productId,
    String? orderId,
    String? userId,
    String? authorName,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerifiedPurchase,
  }) {
    return ReviewUiModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
    );
  }
}

/// Résumé agrégé des avis pour un produit donné (moyenne, total et ventilation 5 -> 1).
class ReviewSummary {
  /// Moyenne des notes (ex: 4.3).
  final double averageRating;

  /// Nombre total d'avis collectés.
  final int totalReviews;

  /// Ventilation du nombre d'avis par étoile (clés : 5, 4, 3, 2, 1).
  final Map<int, int> distribution;

  const ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
  });

  /// Résumé vide par défaut.
  static const ReviewSummary empty = ReviewSummary(
    averageRating: 0.0,
    totalReviews: 0,
    distribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
  );

  /// Calcule la proportion (entre 0.0 et 1.0) pour une note donnée.
  double ratioFor(int star) {
    if (totalReviews == 0) return 0.0;
    final count = distribution[star] ?? 0;
    return (count / totalReviews).clamp(0.0, 1.0);
  }

  /// Retourne le nombre d'avis pour une note donnée.
  int countFor(int star) => distribution[star] ?? 0;
}
