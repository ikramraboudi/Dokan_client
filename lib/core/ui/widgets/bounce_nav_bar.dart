/// ============================================================================
/// RÔLE DU FICHIER : Barre de navigation inférieure flottante style « Bounce » (bulle de verre gélatineuse).
/// DESIGN SYSTEM : Glassmorphism teal sombre, bulle bondissante avec squash & stretch, lueur dynamique et point indicateur.
/// ============================================================================
library;

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../animations/cart_fly_animation.dart';

// --- Constantes configurables de style et de géométrie ---
const double kNavBarHeight = 66.0;
const double kNavBubbleDiameter = 54.0;
const double kNavBubbleGap = 10.0;
const double kNavHorizontalMargin = 16.0;
const double kNavBottomMargin = 12.0;

// --- Couleurs Glassmorphism Dokan ---
const Color kNavGlassDarkTeal = Color(0xDD0D2B2F); // Fond verre dépoli vert-canard profond
const Color kNavBubbleGradientTop = Color(0xFA2D7D7A); // Teinte supérieure bulle
const Color kNavBubbleGradientBottom = Color(0xF0154D4E); // Teinte inférieure bulle
const Color kNavBorderColor = Color(0x35FFFFFF); // Fine bordure claire (environ 21% opacité)
const Color kNavGlowColor = Color(0x281F7A7A); // Halo diffus derrière l'onglet actif
const double kNavBlurSigma = 16.0; // Intensité du flou de verre dépoli

// --- Paramètres temporels de l'animation ---
const Duration kNavBounceDuration = Duration(milliseconds: 550);
const Duration kNavFastDuration = Duration(milliseconds: 150);

/// Modèle descriptif d'un onglet de la barre de navigation.
class BounceNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? tooltip;
  final int badgeCount;

  const BounceNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.tooltip,
    this.badgeCount = 0,
  });
}

/// Barre de navigation flottante « Bounce » avec bulle gélatineuse bondissante.
class BounceBottomNavBar extends StatefulWidget {
  final List<BounceNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BounceBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<BounceBottomNavBar> createState() => _BounceBottomNavBarState();
}

class _BounceBottomNavBarState extends State<BounceBottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Indices et positions de départ et d'arrivée
  int _fromIndex = 0;
  int _toIndex = 0;
  double _startPositionFactor = 0.0;
  double _targetPositionFactor = 0.0;

  // Dernier index officiel notifié
  late int _activeDisplayIndex;

  @override
  void initState() {
    super.initState();
    _activeDisplayIndex = widget.currentIndex;
    _fromIndex = widget.currentIndex;
    _toIndex = widget.currentIndex;
    _startPositionFactor = widget.currentIndex.toDouble();
    _targetPositionFactor = widget.currentIndex.toDouble();

    _controller = AnimationController(
      vsync: this,
      duration: kNavBounceDuration,
    );
  }

  @override
  void didUpdateWidget(covariant BounceBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _startTransition(oldWidget.currentIndex, widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Déclenche la transition gélatineuse fluide vers le nouvel index.
  void _startTransition(int from, int to) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      setState(() {
        _fromIndex = to;
        _toIndex = to;
        _activeDisplayIndex = to;
        _startPositionFactor = to.toDouble();
        _targetPositionFactor = to.toDouble();
      });
      return;
    }

    // Si une animation était en cours, on part de la position interpolée actuelle sans à-coup
    final currentFactor = _controller.isAnimating
        ? _calculateInterpolatedPosition(_controller.value)
        : _targetPositionFactor;

    setState(() {
      _fromIndex = from;
      _toIndex = to;
      _activeDisplayIndex = to;
      _startPositionFactor = currentFactor;
      _targetPositionFactor = to.toDouble();
    });

    // Ajustement fin de la durée selon l'écart (ex: 4 onglets d'écart = 650 ms, 1 onglet = 500 ms)
    final distance = (to - from).abs();
    final adjustedMs = (480 + distance * 45).clamp(500, 680);
    _controller.duration = Duration(milliseconds: adjustedMs);

    _controller.forward(from: 0.0);
  }

  void _handleTap(int index) {
    HapticFeedback.selectionClick();
    if (index == widget.currentIndex) {
      // Re-clic sur l'onglet actif : petit rebond vertical local et navigation racine
      if (!_controller.isAnimating) {
        _controller.forward(from: 0.70);
      }
      widget.onTap(index);
    } else {
      widget.onTap(index);
    }
  }

  /// Calcule la position interpolée continue [0 .. items.length - 1]
  double _calculateInterpolatedPosition(double t) {
    if (_startPositionFactor == _targetPositionFactor) {
      return _targetPositionFactor;
    }
    // Courbe avec dépassement élastique amorti en fin de course
    final curvedT = Curves.easeOutBack.transform(t);
    return _startPositionFactor + (_targetPositionFactor - _startPositionFactor) * curvedT;
  }

  /// Calcule les déformations gélatineuses (scaleX, scaleY, deltaY)
  ({double scaleX, double scaleY, double deltaY}) _computeJellyDeformation(
    double t,
    double distance,
    bool disableAnimations,
  ) {
    if (disableAnimations || distance == 0) {
      return (scaleX: 1.0, scaleY: 1.0, deltaY: 0.0);
    }

    final distFactor = (distance / 2.0).clamp(0.6, 1.25);
    double sx = 1.0;
    double sy = 1.0;
    double dy = 0.0;

    if (t < 0.15) {
      // Décollage : élongation verticale préparatoire au saut
      final progress = t / 0.15;
      final impulse = math.sin(math.pi * progress);
      sx = 1.0 - (0.14 * impulse);
      sy = 1.0 + (0.22 * impulse);
      dy = -3.5 * impulse;
    } else if (t < 0.70) {
      // Plein vol : étirement horizontal et aplatissement aérodynamique (vitesse max)
      final progress = (t - 0.15) / 0.55;
      final flight = math.sin(math.pi * progress);
      sx = 1.0 + (0.25 * distFactor * flight);
      sy = 1.0 - (0.20 * distFactor * flight);
      dy = -7.5 * flight; // Léger arc de saut parabolique
    } else {
      // Atterrissage & Rebondissement : 2 oscillations élastiques amorties
      final progress = (t - 0.70) / 0.30;
      final damping = math.exp(-4.2 * progress);
      final oscillation = math.cos(3.0 * math.pi * progress);
      final reboundImpulse = damping * oscillation;

      sx = 1.0 - (0.18 * distFactor * reboundImpulse);
      sy = 1.0 + (0.20 * distFactor * reboundImpulse);
      dy = 4.0 * damping * math.sin(3.0 * math.pi * progress);
    }

    return (scaleX: sx, scaleY: sy, deltaY: dy);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;

    // Si le clavier virtuel est ouvert, ne pas remonter par-dessus
    if (isKeyboardOpen) {
      return const SizedBox.shrink();
    }

    final safeAreaBottom = mediaQuery.padding.bottom;
    final disableAnimations = mediaQuery.disableAnimations;
    final totalBarStackHeight =
        kNavBarHeight + kNavBottomMargin + safeAreaBottom + kNavBubbleDiameter + kNavBubbleGap;

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final barWidth = totalWidth - (kNavHorizontalMargin * 2);
          final tabCount = widget.items.length;
          final tabWidth = barWidth / tabCount;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              final distance = (_toIndex - _fromIndex).abs().toDouble();

              final currentFactor = _calculateInterpolatedPosition(t);
              final deform = _computeJellyDeformation(t, distance, disableAnimations);

              // Position X absolue du centre de la bulle
              final bubbleCenterX =
                  kNavHorizontalMargin + (currentFactor + 0.5) * tabWidth;

              // Détection de l'icône de bulle à afficher (transition à mi-course)
              final bubbleItemIndex = t < 0.45 ? _fromIndex : _toIndex;
              final safeBubbleIndex = bubbleItemIndex.clamp(0, tabCount - 1);
              final bubbleItem = widget.items[safeBubbleIndex];

              return SizedBox(
                width: totalWidth,
                height: totalBarStackHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // --- 1. La barre en forme de pilule (Glassmorphism) ---
                    Positioned(
                      left: kNavHorizontalMargin,
                      right: kNavHorizontalMargin,
                      bottom: kNavBottomMargin + safeAreaBottom,
                      height: kNavBarHeight,
                      child: _buildGlassmorphicBar(
                        tabWidth: tabWidth,
                        currentFactor: currentFactor,
                        disableAnimations: disableAnimations,
                      ),
                    ),

                    // --- 2. La bulle flottante « Bounce » au-dessus de l'onglet actif ---
                    Positioned(
                      left: bubbleCenterX - (kNavBubbleDiameter * deform.scaleX) / 2,
                      bottom: kNavBottomMargin +
                          safeAreaBottom +
                          kNavBarHeight +
                          kNavBubbleGap +
                          deform.deltaY,
                      child: _buildFloatingBubble(
                        bubbleItem: bubbleItem,
                        scaleX: deform.scaleX,
                        scaleY: deform.scaleY,
                        onTap: () => _handleTap(_activeDisplayIndex),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Construit la pilule de verre dépoli avec flou, lueur et onglets
  Widget _buildGlassmorphicBar({
    required double tabWidth,
    required double currentFactor,
    required bool disableAnimations,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: kNavBlurSigma, sigmaY: kNavBlurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: kNavGlassDarkTeal,
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              border: Border.all(
                color: kNavBorderColor,
                width: 1.0,
              ),
            ),
            child: Stack(
              children: [
                // --- Lueur douce qui suit l'onglet actif ---
                Positioned(
                  left: (currentFactor * tabWidth) - (tabWidth * 0.1),
                  top: 0,
                  bottom: 0,
                  width: tabWidth * 1.2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.85,
                        colors: [
                          Colors.white.withValues(alpha: 0.13),
                          kNavGlowColor,
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),

                // --- Petit point blanc sous le libellé qui glisse vers l'onglet actif ---
                Positioned(
                  left: ((currentFactor + 0.5) * tabWidth) - 2.0,
                  bottom: 7.0,
                  child: Container(
                    width: 4.0,
                    height: 4.0,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 4.0,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                  ),
                ),

                // --- Les 5 onglets tactiles ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(widget.items.length, (index) {
                    final item = widget.items[index];
                    final isSelected = index == _activeDisplayIndex;

                    // Calcul de la distance relative à la bulle pour estomper l'icône dans la barre
                    final relativeDist = (index - currentFactor).abs();
                    final iconOpacity = (relativeDist.clamp(0.0, 1.0)).toDouble();

                    return Expanded(
                      child: Semantics(
                        label: item.label,
                        selected: isSelected,
                        button: true,
                        tooltip: item.tooltip ?? item.label,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                            splashColor: Colors.white.withValues(alpha: 0.12),
                            highlightColor: Colors.white.withValues(alpha: 0.06),
                            onTap: () => _handleTap(index),
                            child: _buildTabContent(
                              item: item,
                              isSelected: isSelected,
                              iconOpacity: iconOpacity,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construit le contenu d'un onglet dans la barre (icône, label et badge éventuel)
  Widget _buildTabContent({
    required BounceNavItem item,
    required bool isSelected,
    required double iconOpacity,
  }) {
    // Si l'onglet est sélectionné, l'icône est dans la bulle au-dessus
    // et le libellé reste centré/visible en blanc net
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Espace pour l'icône qui s'estompe quand la bulle arrive
          SizedBox(
            height: 26,
            child: Opacity(
              opacity: iconOpacity,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  KeyedSubtree(
                    key: item.label == 'Panier' ? CartFlyAnimation.cartNavIconKey : null,
                    child: Icon(
                      item.icon,
                      size: 22,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  // Badge sur l'icône dans la barre (quand l'onglet n'est pas actif)
                  if (item.badgeCount > 0 && !isSelected)
                    Positioned(
                      top: -4,
                      right: -10,
                      child: _buildBadge(item.badgeCount),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 2.0),

          // Libellé de l'onglet
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.65),
              letterSpacing: 0.1,
            ),
          ),

          // Réservation de hauteur pour le point blanc
          const SizedBox(height: 4.0),
        ],
      ),
    );
  }

  /// Construit la bulle flottante de verre dépoli avec reflet, halo et badge
  Widget _buildFloatingBubble({
    required BounceNavItem bubbleItem,
    required double scaleX,
    required double scaleY,
    required VoidCallback onTap,
  }) {
    return Transform.scale(
      scaleX: scaleX,
      scaleY: scaleY,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: kNavBubbleDiameter,
          height: kNavBubbleDiameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                kNavBubbleGradientTop,
                kNavBubbleGradientBottom,
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.40),
              width: 1.2,
            ),
            boxShadow: [
              // Halo lumineux extérieur couleur teal
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.55),
                blurRadius: 18,
                spreadRadius: 1.5,
              ),
              // Ombre portée diffuse
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Léger reflet intérieur en haut de la bulle
              Positioned(
                top: 2,
                left: 10,
                right: 10,
                height: 14,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Icône active avec transition animée douce
              AnimatedSwitcher(
                duration: kNavFastDuration,
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  bubbleItem.selectedIcon,
                  key: ValueKey(bubbleItem.selectedIcon),
                  size: 24,
                  color: Colors.white,
                ),
              ),

              // Badge du panier au coin haut droit de la bulle
              if (bubbleItem.badgeCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: _buildBadge(bubbleItem.badgeCount),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Badge numérique ambre Dokan réutilisable (sur l'icône ou sur la bulle)
  Widget _buildBadge(int count) {
    return _BouncingBadge(count: count);
  }
}

class _BouncingBadge extends StatefulWidget {
  final int count;

  const _BouncingBadge({required this.count});

  @override
  State<_BouncingBadge> createState() => _BouncingBadgeState();
}

class _BouncingBadgeState extends State<_BouncingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 50,
      ),
    ]).animate(_bounceController);

    CartBadgeBounceController.instance.addListener(_onCartBounce);
  }

  void _onCartBounce() {
    if (mounted) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant _BouncingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    CartBadgeBounceController.instance.removeListener(_onCartBounce);
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        constraints: const BoxConstraints(
          minWidth: 18,
          minHeight: 18,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          border: Border.all(
            color: Colors.white,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.count > 99 ? '99+' : '${widget.count}',
            style: const TextStyle(
              color: AppColors.onPrimary,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
