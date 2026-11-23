/// ============================================================================
/// RÔLE DU FICHIER :
/// Service et composant d'animation de vol parabolique d'un article vers l'icône du panier.
///
/// COMPORTEMENT :
/// 1) Clone temporaire de l'image (36 px) inséré dans l'Overlay.
/// 2) Trajectoire en arc de cercle (courbe parabolique) vers l'icône du panier.
/// 3) À l'impact : déclenche un rebond élastique sur le badge du panier (1.0 -> 1.3 -> 1.0).
/// ============================================================================
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Notifier global pour déclencher le rebond du badge du panier à l'atterrissage
class CartBadgeBounceController extends ChangeNotifier {
  static final CartBadgeBounceController instance = CartBadgeBounceController._();
  CartBadgeBounceController._();

  void triggerBounce() {
    notifyListeners();
  }
}

class CartFlyAnimation {
  /// Clé globale pour localiser l'icône du panier dans la barre de navigation
  static final GlobalKey cartNavIconKey = GlobalKey();

  /// Lance l'animation de vol depuis la position du widget de départ [startKey]
  static void runFly({
    required BuildContext context,
    required GlobalKey startKey,
    String? imageUrl,
  }) {
    if (MediaQuery.of(context).disableAnimations) {
      CartBadgeBounceController.instance.triggerBounce();
      return;
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      CartBadgeBounceController.instance.triggerBounce();
      return;
    }

    // 1. Calcul du point de départ
    final startBox = startKey.currentContext?.findRenderObject() as RenderBox?;
    if (startBox == null || !startBox.attached) {
      CartBadgeBounceController.instance.triggerBounce();
      return;
    }
    final startOffset = startBox.localToGlobal(Offset.zero);
    final startCenter = startOffset + Offset(startBox.size.width / 2, startBox.size.height / 2);

    // 2. Calcul du point d'arrivée (icône du panier ou centre-bas de l'écran par défaut)
    final screenSize = MediaQuery.of(context).size;
    Offset targetCenter;
    final navBox = cartNavIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (navBox != null && navBox.attached) {
      final navOffset = navBox.localToGlobal(Offset.zero);
      targetCenter = navOffset + Offset(navBox.size.width / 2, navBox.size.height / 2);
    } else {
      // Destination de secours : 70% largeur, bas de l'écran
      targetCenter = Offset(screenSize.width * 0.70, screenSize.height - 40);
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _FlyingThumbnail(
        start: startCenter,
        target: targetCenter,
        imageUrl: imageUrl,
        onComplete: () {
          entry.remove();
          CartBadgeBounceController.instance.triggerBounce();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _FlyingThumbnail extends StatefulWidget {
  final Offset start;
  final Offset target;
  final String? imageUrl;
  final VoidCallback onComplete;

  const _FlyingThumbnail({
    required this.start,
    required this.target,
    required this.imageUrl,
    required this.onComplete,
  });

  @override
  State<_FlyingThumbnail> createState() => _FlyingThumbnailState();
}

class _FlyingThumbnailState extends State<_FlyingThumbnail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value;

        // Trajectoire parabolique : interpolation linéaire sur X, arc sur Y
        final x = widget.start.dx + (widget.target.dx - widget.start.dx) * t;
        // Hauteur de l'arc (sommet au milieu)
        const arcHeight = 90.0;
        final arcOffset = -arcHeight * 4.0 * t * (1.0 - t);
        final y = widget.start.dy + (widget.target.dy - widget.start.dy) * t + arcOffset;

        // Réduction progressive de la taille de 38 à 14 px
        final size = 38.0 - (24.0 * t);
        // Légère rotation pendant le vol
        final angle = t * math.pi;

        return Positioned(
          left: x - size / 2,
          top: y - size / 2,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: angle,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                      ? Image.network(
                          widget.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.shopping_bag_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.shopping_bag_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
