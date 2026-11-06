/// ============================================================================
/// RÔLE DU FICHIER : Carrousel interactif de bannières pour l'écran d'accueil Dokan.
/// ANIMATIONS : PageView avec viewportFraction 0.88, zoom/opacité voisins,
///              défilement automatique 4s, barre de progression animée dans
///              la pilule active, effet parallaxe et retour tactile haptique.
/// ============================================================================
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

/// Modèle d'affichage d'une bannière publicitaire ou thématique de l'accueil.
class BannerItem {
  final String title;
  final String subtitle;
  final String tag;
  final List<Color> colors;
  final VoidCallback? onTap;

  const BannerItem({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.colors,
    this.onTap,
  });
}

/// Carrousel interactif de bannières avec animations avancées et conformité accessibilité.
class InteractiveBannerCarousel extends StatefulWidget {
  final List<BannerItem> banners;
  final double height;
  final double viewportFraction;
  final Duration autoScrollInterval;
  final Duration transitionDuration;
  final Curve transitionCurve;

  const InteractiveBannerCarousel({
    super.key,
    required this.banners,
    this.height = 160.0,
    this.viewportFraction = 0.88,
    this.autoScrollInterval = const Duration(seconds: 2),
    this.transitionDuration = const Duration(milliseconds: 600),
    this.transitionCurve = Curves.easeInOutCubic,
  });

  @override
  State<InteractiveBannerCarousel> createState() => _InteractiveBannerCarouselState();
}

class _InteractiveBannerCarouselState extends State<InteractiveBannerCarousel>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentIndex = 0;

  // Animation d'entrée unique (fondu + montée fluide de 400 ms)
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Contrôleur de défilement automatique & progression de la pilule (4 s)
  late final AnimationController _progressController;

  // Gestion des interactions utilisateur (toucher/glisser) et cycle de vie
  bool _isUserInteracting = false;
  Timer? _resumeTimer;
  bool _isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pageController = PageController(
      viewportFraction: widget.viewportFraction,
      initialPage: _currentIndex,
    );

    // Initialisation de l'animation d'entrée
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    // Contrôleur de la barre de progression (4 s)
    _progressController = AnimationController(
      vsync: this,
      duration: widget.autoScrollInterval,
    );
    _progressController.addStatusListener(_handleProgressStatus);

    // Démarre l'animation d'entrée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (disableAnimations) {
        _entranceController.value = 1.0;
      } else {
        _entranceController.forward();
        _startAutoScrollIfAllowed();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndSyncPlaybackState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    _checkAndSyncPlaybackState();
  }

  bool get _canAutoPlay {
    if (!mounted || widget.banners.length <= 1) return false;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) return false;
    if (!_isAppInForeground) return false;
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    if (!isCurrentRoute) return false;
    final isTickerEnabled = TickerMode.valuesOf(context).enabled;
    if (!isTickerEnabled) return false;
    return true;
  }

  void _checkAndSyncPlaybackState() {
    if (!_canAutoPlay || _isUserInteracting) {
      _progressController.stop();
    } else {
      if (!_progressController.isAnimating) {
        _progressController.forward();
      }
    }
  }

  void _startAutoScrollIfAllowed() {
    if (_canAutoPlay && !_isUserInteracting) {
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _handleProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (!mounted || !_canAutoPlay || _isUserInteracting) return;
      _advanceToNextBanner();
    }
  }

  void _advanceToNextBanner() {
    if (widget.banners.isEmpty) return;
    final nextIndex = (_currentIndex + 1) % widget.banners.length;
    _pageController.animateToPage(
      nextIndex,
      duration: widget.transitionDuration,
      curve: widget.transitionCurve,
    );
  }

  void _handlePointerDown() {
    _isUserInteracting = true;
    _resumeTimer?.cancel();
    _progressController.stop();
  }

  void _handlePointerUpOrCancel() {
    _isUserInteracting = false;
    _resumeTimer?.cancel();
    // Reprise du défilement automatique avec sa barre de 4s après que l'utilisateur a lâché
    _resumeTimer = Timer(widget.autoScrollInterval, () {
      if (mounted && _canAutoPlay && !_isUserInteracting) {
        _progressController.reset();
        _progressController.forward();
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Réinitialise la progression pour la nouvelle page active
    _progressController.reset();
    if (_canAutoPlay && !_isUserInteracting) {
      _progressController.forward();
    }
  }

  void _onIndicatorTap(int index) {
    if (index == _currentIndex) return;
    _resumeTimer?.cancel();
    _pageController.animateToPage(
      index,
      duration: widget.transitionDuration,
      curve: widget.transitionCurve,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resumeTimer?.cancel();
    _progressController.removeStatusListener(_handleProgressStatus);
    _progressController.dispose();
    _entranceController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return FadeTransition(
      opacity: disableAnimations ? const AlwaysStoppedAnimation(1.0) : _fadeAnimation,
      child: SlideTransition(
        position: disableAnimations ? const AlwaysStoppedAnimation(Offset.zero) : _slideAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Zone du PageView avec gestion tactile fluide ---
            SizedBox(
              height: widget.height,
              child: Listener(
                onPointerDown: (_) => _handlePointerDown(),
                onPointerUp: (_) => _handlePointerUpOrCancel(),
                onPointerCancel: (_) => _handlePointerUpOrCancel(),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.banners.length,
                  onPageChanged: _onPageChanged,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final banner = widget.banners[index];

                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double page = _currentIndex.toDouble();
                        if (_pageController.position.haveDimensions) {
                          page = _pageController.page ?? _currentIndex.toDouble();
                        }

                        final double diff = page - index;
                        final double absDiff = diff.abs().clamp(0.0, 1.0);

                        // Carte centrale : échelle 1.0, voisines : échelle 0.92
                        final double scale = disableAnimations ? 1.0 : (1.0 - (absDiff * (1.0 - 0.92)));
                        // Carte centrale : opacité 1.0, voisines : opacité 0.70
                        final double opacity = disableAnimations ? 1.0 : (1.0 - (absDiff * (1.0 - 0.70)));
                        // Décalage parallaxe : décor décalé plus lentement
                        final double parallaxOffset = disableAnimations ? 0.0 : (-diff * 26.0);

                        return RepaintBoundary(
                          child: Opacity(
                            opacity: opacity.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: scale,
                              child: _BannerCard(
                                banner: banner,
                                index: index,
                                totalCount: widget.banners.length,
                                parallaxOffset: parallaxOffset,
                                disableAnimations: disableAnimations,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space12),

            // --- Indicateurs animés sous le carrousel ---
            Semantics(
              container: true,
              label: 'Indicateurs de bannières',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.banners.length, (index) {
                  final bool isActive = _currentIndex == index;
                  final banner = widget.banners[index];

                  return Semantics(
                    label: 'Bannière ${index + 1} sur ${widget.banners.length} : ${banner.title}',
                    button: true,
                    selected: isActive,
                    child: InkWell(
                      onTap: () => _onIndicatorTap(index),
                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                      child: Container(
                        // Zone tactile conforme d'au moins 48 dp
                        constraints: const BoxConstraints(
                          minWidth: AppDimens.minTouchTarget,
                          minHeight: AppDimens.minTouchTarget,
                        ),
                        alignment: Alignment.center,
                        child: AnimatedContainer(
                          duration: AppDimens.animMedium,
                          curve: Curves.easeOutCubic,
                          width: isActive ? 28.0 : 8.0,
                          height: 8.0,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primarySoft : AppColors.border,
                            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                          ),
                          child: isActive
                              ? AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (context, _) {
                                    final double progress =
                                        disableAnimations ? 1.0 : _progressController.value;
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: progress.clamp(0.0, 1.0),
                                          child: Container(
                                            height: 8.0,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius:
                                                  BorderRadius.circular(AppDimens.radiusFull),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte individuelle d'une bannière avec effet de pression tactile,
/// pastille de compteur discret et décor parallaxe.
class _BannerCard extends StatefulWidget {
  final BannerItem banner;
  final int index;
  final int totalCount;
  final double parallaxOffset;
  final bool disableAnimations;

  const _BannerCard({
    required this.banner,
    required this.index,
    required this.totalCount,
    required this.parallaxOffset,
    required this.disableAnimations,
  });

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    widget.banner.onTap?.call();
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double pressScale = (widget.disableAnimations || !_isPressed) ? 1.0 : 0.97;

    return Semantics(
      label:
          'Bannière ${widget.index + 1} sur ${widget.totalCount} : ${widget.banner.title}, ${widget.banner.subtitle}',
      button: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space8),
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: pressScale,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.banner.colors,
                ),
                borderRadius: BorderRadius.circular(AppDimens.radius16),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radius16),
                child: Stack(
                  children: [
                    // --- Décor géométrique d'arrière-plan avec effet parallaxe ---
                    Positioned(
                      right: -25,
                      top: -25,
                      child: Transform.translate(
                        offset: Offset(widget.parallaxOffset * 0.7, 0),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.onPrimary.withValues(alpha: 0.10),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      bottom: -35,
                      child: Transform.translate(
                        offset: Offset(widget.parallaxOffset * 0.4, 0),
                        child: Container(
                          width: 105,
                          height: 105,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.onPrimary.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    ),

                    // --- Contenu textuel de la bannière ---
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(widget.parallaxOffset * 0.2, 0),
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimens.space20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimens.space8,
                                  vertical: AppDimens.space4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppDimens.radius8),
                                ),
                                child: Text(
                                  widget.banner.tag,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppDimens.space8),
                              Text(
                                widget.banner.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textOnDark,
                                ),
                              ),
                              const SizedBox(height: AppDimens.space4),
                              Text(
                                widget.banner.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textOnDark.withValues(alpha: 0.90),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // --- Pastille discrète de compteur (ex: 1/3) en haut à droite ---
                    Positioned(
                      top: AppDimens.space12,
                      right: AppDimens.space12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.space8,
                          vertical: AppDimens.space4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                        ),
                        child: Text(
                          '${widget.index + 1}/${widget.totalCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
