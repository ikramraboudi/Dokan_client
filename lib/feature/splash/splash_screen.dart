/// ============================================================================
/// RÔLE DU FICHIER :
/// Écran de démarrage animé (Splash Screen) officiel Dokan.
///
/// SÉQUENCE CINÉMATIQUE (3200 ms) :
/// 1) 0.0 - 0.9s : Chariot stylisé (CustomPainter) entrant depuis la gauche jusqu'au centre.
/// 2) 0.9 - 1.6s : 4 objets stylisés (boîte, sac, fruit, étoile) lancés en arc dans le chariot
///                 avec étincelles blanches à l'impact.
/// 3) 1.6 - 2.3s : Transformation en panier de livraison avec rebond squash & stretch élastique.
/// 4) 2.2 - 2.8s : Apparition du texte « Dokan » et slogan « Vos achats, livrés chez vous ».
/// 5) 2.8 - 3.2s : Voile blanc courbé montant du bas de l'écran révélant l'accueil.
/// ============================================================================
library;

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_summary.dart';

// --- Constantes configurables ---
const String kSplashTagline = 'Vos achats, livrés chez vous';
const int kSplashDurationMs = 3200;
const int kMinWaitBeforeNavMs = 2800;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Phases temporelles normalisées (0.0 à 1.0 sur 3200 ms)
  // 1. Chariot (0.0 -> 0.28)
  late final Animation<double> _cartSlide;
  late final Animation<double> _cartTilt;
  late final Animation<double> _cartWheelRotation;

  // 2. Objets lancés (0.28 -> 0.50)
  late final Animation<double> _item1Arc;
  late final Animation<double> _item2Arc;
  late final Animation<double> _item3Arc;
  late final Animation<double> _item4Arc;

  // 3. Panier / sac (0.50 -> 0.72)
  late final Animation<double> _basketScale;
  late final Animation<double> _basketSquashX;
  late final Animation<double> _basketSquashY;

  // 4. Texte Dokan & Slogan (0.68 -> 0.88)
  late final Animation<double> _textOpacity;
  late final Animation<double> _textSlide;
  late final Animation<double> _taglineOpacity;

  // 5. Voile blanc de sortie (0.875 -> 1.0)
  late final Animation<double> _curvedVeilProgress;

  bool _sessionReady = false;
  bool _minDurationPassed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kSplashDurationMs),
    );

    _initAnimations();

    _ctrl.forward().then((_) {
      if (mounted) {
        _minDurationPassed = true;
        _tryNavigate();
      }
    });

    // Seuil minimal pour la navigation
    Future.delayed(const Duration(milliseconds: kMinWaitBeforeNavMs), () {
      if (mounted) {
        _minDurationPassed = true;
        _tryNavigate();
      }
    });

    // Vérification de session en tâche de fond
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  void _initAnimations() {
    // Phase 1 : Chariot de gauche à centre
    _cartSlide = Tween<double>(begin: -1.3, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.28, curve: Curves.easeOutCubic),
      ),
    );

    _cartTilt = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -0.06).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.06, end: 0.04).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.04, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.28)),
    );

    _cartWheelRotation = Tween<double>(begin: 0.0, end: 6.0 * math.pi).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.28, curve: Curves.linear),
      ),
    );

    // Phase 2 : Objets lancés (0.28 à 0.50)
    _item1Arc = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.28, 0.36, curve: Curves.easeInOut),
    );
    _item2Arc = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.32, 0.40, curve: Curves.easeInOut),
    );
    _item3Arc = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.36, 0.44, curve: Curves.easeInOut),
    );
    _item4Arc = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.40, 0.48, curve: Curves.easeInOut),
    );

    // Phase 3 : Panier de livraison rebondissant (0.50 à 0.72)
    _basketScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.50, 0.68, curve: Curves.elasticOut),
      ),
    );

    _basketSquashX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 0.90), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.50, 0.70)),
    );

    _basketSquashY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.75), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.12), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.50, 0.70)),
    );

    // Phase 4 : Texte et slogan (0.68 à 0.88)
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.68, 0.80, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<double>(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.68, 0.82, curve: Curves.easeOut),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.78, 0.90, curve: Curves.easeIn),
      ),
    );

    // Phase 5 : Voile blanc courbé montant (0.875 à 1.0)
    _curvedVeilProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.875, 1.0, curve: Curves.easeInOutCubic),
      ),
    );
  }

  Future<void> _checkSession() async {
    try {
      final auth = FirebaseAuth.instance;
      final firebaseUser = auth.currentUser ??
          await auth.authStateChanges().first.timeout(
                const Duration(seconds: 3),
                onTimeout: () => null,
              );

      if (firebaseUser != null && mounted) {
        String? phone;
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .get();
          phone = doc.data()?['phone'] as String?;
        } catch (_) {}

        final displayName = (firebaseUser.displayName != null &&
                firebaseUser.displayName!.isNotEmpty)
            ? firebaseUser.displayName!
            : (firebaseUser.email?.split('@').first ?? 'Client');

        ref.read(sessionProvider.notifier).loginSuccess(
              UserSummary(
                fullName: displayName,
                email: firebaseUser.email ?? '',
                phone: phone,
              ),
              userId: firebaseUser.uid,
            );
      } else if (mounted) {
        ref.read(sessionProvider.notifier).logout();
      }
    } catch (_) {
      if (mounted) {
        ref.read(sessionProvider.notifier).logout();
      }
    } finally {
      if (mounted) {
        _sessionReady = true;
        _tryNavigate();
      }
    }
  }

  void _tryNavigate() {
    if (!_sessionReady || !_minDurationPassed || _navigated || !mounted) return;
    _navigated = true;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.shopping_bag_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Dokan',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                kSplashTagline,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fond turquoise officiel Dokan (AppColors.primary)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF288585), // Turquoise lumineux
                  AppColors.primary,  // Color(0xFF1F7A7A) Identité officielle Dokan
                  Color(0xFF0D2B2F), // Vert-canard profond / bleu pétrole
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. Scène animée principale
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Phase 1 & 2 : Chariot stylisé + Objets en vol
                  if (_ctrl.value < 0.65)
                    _buildCartAndFlyingItems(),

                  // Phase 3 & 4 : Sac de livraison + Titre Dokan
                  if (_ctrl.value >= 0.48)
                    _buildBasketAndLogo(),
                ],
              );
            },
          ),

          // 3. Voile blanc montant à bord courbé révélant l'accueil
          AnimatedBuilder(
            animation: _curvedVeilProgress,
            builder: (context, child) {
              if (_curvedVeilProgress.value <= 0.001) return const SizedBox.shrink();
              return ClipPath(
                clipper: _CurvedRisingClipper(_curvedVeilProgress.value),
                child: Container(
                  color: Colors.white,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Construit le chariot stylisé et les 4 objets en vol
  Widget _buildCartAndFlyingItems() {
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final centerY = size.height * 0.44;

    final cartFade = (1.0 - ((_ctrl.value - 0.48) / 0.12)).clamp(0.0, 1.0);

    return Opacity(
      opacity: cartFade,
      child: Stack(
        children: [
          // Chariot se déplaçant horizontalement
          Positioned(
            left: centerX + (_cartSlide.value * size.width) - 60,
            top: centerY - 45,
            child: Transform.rotate(
              angle: _cartTilt.value,
              child: CustomPaint(
                size: const Size(120, 90),
                painter: _StylizedCartPainter(
                  wheelRotation: _cartWheelRotation.value,
                ),
              ),
            ),
          ),

          // 4 Objets volants en cloche
          if (_item1Arc.value > 0.0)
            _buildFlyingItem(
              target: Offset(centerX - 20, centerY + 10),
              progress: _item1Arc.value,
              color: const Color(0xFFFFB300), // Boîte dorée
              isBox: true,
            ),
          if (_item2Arc.value > 0.0)
            _buildFlyingItem(
              target: Offset(centerX + 5, centerY + 5),
              progress: _item2Arc.value,
              color: const Color(0xFFE53935), // Pomme/fruit rouge
              isFruit: true,
            ),
          if (_item3Arc.value > 0.0)
            _buildFlyingItem(
              target: Offset(centerX - 10, centerY - 5),
              progress: _item3Arc.value,
              color: const Color(0xFF26A69A), // Petit sac vert-d'eau
              isBag: true,
            ),
          if (_item4Arc.value > 0.0)
            _buildFlyingItem(
              target: Offset(centerX + 18, centerY + 12),
              progress: _item4Arc.value,
              color: const Color(0xFFFFEB3B), // Étoile dorée
              isStar: true,
            ),
        ],
      ),
    );
  }

  Widget _buildFlyingItem({
    required Offset target,
    required double progress,
    required Color color,
    bool isBox = false,
    bool isFruit = false,
    bool isBag = false,
    bool isStar = false,
  }) {
    final start = Offset(target.dx + 110, target.dy - 120);
    final x = start.dx + (target.dx - start.dx) * progress;
    final arc = -55.0 * 4.0 * progress * (1.0 - progress);
    final y = start.dy + (target.dy - start.dy) * progress + arc;

    // À l'arrivée (progress > 0.85) : petites étincelles blanches
    final clampedProgress = progress.clamp(0.0, 1.0);
    final sparkOpacity = clampedProgress > 0.85
        ? ((clampedProgress - 0.85) / 0.15).clamp(0.0, 1.0)
        : 0.0;

    return Positioned(
      left: x - 10,
      top: y - 10,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.rotate(
            angle: clampedProgress * math.pi * 2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                shape: (isFruit || isStar) ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isBox ? BorderRadius.circular(4) : (isBag ? BorderRadius.circular(5) : null),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: isStar
                  ? const Icon(Icons.star_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          if (sparkOpacity > 0.0 && sparkOpacity <= 1.0)
            Positioned(
              left: -4,
              top: -4,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: (1.0 - sparkOpacity).clamp(0.0, 1.0),
                    ),
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Construit le sac de livraison qui rebondit et le nom Dokan
  Widget _buildBasketAndLogo() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Panier/sac de livraison rebondissant
          Transform.scale(
            scaleX: (math.max(0.0, _basketScale.value) * _basketSquashX.value).clamp(0.0, 3.0),
            scaleY: (math.max(0.0, _basketScale.value) * _basketSquashY.value).clamp(0.0, 3.0),
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Forme élégante du panier / sac
                  const Icon(
                    Icons.shopping_bag_rounded,
                    size: 52,
                    color: AppColors.primary,
                  ),
                  // Petits points lumineux au-dessus
                  Positioned(
                    top: 14,
                    right: 18,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB300),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Titre « Dokan » qui glisse et s'affiche
          Transform.translate(
            offset: Offset(0, _textSlide.value),
            child: Opacity(
              opacity: _textOpacity.value.clamp(0.0, 1.0),
              child: const Text(
                'Dokan',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Slogan Dokan
          Opacity(
            opacity: _taglineOpacity.value.clamp(0.0, 1.0),
            child: const Text(
              kSplashTagline,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clipper pour le voile blanc montant avec bordure supérieure subtilement courbe
class _CurvedRisingClipper extends CustomClipper<Path> {
  final double progress; // 0.0 à 1.0

  _CurvedRisingClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    final clampedP = progress.clamp(0.0, 1.0);
    final topY = size.height * (1.0 - clampedP);
    const curveDepth = 40.0;

    path.moveTo(0, topY);
    // Courbe convexe élégante
    path.quadraticBezierTo(
      size.width / 2,
      topY - (curveDepth * (1.0 - clampedP * 0.5)),
      size.width,
      topY,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant _CurvedRisingClipper oldClipper) =>
      oldClipper.progress != progress;
}

/// Painter original pour le chariot stylisé
class _StylizedCartPainter extends CustomPainter {
  final double wheelRotation;

  _StylizedCartPainter({required this.wheelRotation});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. Cadre du chariot
    final bodyPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.20) // Poignée
      ..lineTo(size.width * 0.28, size.height * 0.35)
      ..lineTo(size.width * 0.85, size.height * 0.35) // Bord haut panier
      ..lineTo(size.width * 0.72, size.height * 0.70) // Fond panier
      ..lineTo(size.width * 0.30, size.height * 0.70)
      ..close();

    canvas.drawPath(bodyPath, linePaint);

    // Grillage interne décoratif
    canvas.drawLine(
      Offset(size.width * 0.44, size.height * 0.35),
      Offset(size.width * 0.40, size.height * 0.70),
      linePaint..strokeWidth = 1.8,
    );
    canvas.drawLine(
      Offset(size.width * 0.60, size.height * 0.35),
      Offset(size.width * 0.55, size.height * 0.70),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.26, size.height * 0.52),
      Offset(size.width * 0.78, size.height * 0.52),
      linePaint,
    );

    // 2. Châssis roues
    linePaint.strokeWidth = 3.0;
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.70),
      Offset(size.width * 0.35, size.height * 0.82),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.68, size.height * 0.70),
      Offset(size.width * 0.68, size.height * 0.82),
      linePaint,
    );

    // 3. Roues stylisées avec rayons qui tournent
    _drawWheel(canvas, Offset(size.width * 0.35, size.height * 0.85), 8.0);
    _drawWheel(canvas, Offset(size.width * 0.68, size.height * 0.85), 8.0);
  }

  void _drawWheel(Canvas canvas, Offset center, double radius) {
    final ringPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, 2.5, Paint()..color = Colors.white);

    // Rayons tournants
    final spokeLength = radius - 1.5;
    for (int i = 0; i < 4; i++) {
      final angle = wheelRotation + (i * math.pi / 2);
      final p2 = Offset(
        center.dx + math.cos(angle) * spokeLength,
        center.dy + math.sin(angle) * spokeLength,
      );
      canvas.drawLine(center, p2, Paint()..color = Colors.white..strokeWidth = 1.4);
    }
  }

  @override
  bool shouldRepaint(covariant _StylizedCartPainter oldDelegate) =>
      oldDelegate.wheelRotation != wheelRotation;
}
