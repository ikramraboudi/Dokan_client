/// ============================================================================
/// RÔLE DU FICHIER :
/// Bouton interactif « Glisser pour confirmer » (« SlideToConfirmButton »)
/// pour la validation finale de la commande.
///
/// COMPORTEMENTS :
/// 1) Pastille blanche circulaire que l'utilisateur fait glisser vers la droite.
/// 2) Remplissage dynamique et estompement du texte pendant le glissement.
/// 3) Rebond élastique si relâché avant 85 % de la course.
/// 4) Verrouillage à 85 %, vibration haptique moyenne et passage en spinner de chargement.
/// 5) Double toucher et accessibilité Semantics intégrés pour les lecteurs d'écran.
/// 6) Retour au départ automatique en cas d'échec de commande (erreur réseau).
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

class SlideToConfirmButton extends StatefulWidget {
  final double total;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onConfirm;

  const SlideToConfirmButton({
    super.key,
    required this.total,
    required this.isLoading,
    required this.onConfirm,
    this.enabled = true,
  });

  @override
  State<SlideToConfirmButton> createState() => _SlideToConfirmButtonState();
}

class _SlideToConfirmButtonState extends State<SlideToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _resetController;
  late Animation<double> _resetAnimation;

  double _dragX = 0.0;
  bool _isConfirmed = false;

  static const double _buttonHeight = 60.0;
  static const double _thumbSize = 48.0;
  static const double _padding = 6.0;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(covariant SlideToConfirmButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si le chargement prend fin sans départ de l'écran (ex: erreur de validation),
    // réinitialiser la pastille vers le début avec un rebond
    if (oldWidget.isLoading && !widget.isLoading && _isConfirmed) {
      _resetThumb();
    }
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _resetThumb() {
    _resetAnimation = Tween<double>(
      begin: _dragX,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _resetController,
        curve: Curves.elasticOut,
      ),
    )..addListener(() {
        setState(() {
          _dragX = _resetAnimation.value;
        });
      });

    setState(() {
      _isConfirmed = false;
    });

    _resetController.forward(from: 0.0);
  }

  void _triggerConfirm() {
    if (!widget.enabled || widget.isLoading || _isConfirmed) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isConfirmed = true;
    });
    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    // Mode accessibilité ou animations désactivées
    if (MediaQuery.of(context).disableAnimations) {
      return SizedBox(
        width: double.infinity,
        height: _buttonHeight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
            ),
          ),
          onPressed: (widget.enabled && !widget.isLoading) ? _triggerConfirm : null,
          child: widget.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  'Confirmer la commande · ${AppConfig.formatPrice(widget.total)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _thumbSize - (_padding * 2);
        final progress = maxDrag > 0 ? (_dragX / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Semantics(
          label: 'Confirmer la commande · ${AppConfig.formatPrice(widget.total)}',
          button: true,
          enabled: widget.enabled && !widget.isLoading,
          onTap: (widget.enabled && !widget.isLoading) ? _triggerConfirm : null,
          child: GestureDetector(
            // Double-toucher de secours pour accessibilité
            onDoubleTap: (widget.enabled && !widget.isLoading) ? _triggerConfirm : null,
            child: Container(
              height: _buttonHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                gradient: LinearGradient(
                  colors: widget.enabled
                      ? [
                          AppColors.primary,
                          AppColors.primaryDark,
                        ]
                      : [
                          Colors.grey.shade400,
                          Colors.grey.shade500,
                        ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: widget.enabled
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Remplissage animé qui suit la pastille
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: _padding + _dragX + (_thumbSize / 2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                      ),
                    ),
                  ),

                  // Texte central qui s'estompe avec l'avancement
                  Center(
                    child: Opacity(
                      opacity: (1.0 - progress * 1.6).clamp(0.0, 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 56.0),
                        child: Text(
                          'Glisser pour confirmer · ${AppConfig.formatPrice(widget.total)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Pastille blanche glissable
                  Positioned(
                    left: _padding + (widget.isLoading ? maxDrag : _dragX),
                    child: GestureDetector(
                      onHorizontalDragUpdate: (widget.enabled && !widget.isLoading && !_isConfirmed)
                          ? (details) {
                              if (_resetController.isAnimating) {
                                _resetController.stop();
                              }
                              setState(() {
                                _dragX = (_dragX + details.delta.dx).clamp(0.0, maxDrag);
                              });
                            }
                          : null,
                      onHorizontalDragEnd: (widget.enabled && !widget.isLoading && !_isConfirmed)
                          ? (details) {
                              if (progress >= 0.85) {
                                setState(() {
                                  _dragX = maxDrag;
                                });
                                _triggerConfirm();
                              } else {
                                _resetThumb();
                              }
                            }
                          : null,
                      child: Container(
                        width: _thumbSize,
                        height: _thumbSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: (widget.isLoading || _isConfirmed)
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
