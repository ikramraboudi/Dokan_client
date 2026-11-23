/// ============================================================================
/// RÔLE DU FICHIER :
/// Écran « Confirmation de commande » après création réussie dans Firestore.
///
/// DESIGN ET SÉQUENCE CINÉMATIQUE :
/// 1) Fond vert plein (gradient Dokan).
/// 2) Cercle blanc expansif avec explosion de 25-30 particules colorées.
/// 3) Grande coche blanche animée dans un cercle (tracé progressif + rebond).
/// 4) Titre « Commande confirmée ! » et texte court de remerciement.
/// 5) Carte de résumé translucide (Numéro DK-AAMMJJ-XXXX, adresse, paiement, total).
/// 6) Bouton blanc en pilule « Suivre ma commande » et lien discret « Continuer mes achats ».
/// ============================================================================
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/navigation/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/repositories/firestore_orders_repository.dart';

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends ConsumerState<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  // 1. Particules d'explosion (0.10 -> 0.45)
  late final Animation<double> _particlesProgress;
  // 3. Tracé de la coche et rebond du cercle (0.25 -> 0.65)
  late final Animation<double> _checkStroke;
  late final Animation<double> _checkScale;
  // 4. Titre et carte translucide (0.55 -> 0.90)
  late final Animation<double> _contentFade;
  late final Animation<double> _contentSlide;

  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _particlesProgress = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.08, 0.45, curve: Curves.easeOutQuad),
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.22, 0.50, curve: Curves.elasticOut),
      ),
    );

    _checkStroke = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.35, 0.65, curve: Curves.easeInOut),
      ),
    );

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.55, 0.85, curve: Curves.easeIn),
      ),
    );

    _contentSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _generateParticles();
    _animCtrl.forward();
  }

  void _generateParticles() {
    final rng = math.Random();
    const colors = [
      Colors.white,
      Color(0xFFFFD54F),
      Color(0xFF81C784),
      Color(0xFFFF8A65),
      Color(0xFF4DD0E1),
    ];

    for (int i = 0; i < 28; i++) {
      final angle = (i / 28.0) * math.pi * 2 + (rng.nextDouble() * 0.2);
      final speed = 80.0 + rng.nextDouble() * 120.0;
      final size = 4.0 + rng.nextDouble() * 5.0;
      final color = colors[rng.nextInt(colors.length)];
      _particles.add(
        _ConfettiParticle(
          angle: angle,
          speed: speed,
          size: size,
          color: color,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(singleOrderStreamProvider(widget.orderId));
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Fond turquoise plein officiel Dokan
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF288585), // Turquoise lumineux
                    AppColors.primary,  // 0xFF1F7A7A Identité officielle Dokan
                    Color(0xFF0D2B2F), // Vert-canard profond / bleu pétrole
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // 2. Particules d'explosion
            if (!disableAnimations)
              AnimatedBuilder(
                animation: _particlesProgress,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ParticlesPainter(
                      particles: _particles,
                      progress: _particlesProgress.value,
                    ),
                  );
                },
              ),

            // 3. Contenu principal
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space24,
                    vertical: AppDimens.space16,
                  ),
                  child: orderAsync.when(
                    loading: () => const CircularProgressIndicator(color: Colors.white),
                    error: (err, stack) => _buildErrorFallback(),
                    data: (order) {
                      final displayNumber = order?.displayNumber ?? widget.orderId;
                      final total = order?.total ?? 0.0;
                      final addressSummary = order?.deliveryAddress.summary ?? 'Tunisie';
                      final recipient = order?.deliveryAddress.recipientName ?? '';

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ── Grande coche blanche animée dans un cercle ─────────
                          if (disableAnimations)
                            _buildStaticCheckmark()
                          else
                            AnimatedBuilder(
                              animation: _animCtrl,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _checkScale.value,
                                  child: CustomPaint(
                                    size: const Size(96, 96),
                                    painter: _AnimatedCheckPainter(
                                      strokeProgress: _checkStroke.value,
                                    ),
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: AppDimens.space20),

                          // ── Titre et message de succès ─────────────────────────
                          _buildAnimatedContent(
                            disableAnimations: disableAnimations,
                            child: Column(
                              children: [
                                const Text(
                                  'Commande confirmée !',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: AppDimens.space8),
                                const Text(
                                  'Merci pour votre confiance. Votre commande est en cours de préparation.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: AppDimens.space24),

                                // ── Carte de résumé translucide ───────────────────
                                Container(
                                  padding: const EdgeInsets.all(AppDimens.space20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppDimens.radius20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.20),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'NUMÉRO DE COMMANDE',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: AppDimens.space6),
                                      SelectableText(
                                        displayNumber,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      Divider(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        height: AppDimens.space24,
                                      ),

                                      // Détails : Adresse, Mode de paiement, Total
                                      _buildTranslucentRow(
                                        icon: Icons.location_on_outlined,
                                        label: 'Livraison à',
                                        value: recipient.isNotEmpty
                                            ? '$recipient\n$addressSummary'
                                            : addressSummary,
                                      ),
                                      const SizedBox(height: AppDimens.space12),
                                      _buildTranslucentRow(
                                        icon: Icons.payments_outlined,
                                        label: 'Mode de paiement',
                                        value: 'Paiement à la livraison',
                                      ),
                                      const SizedBox(height: AppDimens.space12),
                                      _buildTranslucentRow(
                                        icon: Icons.receipt_outlined,
                                        label: 'Total réglé',
                                        value: AppConfig.formatPrice(total),
                                        isBold: true,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: AppDimens.space24),

                                // ── Bouton blanc en pilule « Suivre ma commande » ──
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primary,
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(AppDimens.radiusFull),
                                      ),
                                    ),
                                    onPressed: () {
                                      context.push('${AppRoutes.myOrders}/${widget.orderId}');
                                    },
                                    child: const Text(
                                      'Suivre ma commande',
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: AppDimens.space12),

                                // ── Lien discret « Continuer mes achats » ──────────
                                TextButton(
                                  onPressed: () => context.go(AppRoutes.home),
                                  child: const Text(
                                    'Continuer mes achats',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildAnimatedContent({
    required Widget child,
    required bool disableAnimations,
  }) {
    if (disableAnimations) return child;
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, _) {
        return Opacity(
          opacity: _contentFade.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, _contentSlide.value),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildStaticCheckmark() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: const Icon(Icons.check_rounded, size: 54, color: Colors.white),
    );
  }

  Widget _buildTranslucentRow({
    required IconData icon,
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: AppDimens.space10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isBold ? 15 : 13.5,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorFallback() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, size: 72, color: Colors.white),
        const SizedBox(height: AppDimens.space16),
        const Text(
          'Commande enregistrée !',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimens.space16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
          ),
          onPressed: () => context.go(AppRoutes.home),
          child: const Text('Retour à l\'accueil'),
        ),
      ],
    );
  }
}

class _ConfettiParticle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  const _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ParticlesPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height * 0.28);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final distance = p.speed * progress;
      final x = center.dx + math.cos(p.angle) * distance;
      // Ajout d'une gravité subtile sur Y
      final y = center.dy + math.sin(p.angle) * distance + (progress * progress * 35.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), p.size * (1.0 - progress * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _AnimatedCheckPainter extends CustomPainter {
  final double strokeProgress;

  _AnimatedCheckPainter({required this.strokeProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Cercle extérieur blanc
    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius - 2, fillPaint);
    canvas.drawCircle(center, radius - 2, circlePaint);

    // 2. Tracé progressif de la coche blanche
    if (strokeProgress > 0.0) {
      final checkPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final p1 = Offset(size.width * 0.28, size.height * 0.52);
      final p2 = Offset(size.width * 0.44, size.height * 0.68);
      final p3 = Offset(size.width * 0.72, size.height * 0.38);

      final fullPath = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy);

      for (final metric in fullPath.computeMetrics()) {
        final extract = metric.extractPath(0.0, metric.length * strokeProgress);
        canvas.drawPath(extract, checkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedCheckPainter oldDelegate) =>
      oldDelegate.strokeProgress != strokeProgress;
}
