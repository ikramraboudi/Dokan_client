/// ============================================================================
/// RÔLE DU FICHIER :
/// Peintre vectoriel cinématique officiel pour l'écran de démarrage Dokan.
/// Dessine en pur Flutter CustomPainter (formes géométriques, courbes de Bézier,
/// strokes et fills) sans aucune dépendance externe ni ressource image :
///
/// 1) Ligne blanche fine au sol
/// 2) Stand de boutique (auvent rayé blanc et orange, étagères, enseigne Dokan)
/// 3) Personnage Dokan original (casquette turquoise & orange, veste blanche
///    à bande colorée, pantalon foncé, foulées animées) + chariot filaire blanc
/// 4) 5 produits en cloche parabolique (boîte cadeau, t-shirt, basket, phone,
///    écouteurs) avec étincelles blanches en rayons à l'impact
/// 5) Course d'accélération avec traits de vitesse, nuage de poussière et
///    répliques fantômes semi-transparentes
/// 6) Grand sac de courses en papier Dokan (contour tracé, squash & stretch,
///    ombre ovale au sol)
/// 7) 3 produits phares jaillissant du sac avec étoiles scintillantes
/// ============================================================================
library;

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Peintre cinématique central pour SplashScreen Dokan
class SplashCinematicPainter extends CustomPainter {
  /// Progression globale normalisée (0.0 à 1.0 sur les 4500 ms de l'animation)
  final double progress;

  /// Décalage vertical du sac lors de la révélation du texte
  final double bagRiseY;

  /// Palette Dokan
  static const Color kTurquoisePrimary = AppColors.primary; // 0xFF1F7A7A
  static const Color kTurquoiseDark = AppColors.primaryDark; // 0xFF155B5E
  static const Color kTurquoiseLight = Color(0xFF38A3A5);
  static const Color kOrangeAccent = Color(0xFFFF9800);
  static const Color kWarmPaper = Color(0xFFFAF6EE);
  static const Color kWarmPaperSide = Color(0xFFEFE6D5);
  static const Color kCordColor = Color(0xFFD1C5B2);
  static const Color kPantsDark = Color(0xFF192A2D);

  SplashCinematicPainter({
    required this.progress,
    this.bagRiseY = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clampedP = progress.clamp(0.0, 1.0);
    final groundY = size.height * 0.65;

    // --- PHASE 1 & 2 : Ligne au sol, Stand et Personnage + Chariot ---
    if (clampedP >= 0.066 && clampedP < 0.60) {
      _drawGroundLine(canvas, size, groundY, clampedP);
      _drawStand(canvas, size, groundY, clampedP);
      _drawCharacterAndCartSequence(canvas, size, groundY, clampedP);
    }

    // --- PHASE 5 & 6 : Grand Sac Dokan + Produits jaillissants ---
    if (clampedP >= 0.56) {
      _drawBagSequence(canvas, size, groundY, clampedP);
    }
  }

  // ==========================================================================
  // 1. LIGNE AU SOL
  // ==========================================================================
  void _drawGroundLine(Canvas canvas, Size size, double groundY, double p) {
    // Dessinée de gauche à droite entre 0.067 et 0.18
    final lineP = ((p - 0.066) / 0.12).clamp(0.0, 1.0);
    if (lineP <= 0.0) return;

    // Disparition progressive vers 0.54 - 0.60
    final fadeOut = p >= 0.52 ? (1.0 - ((p - 0.52) / 0.08)).clamp(0.0, 1.0) : 1.0;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85 * fadeOut)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final startX = 0.0;
    final endX = size.width * lineP;

    canvas.drawLine(Offset(startX, groundY), Offset(endX, groundY), paint);

    // Ligne pointillée décorative subtile en dessous
    if (lineP > 0.4) {
      final subPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35 * fadeOut)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      const step = 14.0;
      for (double x = 20.0; x < endX - 10; x += step) {
        canvas.drawLine(
          Offset(x, groundY + 5),
          Offset(x + 7.0, groundY + 5),
          subPaint,
        );
      }
    }
  }

  // ==========================================================================
  // 2. STAND DE BOUTIQUE DOKAN (Comptoir, auvent rayé blanc & orange, étagères)
  // ==========================================================================
  void _drawStand(Canvas canvas, Size size, double groundY, double p) {
    // Glisse depuis la droite entre 0.067 et 0.222
    // Reste fixe entre 0.222 et 0.444
    // Glisse et sort à droite entre 0.444 et 0.578
    final enterP = ((p - 0.066) / 0.15).clamp(0.0, 1.0);
    final curvedEnter = Curves.easeOutCubic.transform(enterP);

    double exitOffset = 0.0;
    double standOpacity = 1.0;
    if (p >= 0.444) {
      final exitP = ((p - 0.444) / 0.12).clamp(0.0, 1.0);
      final curvedExit = Curves.easeInQuad.transform(exitP);
      exitOffset = curvedExit * (size.width * 0.7);
      standOpacity = (1.0 - exitP).clamp(0.0, 1.0);
    }

    if (standOpacity <= 0.0) return;

    final targetX = size.width * 0.74;
    final startX = size.width + 120;
    final standX = startX + (targetX - startX) * curvedEnter + exitOffset;
    final standY = groundY - 110;

    canvas.save();
    canvas.translate(standX, standY);

    // 1. Comptoir (Base en bois clair / crème)
    final counterRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-35, 60, 70, 50),
      const Radius.circular(6),
    );
    final counterPaint = Paint()
      ..color = const Color(0xFFF0E5D3).withValues(alpha: standOpacity);
    canvas.drawRRect(counterRect, counterPaint);

    // Lignes verticales de lattes de bois sur le comptoir
    final slatPaint = Paint()
      ..color = const Color(0xFFD6C7B2).withValues(alpha: standOpacity)
      ..strokeWidth = 1.5;
    for (double lx = -25; lx <= 25; lx += 12) {
      canvas.drawLine(Offset(lx, 62), Offset(lx, 108), slatPaint);
    }

    // Plateau du comptoir
    final topRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-40, 54, 80, 8),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      topRect,
      Paint()..color = Colors.white.withValues(alpha: standOpacity),
    );

    // 2. Étagère arrière avec articles (boîtes colorées & pots)
    final shelfPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9 * standOpacity)
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(-30, 36), const Offset(30, 36), shelfPaint);

    // Articles sur l'étagère
    final boxPaint1 = Paint()
      ..color = kOrangeAccent.withValues(alpha: standOpacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-26, 22, 14, 14), const Radius.circular(2)),
      boxPaint1,
    );
    final boxPaint2 = Paint()
      ..color = kTurquoisePrimary.withValues(alpha: standOpacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-8, 18, 12, 18), const Radius.circular(2)),
      boxPaint2,
    );
    final boxPaint3 = Paint()
      ..color = Colors.white.withValues(alpha: 0.8 * standOpacity);
    canvas.drawCircle(const Offset(16, 28), 6, boxPaint3);

    // 3. Montants métalliques de l'auvent
    final polePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75 * standOpacity)
      ..strokeWidth = 2.2;
    canvas.drawLine(const Offset(-34, 54), const Offset(-34, 2), polePaint);
    canvas.drawLine(const Offset(34, 54), const Offset(34, 2), polePaint);

    // 4. Auvent rayé blanc et orange (5 rayures avec festons arrondis)
    final stripeWidth = 16.0;
    const awningTop = -8.0;
    const awningBottom = 16.0;
    const totalAwningWidth = 80.0;
    const leftAwning = -totalAwningWidth / 2;

    for (int i = 0; i < 5; i++) {
      final sx = leftAwning + (i * stripeWidth);
      final isOrange = i % 2 == 1;
      final stripePaint = Paint()
        ..color = (isOrange ? kOrangeAccent : Colors.white).withValues(alpha: standOpacity)
        ..style = PaintingStyle.fill;

      final stripePath = Path()
        ..moveTo(sx, awningTop)
        ..lineTo(sx + stripeWidth, awningTop)
        ..lineTo(sx + stripeWidth, awningBottom)
        // Feston courbé en bas
        ..quadraticBezierTo(
          sx + (stripeWidth / 2),
          awningBottom + 6.0,
          sx,
          awningBottom,
        )
        ..close();

      canvas.drawPath(stripePath, stripePaint);
    }

    // Bord supérieur de l'auvent
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: standOpacity)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-42, awningTop), const Offset(42, awningTop), rimPaint);

    // Petite enseigne "Dokan" suspendue sous l'auvent
    final signRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-16, -20, 32, 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      signRect,
      Paint()..color = kTurquoisePrimary.withValues(alpha: standOpacity),
    );
    // Petit point doré sur l'enseigne
    canvas.drawCircle(
      const Offset(0, -14),
      2.5,
      Paint()..color = Colors.white.withValues(alpha: standOpacity),
    );

    canvas.restore();
  }

  // ==========================================================================
  // 3. PERSONNAGE DOKAN & CHARIOT DE COURSES (+ COURSE & OBJETS VOLANTS)
  // ==========================================================================
  void _drawCharacterAndCartSequence(Canvas canvas, Size size, double groundY, double p) {
    // Positions clés :
    // Entrée : x de -140 à (size.width * 0.28) entre 0.066 et 0.222
    // Arrêt devant le stand : 0.222 à 0.444
    // Course rapide vers la droite : 0.444 à 0.578
    final enterP = ((p - 0.066) / 0.15).clamp(0.0, 1.0);
    final curvedEnter = Curves.easeOutCubic.transform(enterP);

    final stopX = size.width * 0.28;
    const startX = -130.0;

    double charX = startX + (stopX - startX) * curvedEnter;
    bool isRunning = false;
    double runPhase = 0.0;
    double dashOpacity = 1.0;

    if (p >= 0.444) {
      isRunning = true;
      runPhase = ((p - 0.444) / 0.13).clamp(0.0, 1.0);
      final curvedRun = Curves.easeInCubic.transform(runPhase);
      charX = stopX + (curvedRun * (size.width + 160));
      dashOpacity = (1.0 - ((runPhase - 0.7) / 0.3)).clamp(0.0, 1.0);
    }

    if (dashOpacity <= 0.0) return;

    // Déterminer les objets actuellement dans le chariot (remplissage progressif)
    final itemsInCart = <int>[];
    if (p >= 0.266) itemsInCart.add(0); // Cadeau
    if (p >= 0.311) itemsInCart.add(1); // T-shirt
    if (p >= 0.355) itemsInCart.add(2); // Basket
    if (p >= 0.400) itemsInCart.add(3); // Smartphone
    if (p >= 0.444) itemsInCart.add(4); // Écouteurs

    // Rebond du chariot lors de l'impact des objets
    double cartBounce = 0.0;
    for (int i = 0; i < 5; i++) {
      final arrivalT = 0.222 + (i * 0.044) + 0.040; // Temps d'impact de chaque objet
      if (p >= arrivalT && p < arrivalT + 0.025) {
        final bp = ((p - arrivalT) / 0.025).clamp(0.0, 1.0);
        cartBounce = math.sin(bp * math.pi) * 3.5;
        break;
      }
    }

    // Dessin des répliques fantômes (motion blur) pendant la course
    if (isRunning && runPhase > 0.05 && dashOpacity > 0.1) {
      _drawGhostReplicas(canvas, charX, groundY, runPhase, itemsInCart);
      _drawSpeedLinesAndDust(canvas, size, charX, groundY, runPhase);
    }

    // Dessin du personnage et du chariot
    _drawCharacterAndCart(
      canvas: canvas,
      x: charX,
      groundY: groundY,
      walkProgress: isRunning ? (runPhase * 3.0) : enterP,
      isRunning: isRunning,
      itemsInCart: itemsInCart,
      cartBounce: cartBounce,
      opacity: dashOpacity,
    );

    // Dessin des 5 objets volants en trajectoire parabolique (1.0s à 2.0s => 0.222 à 0.444)
    if (p >= 0.220 && p < 0.450) {
      _drawFlyingProducts(canvas, size, groundY, stopX, p);
    }
  }

  /// Dessine le personnage original Dokan poussant le chariot
  void _drawCharacterAndCart({
    required Canvas canvas,
    required double x,
    required double groundY,
    required double walkProgress,
    required bool isRunning,
    required List<int> itemsInCart,
    required double cartBounce,
    required double opacity,
  }) {
    canvas.save();
    canvas.translate(x, groundY);

    final characterTilt = isRunning ? 0.35 : 0.0; // Penché en avant en course
    final walkCycle = walkProgress * math.pi * 6.0;

    // --- A. LE PERSONNAGE DOKAN (Derrière le chariot) ---
    canvas.save();
    canvas.translate(-42, 0); // En retrait par rapport au chariot
    canvas.rotate(characterTilt);

    // 1. Jambes & foulée
    final legSwing = isRunning
        ? math.sin(walkCycle * 1.5) * 0.65
        : math.sin(walkCycle) * 0.42;

    final pantsPaint = Paint()
      ..color = kPantsDark.withValues(alpha: opacity)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final shoePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity);

    // Jambe arrière
    canvas.save();
    canvas.translate(0, -32);
    canvas.rotate(-legSwing);
    canvas.drawLine(Offset.zero, const Offset(0, 30), pantsPaint);
    // Chaussure blanche arrière avec semelle turquoise
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-3, 27, 14, 6), const Radius.circular(2)),
      shoePaint,
    );
    canvas.restore();

    // Jambe avant
    canvas.save();
    canvas.translate(0, -32);
    canvas.rotate(legSwing);
    canvas.drawLine(Offset.zero, const Offset(0, 30), pantsPaint);
    // Chaussure blanche avant
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-3, 27, 14, 6), const Radius.circular(2)),
      shoePaint,
    );
    canvas.restore();

    // 2. Torse / Veste blanche avec bande turquoise Dokan
    final torsoPath = Path()
      ..moveTo(-8, -62)
      ..lineTo(9, -62)
      ..lineTo(7, -32)
      ..lineTo(-7, -32)
      ..close();
    canvas.drawPath(
      torsoPath,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );

    // Bande diagonale turquoise sur la veste
    final stripePath = Path()
      ..moveTo(-8, -48)
      ..lineTo(9, -42)
      ..lineTo(8, -36)
      ..lineTo(-7, -42)
      ..close();
    canvas.drawPath(
      stripePath,
      Paint()..color = kTurquoisePrimary.withValues(alpha: opacity),
    );

    // Fine bande orange d'accent
    final orangeStripe = Path()
      ..moveTo(-7, -42)
      ..lineTo(8, -36)
      ..lineTo(8, -33)
      ..lineTo(-7, -39)
      ..close();
    canvas.drawPath(
      orangeStripe,
      Paint()..color = kOrangeAccent.withValues(alpha: opacity),
    );

    // 3. Tête & Visage minimaliste
    const headCenter = Offset(0, -72);
    canvas.drawCircle(
      headCenter,
      9.0,
      Paint()..color = const Color(0xFFF7D5B6).withValues(alpha: opacity), // Teint chair chaleureux
    );

    // 4. Casquette Dokan (Dôme turquoise + visière orange vers l'avant)
    final capPath = Path()
      ..addArc(
        Rect.fromCircle(center: const Offset(0, -73), radius: 9.8),
        math.pi,
        math.pi,
      );
    canvas.drawPath(
      capPath,
      Paint()..color = kTurquoisePrimary.withValues(alpha: opacity),
    );

    // Visière orange tournée vers la droite (direction de la marche)
    final visorPath = Path()
      ..moveTo(5, -73)
      ..lineTo(16, -72)
      ..lineTo(6, -69)
      ..close();
    canvas.drawPath(
      visorPath,
      Paint()..color = kOrangeAccent.withValues(alpha: opacity),
    );

    // 5. Bras tenant la poignée du chariot
    final armPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    // Bras tendu vers la poignée
    canvas.drawLine(const Offset(2, -56), const Offset(26, -46), armPaint);

    canvas.restore(); // Fin character

    // --- B. LE CHARIOT DE COURSES BLANC ÉPURÉ (Avec rebond cartBounce) ---
    canvas.save();
    canvas.translate(0, -cartBounce);

    final cartLine = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Panier en fil de fer
    final basketPath = Path()
      ..moveTo(-18, -48) // Poignée
      ..lineTo(-6, -44)
      ..lineTo(36, -44) // Bord supérieur
      ..lineTo(28, -16) // Avant incliné
      ..lineTo(-4, -16) // Fond
      ..close();
    canvas.drawPath(basketPath, cartLine);

    // Grillage fin du panier
    final gridLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.55 * opacity)
      ..strokeWidth = 1.4;
    canvas.drawLine(const Offset(6, -44), const Offset(4, -16), gridLine);
    canvas.drawLine(const Offset(18, -44), const Offset(14, -16), gridLine);
    canvas.drawLine(const Offset(-5, -30), const Offset(32, -30), gridLine);

    // Châssis reliant les roues
    canvas.drawLine(const Offset(-4, -16), const Offset(-4, -8), cartLine);
    canvas.drawLine(const Offset(26, -16), const Offset(26, -8), cartLine);
    canvas.drawLine(const Offset(-6, -8), const Offset(28, -8), cartLine);

    // Roues avec rotation des rayons
    final wheelRotation = walkProgress * math.pi * 8.0;
    _drawCartWheel(canvas, const Offset(-4, -6), 6.5, wheelRotation, opacity);
    _drawCartWheel(canvas, const Offset(26, -6), 6.5, wheelRotation, opacity);

    // --- C. CONTENU DU CHARIOT (Articles atterris) ---
    for (final itemIdx in itemsInCart) {
      _drawItemInsideCart(canvas, itemIdx, opacity);
    }

    canvas.restore(); // Fin cart
    canvas.restore(); // Fin overall sequence
  }

  void _drawCartWheel(Canvas canvas, Offset center, double radius, double angle, double opacity) {
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(center, 2.0, Paint()..color = Colors.white.withValues(alpha: opacity));

    // 4 Rayons
    for (int i = 0; i < 4; i++) {
      final a = angle + (i * math.pi / 2);
      canvas.drawLine(
        center,
        Offset(center.dx + math.cos(a) * (radius - 1), center.dy + math.sin(a) * (radius - 1)),
        Paint()..color = Colors.white.withValues(alpha: 0.8 * opacity)..strokeWidth = 1.0,
      );
    }
  }

  /// Dessine un produit rangé dans le panier du chariot
  void _drawItemInsideCart(Canvas canvas, int itemIdx, double opacity) {
    switch (itemIdx) {
      case 0: // Boîte cadeau au fond
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(0, -28, 12, 11), const Radius.circular(2)),
          Paint()..color = kOrangeAccent.withValues(alpha: opacity),
        );
        // Ruban turquoise
        canvas.drawLine(
          const Offset(6, -28),
          const Offset(6, -17),
          Paint()..color = kTurquoisePrimary.withValues(alpha: opacity)..strokeWidth = 2.0,
        );
        break;
      case 1: // T-shirt plié
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(11, -26, 12, 9), const Radius.circular(2)),
          Paint()..color = Colors.white.withValues(alpha: 0.9 * opacity),
        );
        break;
      case 2: // Basket sportive
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(3, -36, 13, 8), const Radius.circular(3)),
          Paint()..color = kTurquoisePrimary.withValues(alpha: opacity),
        );
        break;
      case 3: // Smartphone
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(15, -37, 8, 13), const Radius.circular(2)),
          Paint()..color = const Color(0xFF1E293B).withValues(alpha: opacity),
        );
        canvas.drawCircle(
          const Offset(19, -31),
          2.0,
          Paint()..color = kTurquoiseLight.withValues(alpha: opacity),
        );
        break;
      case 4: // Écouteurs
        canvas.drawCircle(
          const Offset(10, -42),
          4.0,
          Paint()..color = Colors.white.withValues(alpha: opacity),
        );
        break;
    }
  }

  /// Répliques fantômes semi-transparentes pour illustrer la vitesse
  void _drawGhostReplicas(
    Canvas canvas,
    double charX,
    double groundY,
    double runPhase,
    List<int> itemsInCart,
  ) {
    const offsets = [-32.0, -64.0];
    final alphas = [0.28, 0.12];

    for (int i = 0; i < offsets.length; i++) {
      final ghostX = charX + offsets[i];
      _drawCharacterAndCart(
        canvas: canvas,
        x: ghostX,
        groundY: groundY,
        walkProgress: runPhase * 3.0,
        isRunning: true,
        itemsInCart: itemsInCart,
        cartBounce: 0.0,
        opacity: alphas[i],
      );
    }
  }

  /// Traits horizontaux de vitesse et nuage de poussière sous les pieds
  void _drawSpeedLinesAndDust(
    Canvas canvas,
    Size size,
    double charX,
    double groundY,
    double runPhase,
  ) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Traits de vitesse horizontaux derrière le personnage
    final yOffsets = [-50.0, -38.0, -25.0, -12.0];
    final lengths = [45.0, 70.0, 55.0, 35.0];

    for (int i = 0; i < yOffsets.length; i++) {
      final lx = charX - 55 - (i * 12);
      final ly = groundY + yOffsets[i];
      canvas.drawLine(
        Offset(lx, ly),
        Offset(lx - lengths[i], ly),
        linePaint..strokeWidth = (i % 2 == 0 ? 2.2 : 1.4),
      );
    }

    // Petit nuage de poussière stylisé sous les pieds à l'accélération
    if (runPhase < 0.6) {
      final dustOpacity = (1.0 - (runPhase / 0.6)).clamp(0.0, 1.0);
      final dustPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.45 * dustOpacity)
        ..style = PaintingStyle.fill;

      final dustOrigin = Offset(charX - 45, groundY - 4);
      canvas.drawCircle(dustOrigin, 6.0 * (1.0 + runPhase), dustPaint);
      canvas.drawCircle(Offset(dustOrigin.dx - 10, dustOrigin.dy + 2), 4.5 * (1.0 + runPhase), dustPaint);
      canvas.drawCircle(Offset(dustOrigin.dx - 18, dustOrigin.dy), 3.0, dustPaint);
    }
  }

  // ==========================================================================
  // 4. LES 5 OBJETS VOLANTS EN ARC PARABOLIQUE + ÉTINCELLES D'IMPACT
  // ==========================================================================
  void _drawFlyingProducts(
    Canvas canvas,
    Size size,
    double groundY,
    double stopX,
    double p,
  ) {
    // 5 objets :
    // 0 : Boîte cadeau (0.222 -> 0.266)
    // 1 : T-shirt plié (0.266 -> 0.311)
    // 2 : Basket sportive (0.311 -> 0.355)
    // 3 : Smartphone (0.355 -> 0.400)
    // 4 : Écouteurs (0.400 -> 0.444)
    final standShelf = Offset(size.width * 0.74 - 15, groundY - 75);
    final cartTarget = Offset(stopX + 15, groundY - 32);

    for (int i = 0; i < 5; i++) {
      final startT = 0.222 + (i * 0.044);
      final endT = startT + 0.044;

      if (p >= startT && p <= endT + 0.035) {
        final itemP = ((p - startT) / 0.044).clamp(0.0, 1.0);
        final curvedP = Curves.easeInOutQuad.transform(itemP);

        // Trajectoire en cloche parabolique
        final x = standShelf.dx + (cartTarget.dx - standShelf.dx) * curvedP;
        final arcApex = -90.0;
        final y = standShelf.dy + (cartTarget.dy - standShelf.dy) * curvedP +
            (4.0 * arcApex * curvedP * (1.0 - curvedP));

        // Dessin du produit en vol
        if (itemP < 1.0) {
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(curvedP * math.pi * 2.5); // Rotation aérienne fluide
          _drawIndividualProduct(canvas, i, 1.0);
          canvas.restore();
        }

        // Éclat d'étincelles blanches en rayons à l'impact (p > endT - 0.008)
        if (itemP >= 0.85) {
          final sparkP = ((p - (endT - 0.008)) / 0.030).clamp(0.0, 1.0);
          _drawImpactSparks(canvas, cartTarget, sparkP);
        }
      }
    }
  }

  /// Dessine un produit individuel stylisé
  void _drawIndividualProduct(Canvas canvas, int index, double scale) {
    canvas.scale(scale);

    switch (index) {
      case 0: // 1. Boîte cadeau orange avec ruban turquoise
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-9, -9, 18, 18), const Radius.circular(3)),
          Paint()..color = kOrangeAccent,
        );
        // Ruban turquoise
        final ribbonPaint = Paint()..color = kTurquoisePrimary..strokeWidth = 3.2;
        canvas.drawLine(const Offset(0, -9), const Offset(0, 9), ribbonPaint);
        canvas.drawLine(const Offset(-9, 0), const Offset(9, 0), ribbonPaint);
        // Petit nœud papillon
        canvas.drawCircle(const Offset(-2, -10), 2.5, ribbonPaint);
        canvas.drawCircle(const Offset(2, -10), 2.5, ribbonPaint);
        break;

      case 1: // 2. T-shirt plié blanc & turquoise
        final shirtPath = Path()
          ..moveTo(-10, -7)
          ..lineTo(10, -7)
          ..lineTo(8, 7)
          ..lineTo(-8, 7)
          ..close();
        canvas.drawPath(shirtPath, Paint()..color = Colors.white);
        // Col et ligne turquoise
        canvas.drawCircle(const Offset(0, -7), 3.0, Paint()..color = kTurquoisePrimary);
        canvas.drawLine(
          const Offset(-7, 0),
          const Offset(7, 0),
          Paint()..color = kTurquoiseLight..strokeWidth = 2.0,
        );
        break;

      case 2: // 3. Basket de sport dynamique
        final shoePath = Path()
          ..moveTo(-11, 2)
          ..lineTo(12, 2) // Semelle
          ..lineTo(11, -3)
          ..lineTo(3, -5)
          ..lineTo(-4, -9) // Cheville
          ..lineTo(-10, -6)
          ..close();
        canvas.drawPath(shoePath, Paint()..color = kTurquoisePrimary);
        // Semelle blanche
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-12, 2, 25, 4), const Radius.circular(2)),
          Paint()..color = Colors.white,
        );
        // Virgule / accent orange
        canvas.drawLine(
          const Offset(-3, -2),
          const Offset(5, -4),
          Paint()..color = kOrangeAccent..strokeWidth = 2.0,
        );
        break;

      case 3: // 4. Smartphone avec écran illuminé
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -13, 16, 26), const Radius.circular(3.5)),
          Paint()..color = const Color(0xFF1E293B),
        );
        // Écran turquoise
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-6.5, -11, 13, 20), const Radius.circular(2)),
          Paint()..color = kTurquoiseLight,
        );
        // Petit icône shopping sur l'écran
        canvas.drawCircle(const Offset(0, -1), 3.0, Paint()..color = Colors.white);
        break;

      case 4: // 5. Boîtier écouteurs sans fil blanc
        canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-9, -7, 18, 14), const Radius.circular(5)),
          Paint()..color = Colors.white,
        );
        // Rainure centrale et LED
        canvas.drawLine(
          const Offset(-9, -1),
          const Offset(9, -1),
          Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 1.0,
        );
        canvas.drawCircle(
          const Offset(0, 2),
          1.5,
          Paint()..color = kTurquoisePrimary,
        );
        break;
    }
  }

  /// Explosion de 6 à 8 rayons blancs lors de l'impact dans le chariot
  void _drawImpactSparks(Canvas canvas, Offset center, double sparkP) {
    if (sparkP <= 0.0 || sparkP >= 1.0) return;

    final alpha = (1.0 - sparkP).clamp(0.0, 1.0);
    final sparkPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const count = 7;
    final rMin = 4.0 + (sparkP * 12.0);
    final rMax = 8.0 + (sparkP * 24.0);

    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi / count) - (math.pi / 2);
      final p1 = Offset(center.dx + math.cos(angle) * rMin, center.dy + math.sin(angle) * rMin);
      final p2 = Offset(center.dx + math.cos(angle) * rMax, center.dy + math.sin(angle) * rMax);
      canvas.drawLine(p1, p2, sparkPaint);
    }
  }

  // ==========================================================================
  // 5. GRAND SAC DOKAN (Tracé contour, squash & stretch, ombre ovale, 3 items)
  // ==========================================================================
  void _drawBagSequence(Canvas canvas, Size size, double groundY, double p) {
    // Timing :
    // 0.578 à 0.650 : Dessin du contour au trait (extractPath)
    // 0.620 à 0.720 : Remplissage couleur & rebond squash & stretch élastique
    // 0.711 à 0.867 : 3 produits phares jaillissent du sac avec étincelles
    // 0.844 à 1.000 : Le sac remonte de bagRiseY pour libérer l'espace texte
    final bagCenter = Offset(size.width / 2, size.height * 0.42 + bagRiseY);

    // Progression du tracé du contour
    final strokeP = ((p - 0.578) / 0.08).clamp(0.0, 1.0);
    // Progression du remplissage de fond
    final fillP = ((p - 0.630) / 0.09).clamp(0.0, 1.0);

    // Rebond élastique squash & stretch
    double scaleX = 1.0;
    double scaleY = 1.0;
    double dropOffsetY = 0.0;
    double shadowScale = 1.0;

    if (p >= 0.620 && p < 0.800) {
      final bounceP = ((p - 0.620) / 0.16).clamp(0.0, 1.0);
      final elasticVal = Curves.elasticOut.transform(bounceP);
      // Rebond doux
      scaleX = 0.85 + (0.15 * elasticVal);
      scaleY = 1.15 - (0.15 * elasticVal);
      dropOffsetY = (1.0 - elasticVal) * -35.0;
      shadowScale = 0.6 + (0.4 * elasticVal);
    }

    final animatedCenter = Offset(bagCenter.dx, bagCenter.dy + dropOffsetY);

    // 1. Ombre ovale au sol
    if (strokeP > 0.3) {
      final shadowOpacity = (strokeP * 0.35 * (1.0 - (dropOffsetY.abs() / 70.0))).clamp(0.0, 0.35);
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: shadowOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(animatedCenter.dx, groundY - 6),
          width: 105.0 * shadowScale,
          height: 18.0 * shadowScale,
        ),
        shadowPaint,
      );
    }

    // 2. Le Sac en papier Dokan
    canvas.save();
    canvas.translate(animatedCenter.dx, animatedCenter.dy);
    canvas.scale(scaleX, scaleY);

    _drawPaperBag(canvas, strokeP, fillP);

    // 3. Les 3 produits jaillissant du sac (0.711 à 0.867)
    if (p >= 0.710 && p < 0.960) {
      _drawPoppingProducts(canvas, p);
      _drawTwinklingStars(canvas, p);
    }

    canvas.restore();
  }

  /// Dessine le sac de courses en papier avec son contour au trait et son remplissage
  void _drawPaperBag(Canvas canvas, double strokeP, double fillP) {
    const bagW = 92.0;
    const bagH = 100.0;
    const halfW = bagW / 2;
    const halfH = bagH / 2;

    // Chemin du corps du sac avec léger trapèze évasé vers le haut
    final bagBodyPath = Path()
      ..moveTo(-halfW + 6, halfH) // Bas gauche
      ..lineTo(halfW - 6, halfH) // Bas droite
      ..lineTo(halfW, -halfH + 12) // Haut droite
      ..lineTo(-halfW, -halfH + 12) // Haut gauche
      ..close();

    // A. Remplissage de couleur (si fillP > 0)
    if (fillP > 0.0) {
      final fillOpacity = fillP.clamp(0.0, 1.0);

      // Fond principal papier crème doux
      canvas.drawPath(
        bagBodyPath,
        Paint()..color = kWarmPaper.withValues(alpha: fillOpacity),
      );

      // Pli latéral d'ombrage du sac (style papier kraft / sac boutique)
      final sideFoldPath = Path()
        ..moveTo(-halfW, -halfH + 12)
        ..lineTo(-halfW + 18, -halfH + 14)
        ..lineTo(-halfW + 14, halfH)
        ..lineTo(-halfW + 6, halfH)
        ..close();
      canvas.drawPath(
        sideFoldPath,
        Paint()..color = kWarmPaperSide.withValues(alpha: fillOpacity),
      );

      // Bande signature turquoise Dokan au centre
      final stripeRect = Rect.fromLTWH(-halfW + 2, -10, bagW - 4, 24);
      canvas.drawRect(
        stripeRect,
        Paint()..color = kTurquoisePrimary.withValues(alpha: fillOpacity),
      );

      // Logo Dokan / Lettre « D » stylisée blanche sur la bande
      _drawBrandMarkOnBag(canvas, const Offset(0, 2), fillOpacity);

      // Anses souples en cordelette (au-dessus du sac)
      final cordPaint = Paint()
        ..color = kCordColor.withValues(alpha: fillOpacity)
        ..strokeWidth = 3.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final handlePath = Path()
        ..moveTo(-22, -halfH + 12)
        ..cubicTo(-22, -halfH - 26, 22, -halfH - 26, 22, -halfH + 12);
      canvas.drawPath(handlePath, cordPaint);

      // Petits nœuds ou attaches de cordelette
      final knotPaint = Paint()..color = kCordColor.withValues(alpha: fillOpacity);
      canvas.drawCircle(const Offset(-22, -halfH + 14), 3.0, knotPaint);
      canvas.drawCircle(const Offset(22, -halfH + 14), 3.0, knotPaint);
    }

    // B. Contour blanc au trait (dessiné via PathMetric entre 0 et strokeP)
    if (strokeP > 0.0) {
      final strokePaint = Paint()
        ..color = Colors.white.withValues(alpha: strokeP.clamp(0.0, 1.0))
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (strokeP >= 0.999) {
        canvas.drawPath(bagBodyPath, strokePaint);
      } else {
        // Tracé progressif au trait
        for (final metric in bagBodyPath.computeMetrics()) {
          final extract = metric.extractPath(0.0, metric.length * strokeP);
          canvas.drawPath(extract, strokePaint);
        }
      }
    }
  }

  /// Symbole Dokan élégant sur la bande turquoise du sac
  void _drawBrandMarkOnBag(Canvas canvas, Offset center, double opacity) {
    final whitePaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Lettre « D » arrondie épurée
    final dPath = Path()
      ..moveTo(center.dx - 8, center.dy - 7)
      ..lineTo(center.dx - 1, center.dy - 7)
      ..arcToPoint(
        Offset(center.dx - 1, center.dy + 7),
        radius: const Radius.circular(7),
        clockwise: true,
      )
      ..lineTo(center.dx - 8, center.dy + 7)
      ..close();

    // Creux intérieur du D
    final innerD = Path()
      ..moveTo(center.dx - 4, center.dy - 4)
      ..lineTo(center.dx - 1, center.dy - 4)
      ..arcToPoint(
        Offset(center.dx - 1, center.dy + 4),
        radius: const Radius.circular(4),
        clockwise: true,
      )
      ..lineTo(center.dx - 4, center.dy + 4)
      ..close();

    final combined = Path.combine(PathOperation.difference, dPath, innerD);
    canvas.drawPath(combined, whitePaint);

    // Petit point étincelle orange au-dessus du D
    canvas.drawCircle(
      Offset(center.dx + 8, center.dy - 4),
      2.0,
      Paint()..color = kOrangeAccent.withValues(alpha: opacity),
    );
  }

  /// 3 Produits phares jaillissant du sac puis flottant au sommet
  void _drawPoppingProducts(Canvas canvas, double p) {
    // 0.711 à 0.867 : Montée élastique puis léger flottement
    final popP = ((p - 0.710) / 0.14).clamp(0.0, 1.0);
    final popCurve = Curves.elasticOut.transform(popP);

    // Position d'élévation
    final elevate = popCurve;

    // Produit 1 : Boîte cadeau (à gauche)
    canvas.save();
    canvas.translate(-38.0 * elevate, -50 - (42.0 * elevate));
    canvas.rotate(-0.25 * (1.0 - popP));
    _drawIndividualProduct(canvas, 0, 0.95 * elevate);
    canvas.restore();

    // Produit 2 : Basket sportive (au centre plus haut)
    canvas.save();
    canvas.translate(0.0, -50 - (62.0 * elevate));
    canvas.rotate(0.12 * math.sin(p * 20));
    _drawIndividualProduct(canvas, 2, 1.05 * elevate);
    canvas.restore();

    // Produit 3 : Smartphone (à droite)
    canvas.save();
    canvas.translate(38.0 * elevate, -50 - (44.0 * elevate));
    canvas.rotate(0.25 * (1.0 - popP));
    _drawIndividualProduct(canvas, 3, 0.95 * elevate);
    canvas.restore();
  }

  /// Étoiles scintillantes à 4 branches autour du sac Dokan
  void _drawTwinklingStars(Canvas canvas, double p) {
    final starPhase = ((p - 0.710) / 0.22).clamp(0.0, 1.0);
    final starOpacity = math.sin(starPhase * math.pi).clamp(0.0, 1.0);

    final starPositions = [
      const Offset(-52, -100),
      const Offset(48, -108),
      const Offset(62, -45),
      const Offset(-58, -35),
      const Offset(0, -125),
    ];

    for (int i = 0; i < starPositions.length; i++) {
      final pos = starPositions[i];
      final twinkle = math.sin((p * 25) + (i * 1.5)).abs();
      final starSize = 5.0 + (twinkle * 4.0);

      _draw4PointStar(
        canvas,
        pos,
        starSize,
        (i % 2 == 0 ? Colors.white : kOrangeAccent).withValues(alpha: starOpacity * 0.9),
      );
    }
  }

  void _draw4PointStar(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SplashCinematicPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.bagRiseY != bagRiseY;
}
