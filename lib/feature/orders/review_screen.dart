/// ============================================================================
/// RÔLE DU FICHIER : Écran interactif « Donner mon avis » avec visage expressif animé,
///                   curseur à 5 paliers avec haptique, fond réactif et mode modification.
/// INTERAGIT AVEC : review_repository.dart, review_model.dart, app_router.dart.
/// ============================================================================
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_status.dart';
import '../../data/models/product_ui_model.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/firestore_catalog_repository.dart';
import '../../data/repositories/firestore_orders_repository.dart';
import '../../data/repositories/orders_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../services/auth_service.dart';

/// Écran complet de notation et avis post-livraison d'un produit.
class ReviewScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String productId;

  /// Infos facultatives transmises directement pour éviter des requêtes supplémentaires
  final String? productName;
  final String? productImageUrl;

  const ReviewScreen({
    super.key,
    required this.orderId,
    required this.productId,
    this.productName,
    this.productImageUrl,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen>
    with SingleTickerProviderStateMixin {
  // Valeurs de note et d'interaction
  double _sliderRating = 3.0; // Valeur continue du curseur (1.0 à 5.0)
  int _ratingStep = 3; // Palier entier courant
  int _lastHapticStep = 3;
  bool _hasTouchedSlider = false; // Le bouton envoyer reste désactivé tant que non touché
  bool _isEditMode = false;
  bool _isLoadingInitial = true;
  bool _isSubmitting = false;
  bool _isSuccess = false;

  // Contrôleur de texte pour le commentaire facultatif
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Contrôleur d'animation pour le rebond du visage lors d'un changement de palier
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  // Données de secours pour l'en-tête produit
  String _displayName = '';
  String _displayImageUrl = '';
  bool _isDelivered = true;

  @override
  void initState() {
    super.initState();
    _displayName = widget.productName ?? '';
    _displayImageUrl = widget.productImageUrl ?? '';

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeOut,
    ));

    _commentController.addListener(() => setState(() {}));
    _initData();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _commentController.dispose();
    _commentFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final repo = ref.read(reviewRepositoryProvider);
    final authService = AuthService();
    final user = authService.currentUser;

    // 1. Vérification de la commande (doit être delivered)
    try {
      final ordersRepo = ref.read(ordersRepositoryProvider);
      final order = await ordersRepo.watchOrder(widget.orderId).first;
      if (order != null) {
        if (order.status != OrderStatus.delivered) {
          _isDelivered = false;
        }
        // Trouver l'item pour le nom et l'image si besoin
        if (_displayName.isEmpty) {
          final item = order.items.cast<OrderItemUiModel?>().firstWhere(
                (it) => it?.productId == widget.productId,
                orElse: () => null,
              );
          if (item != null) {
            _displayName = item.name;
            _displayImageUrl = item.imageUrl;
          }
        }
      }
    } catch (_) {
      // Ignorer ou tolérer en mode mock/démo
    }

    // 2. Récupération des infos produit complémentaires si toujours vides
    if (_displayName.isEmpty) {
      try {
        final catalogRepo = ref.read(firestoreCatalogRepositoryProvider);
        final prod = await catalogRepo.getProductById(widget.productId);
        if (prod != null) {
          _displayName = prod.name;
          _displayImageUrl = prod.imageUrl;
        }
      } catch (_) {
        _displayName = 'Article Dokan';
      }
    }

    // 3. Vérification si un avis existe déjà pour cette commande + produit
    try {
      final existing = await repo.getMyReviewForProductInOrder(
        orderId: widget.orderId,
        productId: widget.productId,
      );

      if (existing != null && mounted) {
        _isEditMode = true;
        _sliderRating = existing.rating.toDouble();
        _ratingStep = existing.rating;
        _lastHapticStep = existing.rating;
        _hasTouchedSlider = true;
        _commentController.text = existing.comment;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoadingInitial = false);
    }
  }

  // --- Gestion des couleurs réactives et du texte d'humeur ---

  Color _getBackgroundColor(double rating) {
    if (rating <= 3.0) {
      final t = ((rating - 1.0) / 2.0).clamp(0.0, 1.0);
      return Color.lerp(AppColors.reviewBadBg, AppColors.reviewMidBg, t) ??
          AppColors.reviewMidBg;
    } else {
      final t = ((rating - 3.0) / 2.0).clamp(0.0, 1.0);
      return Color.lerp(AppColors.reviewMidBg, AppColors.reviewGoodBg, t) ??
          AppColors.reviewGoodBg;
    }
  }

  Color _getForegroundColor(double rating) {
    if (rating <= 3.0) {
      final t = ((rating - 1.0) / 2.0).clamp(0.0, 1.0);
      return Color.lerp(AppColors.reviewBadFg, AppColors.reviewMidFg, t) ??
          AppColors.reviewMidFg;
    } else {
      final t = ((rating - 3.0) / 2.0).clamp(0.0, 1.0);
      return Color.lerp(AppColors.reviewMidFg, AppColors.reviewGoodFg, t) ??
          AppColors.reviewGoodFg;
    }
  }

  String _getMoodLabel(int step) {
    switch (step) {
      case 1:
        return 'TRÈS MAUVAIS';
      case 2:
        return 'MAUVAIS';
      case 3:
        return 'MOYEN';
      case 4:
        return 'BIEN';
      case 5:
        return 'EXCELLENT';
      default:
        return 'MOYEN';
    }
  }

  void _onSliderChanged(double value) {
    final newStep = value.round().clamp(1, 5);
    final disableAnim = MediaQuery.of(context).disableAnimations;

    if (!_hasTouchedSlider) {
      _hasTouchedSlider = true;
    }

    if (newStep != _lastHapticStep) {
      HapticFeedback.lightImpact();
      _lastHapticStep = newStep;
      if (!disableAnim) {
        _bounceController.forward(from: 0.0);
      }
    }

    setState(() {
      _sliderRating = value;
      _ratingStep = newStep;
    });
  }

  Future<bool> _handleCloseRequest() async {
    // Si l'utilisateur est sur l'écran de succès, on ferme directement
    if (_isSuccess) {
      context.pop(true);
      return true;
    }

    // Si du texte a été saisi ou si le curseur a été déplacé en mode création
    final hasContent = _commentController.text.trim().isNotEmpty ||
        (_hasTouchedSlider && !_isEditMode);

    if (!hasContent) {
      context.pop(false);
      return true;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Abandonner votre avis ?'),
        content: const Text(
          'Les modifications apportées à votre note et votre commentaire ne seront pas enregistrées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnDark,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );

    if (shouldDiscard == true && mounted) {
      context.pop(false);
      return true;
    }
    return false;
  }

  Future<void> _submitReview() async {
    if (!_hasTouchedSlider || _isSubmitting) return;

    if (!_isDelivered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vous ne pouvez donner votre avis que sur une commande livrée.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(reviewRepositoryProvider);
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour publier un avis.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // Calcul du nom anonymisé sécurisé "Prénom + initiale" (jamais d'email ni téléphone)
      String authorName = ReviewUiModel.sanitizeAuthorName(user.displayName);
      if (authorName == 'Client Dokan') {
        try {
          final userData = await authService.fetchUserData(user.uid);
          if (userData != null && userData['name'] != null) {
            authorName = ReviewUiModel.sanitizeAuthorName(userData['name'].toString());
          }
        } catch (_) {}
      }

      final review = ReviewUiModel(
        id: ReviewUiModel.buildId(
          orderId: widget.orderId,
          productId: widget.productId,
        ),
        productId: widget.productId,
        orderId: widget.orderId,
        userId: user.uid,
        authorName: authorName,
        rating: _ratingStep,
        comment: _commentController.text.trim(),
        isVerifiedPurchase: true,
      );

      await repo.submitReview(review);

      // Invalidation des providers Riverpod pour actualisation immédiate
      ref.invalidate(productReviewSummaryProvider(widget.productId));
      ref.invalidate(productReviewsStreamProvider(widget.productId));
      ref.invalidate(orderReviewsStreamProvider(widget.orderId));
      ref.invalidate(eligibleDeliveredOrderIdProvider(widget.productId));
      ref.invalidate(myReviewForProductProvider(widget.productId));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Échec de l\'envoi : ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteReview() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Supprimer votre avis ?'),
        content: const Text(
          'Êtes-vous certain de vouloir supprimer définitivement votre avis pour ce produit ? Cette action est irréversible.',
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

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(reviewRepositoryProvider);
      await repo.deleteReview(
        orderId: widget.orderId,
        productId: widget.productId,
      );

      ref.invalidate(productReviewSummaryProvider(widget.productId));
      ref.invalidate(productReviewsStreamProvider(widget.productId));
      ref.invalidate(orderReviewsStreamProvider(widget.orderId));
      ref.invalidate(eligibleDeliveredOrderIdProvider(widget.productId));
      ref.invalidate(myReviewForProductProvider(widget.productId));

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Votre avis a été supprimé.'),
          backgroundColor: AppColors.textPrimary,
        ),
      );

      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Impossible de supprimer : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor(_sliderRating);
    final fgColor = _getForegroundColor(_sliderRating);
    final disableAnim = MediaQuery.of(context).disableAnimations;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleCloseRequest();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: _isLoadingInitial
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : !_isDelivered
                  ? _buildNotDeliveredWarning(fgColor)
                  : _isSuccess
                      ? _buildSuccessView(bgColor, fgColor)
                      : _buildFormView(bgColor, fgColor, disableAnim),
        ),
      ),
    );
  }

  // --- Vue avertissement si la commande n'est pas au statut delivered ---
  Widget _buildNotDeliveredWarning(Color fgColor) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_clock_outlined, size: 64, color: fgColor),
          const SizedBox(height: AppDimens.space16),
          const Text(
            'Commande non livrée',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          const Text(
            'Vous pourrez évaluer cet article dès que le livreur aura validé la livraison de votre colis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppDimens.space24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radius12),
              ),
            ),
            onPressed: () => context.pop(),
            child: const Text('Retour à la commande'),
          ),
        ],
      ),
    );
  }

  // --- Vue principale du formulaire d'évaluation ---
  Widget _buildFormView(Color bgColor, Color fgColor, bool disableAnim) {
    final charCount = _commentController.text.length;

    return Column(
      children: [
        // 1. Barre supérieure avec bouton fermer ✕
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space16,
            vertical: AppDimens.space8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 28),
                color: AppColors.textPrimary,
                tooltip: 'Fermer',
                onPressed: _handleCloseRequest,
              ),
              Text(
                _isEditMode ? 'Modifier mon avis' : 'Donner mon avis',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 48), // Équilibre visuel pour le bouton fermer
            ],
          ),
        ),

        // 2. Contenu déroulant
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppDimens.space8),

                // Mini-carte produit
                _buildProductMiniCard(),

                const SizedBox(height: AppDimens.space20),

                // Grand visage expressif animé (RepaintBoundary pour haute performance)
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      final scale = disableAnim ? 1.0 : _bounceAnimation.value;
                      return Transform.scale(
                        scale: scale,
                        child: SizedBox(
                          width: 140,
                          height: 140,
                          child: CustomPaint(
                            painter: _ExpressiveFacePainter(
                              ratingValue: _sliderRating,
                              fgColor: fgColor,
                              fillColor: bgColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppDimens.space16),

                // Grand mot de l'état avec transition douce fondu + glissement
                SizedBox(
                  height: 36,
                  child: AnimatedSwitcher(
                    duration: disableAnim
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) {
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.2),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      _getMoodLabel(_ratingStep),
                      key: ValueKey<int>(_ratingStep),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: fgColor,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppDimens.space20),

                // Curseur interactif à 5 paliers
                _buildSliderSection(fgColor),

                const SizedBox(height: AppDimens.space24),

                // Zone de commentaire facultative
                _buildCommentBox(charCount),

                const SizedBox(height: AppDimens.space24),

                // Bouton Envoyer
                _buildSubmitButton(fgColor),

                // Lien discret supprimer en mode modification
                if (_isEditMode) ...[
                  const SizedBox(height: AppDimens.space16),
                  TextButton.icon(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Supprimer mon avis',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _deleteReview,
                  ),
                ],

                const SizedBox(height: AppDimens.space32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Mini-carte récapitulative du produit ---
  Widget _buildProductMiniCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space12,
        vertical: AppDimens.space8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppDimens.radius12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radius8),
            child: Container(
              width: 44,
              height: 44,
              color: AppColors.surfaceAlt,
              child: _displayImageUrl.isNotEmpty
                  ? Image.network(
                      _displayImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_outlined,
                        color: AppColors.textHint,
                      ),
                    )
                  : const Icon(
                      Icons.image_outlined,
                      color: AppColors.textHint,
                    ),
            ),
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName.isNotEmpty ? _displayName : 'Produit Dokan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Comment était ce produit ?',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Curseur 5 paliers avec labels et sémantiques ---
  Widget _buildSliderSection(Color fgColor) {
    return Column(
      children: [
        Semantics(
          slider: true,
          label: 'Note sur 5',
          value: 'Note $_ratingStep sur 5, ${_getMoodLabel(_ratingStep)}',
          increasedValue: 'Note ${(_ratingStep + 1).clamp(1, 5)} sur 5',
          decreasedValue: 'Note ${(_ratingStep - 1).clamp(1, 5)} sur 5',
          onIncrease: () => _onSliderChanged((_ratingStep + 1).clamp(1, 5).toDouble()),
          onDecrease: () => _onSliderChanged((_ratingStep - 1).clamp(1, 5).toDouble()),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: fgColor,
              inactiveTrackColor: fgColor.withValues(alpha: 0.2),
              thumbColor: fgColor,
              overlayColor: fgColor.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 4),
              activeTickMarkColor: AppColors.surface,
              inactiveTickMarkColor: fgColor.withValues(alpha: 0.4),
            ),
            child: Slider(
              value: _sliderRating,
              min: 1.0,
              max: 5.0,
              divisions: 4,
              onChanged: _onSliderChanged,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mauvais',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fgColor.withValues(alpha: 0.8),
                ),
              ),
              Text(
                'Moyen',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fgColor.withValues(alpha: 0.8),
                ),
              ),
              Text(
                'Excellent',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fgColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Champ de saisie du commentaire facultatif ---
  Widget _buildCommentBox(int charCount) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppDimens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _commentController,
            focusNode: _commentFocus,
            maxLength: 500,
            maxLines: 4,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Ajouter un commentaire (facultatif)…',
              hintStyle: TextStyle(
                color: AppColors.textHint,
                fontSize: 14,
              ),
              border: InputBorder.none,
              isDense: true,
              counterText: '', // Compteur personnalisé discret dessous
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$charCount / 500',
            style: TextStyle(
              fontSize: 11,
              color: charCount > 450 ? AppColors.error : AppColors.textHint,
              fontWeight: charCount > 450 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // --- Bouton Envoyer principal ---
  Widget _buildSubmitButton(Color fgColor) {
    final bool isEnabled = _hasTouchedSlider && !_isSubmitting;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? fgColor : AppColors.surfaceAlt,
          foregroundColor: isEnabled ? AppColors.textOnDark : AppColors.textHint,
          elevation: isEnabled ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radius14),
          ),
        ),
        onPressed: isEnabled ? _submitReview : null,
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.textOnDark,
                ),
              )
            : Text(
                _isEditMode ? 'Mettre à jour mon avis' : 'Envoyer →',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // --- Vue de succès animée ---
  Widget _buildSuccessView(Color bgColor, Color fgColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Visage rayonnant content
            SizedBox(
              width: 130,
              height: 130,
              child: CustomPaint(
                painter: _ExpressiveFacePainter(
                  ratingValue: _sliderRating,
                  fgColor: fgColor,
                  fillColor: bgColor,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space24),
            Text(
              'Merci !',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: fgColor,
              ),
            ),
            const SizedBox(height: AppDimens.space8),
            const Text(
              'Votre avis a bien été enregistré et aidera les autres clients.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppDimens.space24),

            // Récapitulatif
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radius16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starNum = index + 1;
                      return Icon(
                        starNum <= _ratingStep
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppColors.star,
                        size: 26,
                      );
                    }),
                  ),
                  if (_commentController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: AppDimens.space12),
                    Text(
                      '« ${_commentController.text.trim()} »',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppDimens.space32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: fgColor,
                      side: BorderSide(color: fgColor),
                      padding: const EdgeInsets.symmetric(vertical: AppDimens.space14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radius12),
                      ),
                    ),
                    onPressed: () => setState(() => _isSuccess = false),
                    child: const Text('Modifier'),
                  ),
                ),
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: fgColor,
                      foregroundColor: AppColors.textOnDark,
                      padding: const EdgeInsets.symmetric(vertical: AppDimens.space14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radius12),
                      ),
                    ),
                    onPressed: () => context.pop(true),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter dessinant le visage expressif morphé de façon continue selon la note.
class _ExpressiveFacePainter extends CustomPainter {
  final double ratingValue; // 1.0 à 5.0
  final Color fgColor;
  final Color fillColor;

  const _ExpressiveFacePainter({
    required this.ratingValue,
    required this.fgColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Fond du visage (légèrement teinté)
    final facePaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 2, facePaint);

    // 2. Contour du visage
    final outlinePaint = Paint()
      ..color = fgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - 2, outlinePaint);

    // 3. Les Yeux (interpolation fluide)
    final eyePaint = Paint()
      ..color = fgColor
      ..style = PaintingStyle.fill;

    final eyeStroke = Paint()
      ..color = fgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final leftEyeX = size.width * 0.33;
    final rightEyeX = size.width * 0.67;
    final eyeY = size.height * 0.40;

    if (ratingValue >= 4.0) {
      // Yeux plissés de joie (^  ^)
      final t = (ratingValue - 4.0).clamp(0.0, 1.0);
      final curveHeight = 8.0 + (t * 4.0);
      final eyeWidth = 10.0;

      // Œil gauche
      final leftEyePath = Path()
        ..moveTo(leftEyeX - eyeWidth, eyeY + 2)
        ..quadraticBezierTo(leftEyeX, eyeY - curveHeight, leftEyeX + eyeWidth, eyeY + 2);
      canvas.drawPath(leftEyePath, eyeStroke);

      // Œil droit
      final rightEyePath = Path()
        ..moveTo(rightEyeX - eyeWidth, eyeY + 2)
        ..quadraticBezierTo(rightEyeX, eyeY - curveHeight, rightEyeX + eyeWidth, eyeY + 2);
      canvas.drawPath(rightEyePath, eyeStroke);
    } else {
      // Yeux ronds (taille variable selon humeur)
      final eyeRadius = ratingValue < 2.0 ? 5.0 : 6.0;
      canvas.drawCircle(Offset(leftEyeX, eyeY), eyeRadius, eyePaint);
      canvas.drawCircle(Offset(rightEyeX, eyeY), eyeRadius, eyePaint);

      // Sourcils tristes pour notes 1 et 2
      if (ratingValue <= 2.5) {
        final browT = (2.5 - ratingValue) / 1.5; // 0.0 à 1.0
        final slant = browT * 6.0;

        // Sourcil gauche (incliné vers le haut au centre)
        canvas.drawLine(
          Offset(leftEyeX - 10, eyeY - 12 - slant),
          Offset(leftEyeX + 10, eyeY - 12 + slant),
          eyeStroke..strokeWidth = 2.5,
        );
        // Sourcil droit
        canvas.drawLine(
          Offset(rightEyeX - 10, eyeY - 12 + slant),
          Offset(rightEyeX + 10, eyeY - 12 - slant),
          eyeStroke,
        );
      }
    }

    // 4. La Bouche (courbe de Bézier quadratique interpolée)
    final mouthPaint = Paint()
      ..color = fgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final mouthY = size.height * 0.68;
    final mouthHalfWidth = size.width * 0.22;

    // Courbure : négatif = triste (arc vers le bas), 0 = neutre, positif = sourire (arc vers le haut)
    // Note 1 -> -18.0, Note 3 -> 0.0, Note 5 -> +22.0
    final double curvature;
    if (ratingValue <= 3.0) {
      final t = (ratingValue - 1.0) / 2.0; // 0.0 à 1.0
      curvature = -18.0 + (t * 18.0); // -18 à 0
    } else {
      final t = (ratingValue - 3.0) / 2.0; // 0.0 à 1.0
      curvature = t * 22.0; // 0 à 22
    }

    final mouthPath = Path();
    mouthPath.moveTo(center.dx - mouthHalfWidth, mouthY);
    mouthPath.quadraticBezierTo(
      center.dx,
      mouthY + curvature,
      center.dx + mouthHalfWidth,
      mouthY,
    );
    canvas.drawPath(mouthPath, mouthPaint);

    // Joues roses discrètes pour les bonnes notes (4 et 5)
    if (ratingValue >= 3.5) {
      final blushOpacity = ((ratingValue - 3.5) / 1.5).clamp(0.0, 0.4);
      final blushPaint = Paint()
        ..color = AppColors.favorite.withValues(alpha: blushOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(leftEyeX - 6, eyeY + 16), 8, blushPaint);
      canvas.drawCircle(Offset(rightEyeX + 6, eyeY + 16), 8, blushPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ExpressiveFacePainter oldDelegate) {
    return oldDelegate.ratingValue != ratingValue ||
        oldDelegate.fgColor != fgColor ||
        oldDelegate.fillColor != fillColor;
  }
}
