/// ============================================================================
/// RÔLE DU FICHIER : Section complète « Avis des clients » pour la fiche produit.
///                   Affiche le résumé (moyenne, étoiles, ventilation 5->1 animée),
///                   l'avis de l'utilisateur épinglé, le bouton d'avis conditionnel
///                   et la liste paginée des avis vérifiés.
/// INTERAGIT AVEC : review_repository.dart, review_model.dart, product_ui_model.dart.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../data/models/product_ui_model.dart';
import '../../../data/models/review_model.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../services/auth_service.dart';

/// Section des avis des clients sur la fiche détaillée d'un produit.
class ProductReviewsSection extends ConsumerStatefulWidget {
  final ProductUiModel product;

  const ProductReviewsSection({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductReviewsSection> createState() =>
      _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends ConsumerState<ProductReviewsSection> {
  int _displayedLimit = 20;
  final Set<String> _expandedComments = <String>{};

  @override
  Widget build(BuildContext context) {
    final summaryAsync =
        ref.watch(productReviewSummaryProvider(widget.product.id));
    final reviewsAsync =
        ref.watch(productReviewsStreamProvider(widget.product.id));
    final eligibleOrderIdAsync =
        ref.watch(eligibleDeliveredOrderIdProvider(widget.product.id));
    final myReviewAsync =
        ref.watch(myReviewForProductProvider(widget.product.id));

    final myReview = myReviewAsync.valueOrNull;
    final allReviews = reviewsAsync.valueOrNull ?? const <ReviewUiModel>[];

    // Liste combinée sans doublon
    final combinedList = <ReviewUiModel>[...allReviews];
    if (myReview != null && !combinedList.any((r) => r.id == myReview.id)) {
      combinedList.add(myReview);
    }

    // Résumé effectif : calculé depuis le provider ou recalculé en direct depuis les avis temps réel
    ReviewSummary effectiveSummary =
        summaryAsync.valueOrNull ?? ReviewSummary.empty;

    if (effectiveSummary.totalReviews == 0 && combinedList.isNotEmpty) {
      final total = combinedList.length;
      final sum = combinedList.fold<int>(0, (prev, r) => prev + r.rating);
      final avg = sum / total;
      final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (final r in combinedList) {
        distribution[r.rating] = (distribution[r.rating] ?? 0) + 1;
      }
      effectiveSummary = ReviewSummary(
        averageRating: avg,
        totalReviews: total,
        distribution: distribution,
      );
    }

    final hasAnyReviews =
        effectiveSummary.totalReviews > 0 || combinedList.isNotEmpty;
    final isLoading = summaryAsync.isLoading && combinedList.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Titre de section et bouton d'action ─────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Avis des clients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            // Bouton "Donner mon avis" si l'utilisateur a reçu ce produit
            eligibleOrderIdAsync.maybeWhen(
              data: (orderId) {
                if (orderId == null) return const SizedBox.shrink();
                return OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space12,
                      vertical: AppDimens.space6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radius8),
                    ),
                  ),
                  icon: const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppColors.star,
                  ),
                  label: const Text(
                    '⭐ Donner mon avis',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => context.push(
                    AppRoutes.orderReviewPath(orderId, widget.product.id),
                    extra: {
                      'productName': widget.product.name,
                      'productImageUrl': widget.product.imageUrl,
                    },
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space16),

        // ── Résumé agrégé ou état vide ──────────────────────────────────────
        if (isLoading)
          _buildSummaryShimmer()
        else if (!hasAnyReviews)
          _buildEmptyState()
        else
          _buildSummaryCard(effectiveSummary),

        if (hasAnyReviews) const SizedBox(height: AppDimens.space20),

        // ── Avis personnel de l'utilisateur connecté (si déjà soumis) ────────
        if (myReview != null) ...[
          _buildMyReviewCard(myReview),
          const SizedBox(height: AppDimens.space16),
        ],

        // ── Liste paginée des autres avis ───────────────────────────────────
        if (hasAnyReviews) ...[
          ...allReviews
              .where((r) => myReview == null || r.id != myReview.id)
              .take(_displayedLimit)
              .map((review) => _buildReviewItem(review)),
          if (allReviews.where((r) => myReview == null || r.id != myReview.id).length >
              _displayedLimit) ...[
            const SizedBox(height: AppDimens.space12),
            Center(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space20,
                    vertical: AppDimens.space10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radius12),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _displayedLimit += 20;
                  });
                },
                child: const Text('Voir plus d\'avis'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  // --- Carte récapitulative de la moyenne et barres de ventilation ---
  Widget _buildSummaryCard(ReviewSummary summary) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Colonne gauche : Grande note + étoiles + nombre d'avis
          SizedBox(
            width: 110,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  summary.averageRating.toStringAsFixed(1).replaceAll('.', ','),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starNum = index + 1;
                    return Icon(
                      starNum <= summary.averageRating.round()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppColors.star,
                      size: 16,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '(${summary.totalReviews} avis)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppDimens.space16),
          Container(width: 1, height: 90, color: AppColors.divider),
          const SizedBox(width: AppDimens.space16),

          // Colonne droite : 5 barres de répartition proportionnelles animées (5 -> 1)
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final ratio = summary.ratioFor(star);
                final count = summary.countFor(star);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: AppColors.star,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                          child: Container(
                            height: 6,
                            color: AppColors.surfaceAlt,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: ratio),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              builder: (context, animatedRatio, child) {
                                return FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: animatedRatio,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.star,
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusFull,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 22,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- Carte "Votre avis" épinglée en haut ---
  Widget _buildMyReviewCard(ReviewUiModel review) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppDimens.radius8),
                ),
                child: const Text(
                  'Votre avis',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => context.push(
                  AppRoutes.orderReviewPath(review.orderId, review.productId),
                  extra: {
                    'productName': widget.product.name,
                    'productImageUrl': widget.product.imageUrl,
                  },
                ),
                child: const Text('Modifier'),
              ),
              const SizedBox(width: AppDimens.space8),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.error,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => _confirmDeleteReview(review),
                child: const Text('Supprimer'),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space8),
          Row(
            children: [
              ...List.generate(5, (index) {
                final starNum = index + 1;
                return Icon(
                  starNum <= review.rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: AppColors.star,
                  size: 16,
                );
              }),
              const SizedBox(width: AppDimens.space8),
              Text(
                review.relativeDate,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppDimens.space8),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDeleteReview(ReviewUiModel review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Supprimer votre avis ?'),
        content: const Text(
          'Êtes-vous certain de vouloir supprimer cet avis ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnDark,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final repo = ref.read(reviewRepositoryProvider);
      await repo.deleteReview(
        orderId: review.orderId,
        productId: review.productId,
      );

      ref.invalidate(productReviewSummaryProvider(widget.product.id));
      ref.invalidate(productReviewsStreamProvider(widget.product.id));
      ref.invalidate(eligibleDeliveredOrderIdProvider(widget.product.id));
      ref.invalidate(myReviewForProductProvider(widget.product.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre avis a été supprimé.'),
            backgroundColor: AppColors.textPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de supprimer : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // --- Composant d'un avis client dans la liste ---
  Widget _buildReviewItem(ReviewUiModel review) {
    final isExpanded = _expandedComments.contains(review.id);
    final initial = review.authorName.isNotEmpty
        ? review.authorName[0].toUpperCase()
        : 'C';

    Color avatarBg;
    Color avatarFg;
    if (review.rating >= 4) {
      avatarBg = AppColors.reviewGoodBg;
      avatarFg = AppColors.reviewGoodFg;
    } else if (review.rating == 3) {
      avatarBg = AppColors.reviewMidBg;
      avatarFg = AppColors.reviewMidFg;
    } else {
      avatarBg = AppColors.reviewBadBg;
      avatarFg = AppColors.reviewBadFg;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space12),
      padding: const EdgeInsets.all(AppDimens.space14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar avec initiale colorée selon la note
              CircleAvatar(
                radius: 16,
                backgroundColor: avatarBg,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: avatarFg,
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.space10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimens.space6),
                        // Badge Achat vérifié
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successSoft,
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusFull),
                          ),
                          child: const Text(
                            'Achat vérifié ✅',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      review.relativeDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              // Étoiles de note
              Row(
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return Icon(
                    starNum <= review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.star,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppDimens.space10),
            Text(
              review.comment,
              maxLines: isExpanded ? null : 3,
              overflow: isExpanded ? null : TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
            if (review.comment.length > 120) ...[
              const SizedBox(height: 2),
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedComments.remove(review.id);
                    } else {
                      _expandedComments.add(review.id);
                    }
                  });
                },
                child: Text(
                  isExpanded ? 'Réduire' : 'Lire la suite',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // --- État vide si aucun avis ---
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space24,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: const [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 36,
            color: AppColors.textHint,
          ),
          SizedBox(height: AppDimens.space12),
          Text(
            'Aucun avis pour le moment. Les clients livrés pourront donner le leur 🌟',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- Shimmer de chargement du résumé ---
  Widget _buildSummaryShimmer() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  // --- État d'erreur avec bouton réessayer ---
  Widget _buildErrorState(VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.textHint, size: 20),
          const SizedBox(width: AppDimens.space10),
          const Expanded(
            child: Text(
              'Impossible de charger le résumé des avis.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
