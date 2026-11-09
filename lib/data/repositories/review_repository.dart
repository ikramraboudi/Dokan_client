/// ============================================================================
/// RÔLE DU FICHIER : Interface abstraite et implémentations (Firestore + Mock) pour les avis clients.
/// INTERAGIT AVEC : review_model.dart, product_detail_screen.dart, review_screen.dart, order_detail_screen.dart.
/// ============================================================================
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../models/order_status.dart';
import '../models/review_model.dart';

/// Provider d'accès au repository des avis.
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  if (Firebase.apps.isNotEmpty) {
    return FirestoreReviewRepository();
  }
  return MockReviewRepository();
});

/// Provider de résumé agrégé (moyenne, nombre total, répartition 5 -> 1).
final productReviewSummaryProvider =
    FutureProvider.family<ReviewSummary, String>((ref, productId) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getSummary(productId);
});

/// Provider Stream des avis d'un produit (triés par date décroissante).
final productReviewsStreamProvider =
    StreamProvider.family<List<ReviewUiModel>, String>((ref, productId) {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.watchReviews(productId, limit: 20);
});

/// Provider Stream des avis du client pour une commande précise.
final orderReviewsStreamProvider =
    StreamProvider.family<List<ReviewUiModel>, String>((ref, orderId) {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.watchMyReviewsForOrder(orderId);
});

/// Provider d'éligibilité : retourne l'orderId d'une commande livrée éligible à un avis pour ce produit,
/// ou null si le client n'a pas reçu ce produit ou a déjà laissé un avis pour toutes ses commandes livrées.
final eligibleDeliveredOrderIdProvider =
    FutureProvider.family<String?, String>((ref, productId) async {
  final authService = AuthService();
  final user = authService.currentUser;
  if (user == null) return null;

  final repo = ref.watch(reviewRepositoryProvider);
  return repo.findDeliveredOrderIdForProduct(
    userId: user.uid,
    productId: productId,
  );
});

/// Provider vérifiant si l'utilisateur connecté a déjà publié un avis pour ce produit.
final myReviewForProductProvider =
    FutureProvider.family<ReviewUiModel?, String>((ref, productId) async {
  final authService = AuthService();
  final user = authService.currentUser;
  if (user == null) return null;

  final repo = ref.watch(reviewRepositoryProvider);
  return repo.findMyReviewForProduct(userId: user.uid, productId: productId);
});

/// Interface abstraite pour la gestion des avis clients.
abstract class ReviewRepository {
  /// Écoute en temps réel les avis d'un produit (triés du plus récent au plus ancien).
  Stream<List<ReviewUiModel>> watchReviews(String productId, {int limit = 20});

  /// Récupère une page d'avis avec pagination.
  Future<List<ReviewUiModel>> getReviews(
    String productId, {
    int limit = 20,
    DocumentSnapshot? startAfterDoc,
  });

  /// Calcule ou récupère le résumé (moyenne, total, répartition) pour un produit.
  Future<ReviewSummary> getSummary(String productId);

  /// Écoute les avis laissés pour les articles d'une commande donnée.
  Stream<List<ReviewUiModel>> watchMyReviewsForOrder(String orderId);

  /// Récupère l'avis de l'utilisateur pour un article précis d'une commande précise.
  Future<ReviewUiModel?> getMyReviewForProductInOrder({
    required String orderId,
    required String productId,
  });

  /// Recherche le premier avis existant de cet utilisateur pour un produit donné.
  Future<ReviewUiModel?> findMyReviewForProduct({
    required String userId,
    required String productId,
  });

  /// Cherche si l'utilisateur possède une commande au statut `delivered` contenant ce produit
  /// et pour laquelle aucun avis n'a encore été posté. Retourne son `orderId` ou null.
  Future<String?> findDeliveredOrderIdForProduct({
    required String userId,
    required String productId,
  });

  /// Enregistre un avis (création déterministe ou modification).
  Future<void> submitReview(ReviewUiModel review);

  /// Supprime un avis existant.
  Future<void> deleteReview({
    required String orderId,
    required String productId,
  });
}

/// Implémentation Firestore conforme et optimisée (100% sans Cloud Functions).
class FirestoreReviewRepository implements ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reviewsRef =>
      _firestore.collection('reviews');

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  @override
  Stream<List<ReviewUiModel>> watchReviews(String productId, {int limit = 20}) {
    return _reviewsRef
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReviewUiModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return list.take(limit).toList();
    });
  }

  @override
  Future<List<ReviewUiModel>> getReviews(
    String productId, {
    int limit = 20,
    DocumentSnapshot? startAfterDoc,
  }) async {
    final snap = await _reviewsRef
        .where('productId', isEqualTo: productId)
        .get();

    final list = snap.docs.map((doc) => ReviewUiModel.fromFirestore(doc)).toList();
    list.sort((a, b) => (b.createdAt ?? DateTime.now())
        .compareTo(a.createdAt ?? DateTime.now()));
    return list.take(limit).toList();
  }

  @override
  Future<ReviewSummary> getSummary(String productId) async {
    final baseQuery = _reviewsRef.where('productId', isEqualTo: productId);

    try {
      // 1. Tentative d'agrégation native Firestore
      final aggregateSnap = await baseQuery
          .aggregate(
            count(),
            average('rating'),
          )
          .get();

      final totalCount = aggregateSnap.count ?? 0;
      if (totalCount == 0) {
        return ReviewSummary.empty;
      }

      final avg = aggregateSnap.getAverage('rating') ?? 0.0;

      final distribution = <int, int>{};
      await Future.wait([5, 4, 3, 2, 1].map((star) async {
        try {
          final starSnap = await baseQuery
              .where('rating', isEqualTo: star)
              .count()
              .get();
          distribution[star] = starSnap.count ?? 0;
        } catch (_) {
          distribution[star] = 0;
        }
      }));

      return ReviewSummary(
        averageRating: avg,
        totalReviews: totalCount,
        distribution: distribution,
      );
    } catch (_) {
      // 2. Repli résilient et immédiat : calcul direct depuis les documents
      try {
        final docsSnap = await baseQuery.get();
        if (docsSnap.docs.isEmpty) {
          return ReviewSummary.empty;
        }

        final list = docsSnap.docs.map((d) => ReviewUiModel.fromFirestore(d)).toList();
        final total = list.length;
        final sum = list.fold<int>(0, (prev, r) => prev + r.rating);
        final avg = sum / total;

        final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
        for (final r in list) {
          distribution[r.rating] = (distribution[r.rating] ?? 0) + 1;
        }

        return ReviewSummary(
          averageRating: avg,
          totalReviews: total,
          distribution: distribution,
        );
      } catch (_) {
        return ReviewSummary.empty;
      }
    }
  }

  @override
  Stream<List<ReviewUiModel>> watchMyReviewsForOrder(String orderId) {
    return _reviewsRef
        .where('orderId', isEqualTo: orderId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewUiModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<ReviewUiModel?> getMyReviewForProductInOrder({
    required String orderId,
    required String productId,
  }) async {
    final docId = ReviewUiModel.buildId(orderId: orderId, productId: productId);
    final doc = await _reviewsRef.doc(docId).get();
    if (!doc.exists) return null;
    return ReviewUiModel.fromFirestore(doc);
  }

  @override
  Future<ReviewUiModel?> findMyReviewForProduct({
    required String userId,
    required String productId,
  }) async {
    try {
      final snap = await _reviewsRef
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return ReviewUiModel.fromFirestore(snap.docs.first);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> findDeliveredOrderIdForProduct({
    required String userId,
    required String productId,
  }) async {
    try {
      // Recherche des commandes de l'utilisateur (tolérant 'userId', 'customerId', 'status', 'statut')
      final ordersSnap = await _ordersRef
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        final rawStatus = (data['status'] as String?) ?? (data['statut'] as String?);
        final status = OrderStatus.fromString(rawStatus);
        if (status != OrderStatus.delivered) {
          continue;
        }

        final items = (data['items'] as List<dynamic>?) ?? [];
        final hasProduct = items.any((item) {
          if (item is Map) {
            final pId = item['productId']?.toString() ?? item['id']?.toString();
            return pId == productId;
          }
          return false;
        });

        if (hasProduct) {
          // Vérifie si un avis existe déjà pour cette commande
          final reviewId = ReviewUiModel.buildId(
            orderId: doc.id,
            productId: productId,
          );
          final reviewDoc = await _reviewsRef.doc(reviewId).get();
          if (!reviewDoc.exists) {
            return doc.id; // Trouvé : commande livrée sans avis pour ce produit
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> submitReview(ReviewUiModel review) async {
    if (review.rating < 1 || review.rating > 5) {
      throw ArgumentError('La note doit être comprise entre 1 et 5.');
    }
    final trimmedComment = review.comment.trim();
    if (trimmedComment.length > 500) {
      throw ArgumentError('Le commentaire ne peut pas dépasser 500 caractères.');
    }

    final docId = ReviewUiModel.buildId(
      orderId: review.orderId,
      productId: review.productId,
    );
    final docRef = _reviewsRef.doc(docId);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      // Modification
      await docRef.update({
        'rating': review.rating,
        'comment': trimmedComment,
        'authorName': review.authorName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Création
      await docRef.set({
        'productId': review.productId,
        'orderId': review.orderId,
        'userId': review.userId,
        'authorName': review.authorName,
        'rating': review.rating,
        'comment': trimmedComment,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<void> deleteReview({
    required String orderId,
    required String productId,
  }) async {
    final docId = ReviewUiModel.buildId(
      orderId: orderId,
      productId: productId,
    );
    await _reviewsRef.doc(docId).delete();
  }
}

/// Implémentation Mock avec données de démonstration en mémoire.
class MockReviewRepository implements ReviewRepository {
  final List<ReviewUiModel> _reviews = [
    ReviewUiModel(
      id: 'cmd_101_prod_1',
      productId: 'prod_1',
      orderId: 'cmd_101',
      userId: 'mock_user_1',
      authorName: 'Karim M.',
      rating: 5,
      comment: 'Superbe set de casseroles ! Chaleur bien répartie et nettoyage très facile.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ReviewUiModel(
      id: 'cmd_102_prod_1',
      productId: 'prod_1',
      orderId: 'cmd_102',
      userId: 'mock_user_2',
      authorName: 'Sonia B.',
      rating: 4,
      comment: 'Bonne qualité générale, livraison soignée dans les délais.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ReviewUiModel(
      id: 'cmd_103_prod_1',
      productId: 'prod_1',
      orderId: 'cmd_103',
      userId: 'mock_user_3',
      authorName: 'Yassine K.',
      rating: 5,
      comment: 'Excellent rapport qualité-prix. Je recommande sans hésitation Dokan !',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      updatedAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    ReviewUiModel(
      id: 'cmd_104_prod_2',
      productId: 'prod_2',
      orderId: 'cmd_104',
      userId: 'mock_user_4',
      authorName: 'Amel D.',
      rating: 5,
      comment: 'Très satisfaite de mon achat, conforme à la description.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final _controller = StreamController<List<ReviewUiModel>>.broadcast();

  MockReviewRepository();

  void _notify() {
    _controller.add(List.unmodifiable(_reviews));
  }

  @override
  Stream<List<ReviewUiModel>> watchReviews(String productId, {int limit = 20}) {
    List<ReviewUiModel> currentForProduct() {
      final list = _reviews.where((r) => r.productId == productId).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list.take(limit).toList();
    }

    return Stream.value(currentForProduct()).concatWith([
      _controller.stream.map((_) => currentForProduct()),
    ]);
  }

  @override
  Future<List<ReviewUiModel>> getReviews(
    String productId, {
    int limit = 20,
    DocumentSnapshot? startAfterDoc,
  }) async {
    final list = _reviews.where((r) => r.productId == productId).toList();
    list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    return list.take(limit).toList();
  }

  @override
  Future<ReviewSummary> getSummary(String productId) async {
    final list = _reviews.where((r) => r.productId == productId).toList();
    if (list.isEmpty) return ReviewSummary.empty;

    final total = list.length;
    final sum = list.fold<int>(0, (prev, r) => prev + r.rating);
    final avg = sum / total;

    final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in list) {
      distribution[r.rating] = (distribution[r.rating] ?? 0) + 1;
    }

    return ReviewSummary(
      averageRating: avg,
      totalReviews: total,
      distribution: distribution,
    );
  }

  @override
  Stream<List<ReviewUiModel>> watchMyReviewsForOrder(String orderId) {
    List<ReviewUiModel> currentForOrder() =>
        _reviews.where((r) => r.orderId == orderId).toList();

    return Stream.value(currentForOrder()).concatWith([
      _controller.stream.map((_) => currentForOrder()),
    ]);
  }

  @override
  Future<ReviewUiModel?> getMyReviewForProductInOrder({
    required String orderId,
    required String productId,
  }) async {
    final id = ReviewUiModel.buildId(orderId: orderId, productId: productId);
    try {
      return _reviews.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ReviewUiModel?> findMyReviewForProduct({
    required String userId,
    required String productId,
  }) async {
    try {
      return _reviews.firstWhere(
        (r) => r.productId == productId && r.userId == userId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> findDeliveredOrderIdForProduct({
    required String userId,
    required String productId,
  }) async {
    // Dans le mock, simule une commande livrée 'mock_order_delivered' si l'utilisateur n'a pas encore noté
    final hasReview = _reviews.any(
      (r) => r.productId == productId && r.userId == userId,
    );
    return hasReview ? null : 'cmd_mock_delivered';
  }

  @override
  Future<void> submitReview(ReviewUiModel review) async {
    if (review.rating < 1 || review.rating > 5) {
      throw ArgumentError('La note doit être comprise entre 1 et 5.');
    }
    final trimmedComment = review.comment.trim();
    if (trimmedComment.length > 500) {
      throw ArgumentError('Le commentaire ne peut pas dépasser 500 caractères.');
    }

    final index = _reviews.indexWhere((r) => r.id == review.id);
    final now = DateTime.now();
    if (index >= 0) {
      _reviews[index] = review.copyWith(
        comment: trimmedComment,
        updatedAt: now,
      );
    } else {
      _reviews.add(review.copyWith(
        comment: trimmedComment,
        createdAt: now,
        updatedAt: now,
      ));
    }
    _notify();
  }

  @override
  Future<void> deleteReview({
    required String orderId,
    required String productId,
  }) async {
    final id = ReviewUiModel.buildId(orderId: orderId, productId: productId);
    _reviews.removeWhere((r) => r.id == id);
    _notify();
  }
}

/// Extension utilitaire interne pour chaîner un premier événement synchrone et les suivants.
extension _StreamConcatExtension<T> on Stream<T> {
  Stream<T> concatWith(Iterable<Stream<T>> others) async* {
    yield* this;
    for (final s in others) {
      yield* s;
    }
  }
}
