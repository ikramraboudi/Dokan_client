/// ============================================================================
/// RÔLE DU FICHIER : Écran interactif et synthétique pour les Conditions d'utilisation
/// et la Politique de confidentialité (format cartes courtes « points clés »,
/// mini-explosion d'emojis native, en-tête flottant et suivi de lecture 0/6 -> 6/6).
/// INTERAGIT AVEC : key_points_data.dart, app_colors.dart, app_router.dart, register_screen.dart.
/// ============================================================================
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_top_bar.dart';
import 'key_points_data.dart';

enum LegalType {
  terms,
  privacy,
}

/// Particule d'emoji pour la mini-explosion native lors de la lecture d'un point clé.
class _EmojiParticle {
  final int id;
  final String emoji;
  final Offset startPosition;
  final Offset endOffset;
  final double scale;
  final AnimationController controller;
  late final Animation<double> progress;

  _EmojiParticle({
    required this.id,
    required this.emoji,
    required this.startPosition,
    required this.endOffset,
    required this.scale,
    required this.controller,
  }) {
    progress = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
  }

  void dispose() {
    controller.dispose();
  }
}

class LegalScreen extends StatefulWidget {
  final LegalType type;

  const LegalScreen({
    super.key,
    required this.type,
  });

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen>
    with TickerProviderStateMixin {
  /// Section de données active (Conditions ou Confidentialité).
  LegalKeyPointsSection get _section => widget.type == LegalType.terms
      ? termsOfUseSection
      : privacyPolicySection;

  /// Ensemble des index de points marqués comme lus par l'utilisateur.
  final Set<int> _readIndices = <int>{};

  /// Index du dernier point touché pour animer le rebond de l'emoji.
  int? _lastTappedIndex;

  /// Contrôleur de l'en-tête pour le mouvement doux de flottement continu.
  late final AnimationController _floatingController;
  late final Animation<Offset> _floatingAnimation;

  /// Contrôleur de l'entrée en cascade des cartes.
  late final AnimationController _entranceController;

  /// Particules d'explosion actives (limitées strictement à 12 simultanées).
  final List<_EmojiParticle> _particles = <_EmojiParticle>[];
  int _nextParticleId = 0;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // 1. Mouvement doux de flottement pour l'emoji d'en-tête (période 2 secondes)
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _floatingAnimation = Tween<Offset>(
      begin: const Offset(0, -6),
      end: const Offset(0, 6),
    ).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOut,
      ),
    );
    _floatingController.repeat(reverse: true);

    // 2. Cascade d'apparition des cartes (~70 ms de décalage)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _entranceController.dispose();
    for (final particle in _particles) {
      particle.dispose();
    }
    _particles.clear();
    super.dispose();
  }

  void _triggerParticleExplosion(Offset globalPosition, String emoji) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) return;

    // Récupération des coordonnées locales relatives au Scaffold
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final localPosition = box != null
        ? box.globalToLocal(globalPosition)
        : globalPosition;

    // 3 à 5 particules par explosion, bornées pour ne jamais dépasser 12 simultanément
    final particleCount = 3 + _random.nextInt(3);
    for (int i = 0; i < particleCount; i++) {
      if (_particles.length >= 12) {
        // Nettoyage de la particule la plus ancienne si le plafond de 12 est atteint
        final oldest = _particles.removeAt(0);
        oldest.dispose();
      }

      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      );

      final double dx = (_random.nextDouble() - 0.5) * 80;
      final double dy = -50 - _random.nextDouble() * 60; // Montent vers le haut
      final double scale = 0.8 + _random.nextDouble() * 0.5;

      final particle = _EmojiParticle(
        id: _nextParticleId++,
        emoji: emoji,
        startPosition: localPosition,
        endOffset: Offset(dx, dy),
        scale: scale,
        controller: controller,
      );

      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() {
              _particles.removeWhere((p) => p.id == particle.id);
            });
          }
          particle.dispose();
        }
      });

      _particles.add(particle);
      controller.forward();
    }
  }

  void _handleCardTap(int index, TapDownDetails details) {
    HapticFeedback.lightImpact();

    final item = _section.points[index];
    _triggerParticleExplosion(details.globalPosition, item.emoji);

    setState(() {
      _lastTappedIndex = index;
      _readIndices.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (disableAnimations) {
      if (_floatingController.isAnimating) {
        _floatingController.stop();
      }
      if (_entranceController.value != 1.0) {
        _entranceController.value = 1.0;
      }
    } else if (!_floatingController.isAnimating) {
      _floatingController.repeat(reverse: true);
    }

    final totalPoints = _section.points.length;
    final readCount = _readIndices.length;
    final isAllRead = readCount >= totalPoints;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: _section.title,
        showBackButton: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Contenu scrollable principal
            ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
                vertical: AppDimens.space12,
              ),
              children: [
                // ── En-tête : Grand emoji flottant + Titre + Barre de progression ──
                _buildHeader(
                  disableAnimations: disableAnimations,
                  readCount: readCount,
                  totalPoints: totalPoints,
                ),
                const SizedBox(height: AppDimens.space16),

                // ── Liste ordonnée des 6 cartes de points clés ───────────────────
                ...List.generate(totalPoints, (index) {
                  final item = _section.points[index];
                  final isRead = _readIndices.contains(index);
                  final isJustTapped = _lastTappedIndex == index;

                  if (disableAnimations) {
                    return _buildKeyPointCard(
                      item: item,
                      index: index,
                      isRead: isRead,
                      isJustTapped: isJustTapped,
                      disableAnimations: true,
                    );
                  }

                  // Cascade d'apparition fluide (~70 ms d'intervalle)
                  final start = (index * 0.08).clamp(0.0, 0.6);
                  final end = (start + 0.35).clamp(0.0, 1.0);
                  final cardAnimation = CurvedAnimation(
                    parent: _entranceController,
                    curve: Interval(start, end, curve: Curves.easeOutCubic),
                  );

                  return FadeTransition(
                    opacity: cardAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.18),
                        end: Offset.zero,
                      ).animate(cardAnimation),
                      child: _buildKeyPointCard(
                        item: item,
                        index: index,
                        isRead: isRead,
                        isJustTapped: isJustTapped,
                        disableAnimations: false,
                      ),
                    ),
                  );
                }),

                const SizedBox(height: AppDimens.space16),

                // ── Bannière de félicitations & Bouton « J'ai compris » ──────────
                if (isAllRead) ...[
                  _buildCompletionBanner(),
                  const SizedBox(height: AppDimens.space24),
                ] else ...[
                  const SizedBox(height: AppDimens.space24),
                ],
              ],
            ),

            // ── Couche d'explosion de particules emojis ──────────────────────
            if (!disableAnimations && _particles.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _entranceController, // Ticker de repaint
                      builder: (context, _) {
                        return Stack(
                          children: _particles.map((particle) {
                            return AnimatedBuilder(
                              animation: particle.controller,
                              builder: (context, _) {
                                final t = particle.progress.value;
                                final dx = particle.startPosition.dx +
                                    particle.endOffset.dx * t;
                                final dy = particle.startPosition.dy +
                                    particle.endOffset.dy * t;
                                final opacity = (1.0 - t).clamp(0.0, 1.0);

                                return Positioned(
                                  left: dx - 12,
                                  top: dy - 12,
                                  child: Opacity(
                                    opacity: opacity,
                                    child: Transform.scale(
                                      scale: particle.scale * (1.0 + t * 0.3),
                                      child: ExcludeSemantics(
                                        child: Text(
                                          particle.emoji,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// En-tête : Grand emoji animé + Titre + Barre de progression 0/6 -> 6/6
  Widget _buildHeader({
    required bool disableAnimations,
    required int readCount,
    required int totalPoints,
  }) {
    final progressFraction = totalPoints > 0 ? (readCount / totalPoints) : 0.0;

    Widget heroEmoji = Text(
      _section.headerEmoji,
      style: const TextStyle(fontSize: 48),
    );

    if (!disableAnimations) {
      heroEmoji = AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: _floatingAnimation.value,
            child: child,
          );
        },
        child: heroEmoji,
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ExcludeSemantics(child: heroEmoji),
          const SizedBox(height: AppDimens.space10),
          Text(
            _section.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.space4),
          const Text(
            'Touchez chaque point pour le marquer comme lu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.space14),

          // Barre de progression
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$readCount/$totalPoints points lus',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (readCount == totalPoints)
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Complet',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppDimens.space6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radius8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progressFraction),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Carte individuelle représentant un point clé interactif
  Widget _buildKeyPointCard({
    required KeyPointItem item,
    required int index,
    required bool isRead,
    required bool isJustTapped,
    required bool disableAnimations,
  }) {
    final strongColor = AppColors.pastelAccents[item.colorIndex % AppColors.pastelAccents.length];
    final softColor = AppColors.pastelAccentsSoft[item.colorIndex % AppColors.pastelAccentsSoft.length];

    // Fond : teinté légèrement avec la couleur douce ou vert si lu
    final cardBgColor = isRead ? AppColors.surface : softColor;
    final cardBorderColor = isRead ? AppColors.success : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space12),
      child: Material(
        color: cardBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radius16),
          side: BorderSide(
            color: cardBorderColor,
            width: isRead ? 1.5 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkResponse(
          onTapDown: (details) => _handleCardTap(index, details),
          onTap: () {}, // Nécessaire pour déclencher l'effet splash
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(AppDimens.radius16),
          child: Semantics(
            button: true,
            label:
                'Point ${index + 1} : ${item.title}. ${item.sentence}. ${isRead ? "Point déjà lu." : "Touchez pour marquer comme lu."}',
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Emoji avec couleur forte + rebond au toucher
                  _CardEmojiBadge(
                    emoji: item.emoji,
                    backgroundColor: strongColor,
                    isJustTapped: isJustTapped,
                    disableAnimations: disableAnimations,
                  ),
                  const SizedBox(width: AppDimens.space14),

                  // Titre + phrase courte en dessous
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.sentence,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.space10),

                  // Indicateur d'état lu / non lu
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: isRead
                        ? Container(
                            key: const ValueKey('read_badge'),
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.successSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: AppColors.success,
                            ),
                          )
                        : Container(
                            key: const ValueKey('unread_badge'),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.border,
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.touch_app_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Bannière de félicitations lorsque tous les points ont été lus
  Widget _buildCompletionBanner() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.success, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Merci d\'avoir lu ! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.space6),
          const Text(
            'Vous connaissez maintenant l\'essentiel en toute transparence.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.space14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimens.space14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radius12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'J\'ai compris',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille d'emoji avec animation de rebond et légère rotation lors de la lecture
class _CardEmojiBadge extends StatefulWidget {
  final String emoji;
  final Color backgroundColor;
  final bool isJustTapped;
  final bool disableAnimations;

  const _CardEmojiBadge({
    required this.emoji,
    required this.backgroundColor,
    required this.isJustTapped,
    required this.disableAnimations,
  });

  @override
  State<_CardEmojiBadge> createState() => _CardEmojiBadgeState();
}

class _CardEmojiBadgeState extends State<_CardEmojiBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_controller);

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.05, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _CardEmojiBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isJustTapped && !widget.disableAnimations) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimens.radius14),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ExcludeSemantics(
        child: Text(
          widget.emoji,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );

    if (widget.disableAnimations) return badge;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * math.pi,
            child: child,
          ),
        );
      },
      child: badge,
    );
  }
}
