/// ============================================================================
/// RÔLE DU FICHIER :
/// Écran de démarrage animé (Splash Screen) officiel Dokan.
///
/// SÉQUENCE CINÉMATIQUE (4500 ms) :
/// 1) 0.0 à 0.3 s : Fond turquoise Dokan seul, transition douce.
/// 2) 0.3 à 1.0 s : Entrée en scène : ligne blanche au sol, stand boutique Dokan
///                  (auvent rayé blanc & orange, étagère), personnage original
///                  (casquette turquoise/orange, veste blanche à bande, pantalon
///                  foncé) arrivant en poussant un chariot blanc épuré.
/// 3) 1.0 à 2.0 s : 5 produits sortent du stand en arc parabolique (boîte cadeau,
///                  t-shirt, basket, smartphone, écouteurs) avec étincelles en
///                  rayons à chaque impact dans le chariot.
/// 4) 2.0 à 2.6 s : Posture de course, accélération vive vers la droite avec
///                  traits de vitesse, nuage de poussière et répliques fantômes.
/// 5) 2.6 à 3.4 s : Grand sac de courses en papier Dokan au centre (tracé du
///                  contour, remplissage, squash & stretch élastique et ombre ovale).
/// 6) 3.2 à 3.9 s : 3 produits phares jaillissent du sac avec étoiles scintillantes.
/// 7) 3.8 à 4.5 s : Le sac remonte légèrement, texte « Dokan » en lettres arrondies
///                  staggered, puis slogan « Vos achats, livrés chez vous ».
/// 8) Fin & Sortie : Maintien ~0.6s (ou respiration si Firebase charge), puis voile
///                  blanc courbé montant révélant l'accueil.
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
import 'widgets/splash_cinematic_painter.dart';

// --- Constantes configurables ---
const String kSplashTagline = 'Vos achats, livrés chez vous';
const int kSplashDurationMs = 4500;
const int kHoldDurationMs = 600;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  /// Contrôleur cinématique principal (4500 ms)
  late final AnimationController _ctrl;

  /// Contrôleur de respiration subtile si le chargement dépasse 4.5s
  late final AnimationController _breathingCtrl;

  /// Contrôleur du voile blanc de sortie vers l'accueil
  late final AnimationController _exitVeilCtrl;

  bool _sessionReady = false;
  bool _minDurationPassed = false;
  bool _navigated = false;
  bool _holdTimerFired = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // 1. Contrôleur principal
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kSplashDurationMs),
    );

    // 2. Contrôleur de respiration (1.0 -> 1.03)
    _breathingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // 3. Contrôleur du voile de sortie (350 ms)
    _exitVeilCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Démarrage de la cinématique
    _ctrl.forward().then((_) {
      if (mounted) {
        // Fin de l'animation de 4500 ms : maintien de ~0.6s
        Future.delayed(const Duration(milliseconds: kHoldDurationMs), () {
          if (mounted) {
            _holdTimerFired = true;
            _minDurationPassed = true;
            if (_sessionReady) {
              _triggerExitAndNavigate();
            } else {
              // Si Firebase n'a pas encore terminé, activer la respiration subtile
              _breathingCtrl.repeat(reverse: true);
            }
          }
        });
      }
    });

    // Vérification de la session Firebase en arrière-plan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
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
        // Si les animations sont réduites ou si la durée minimale est déjà atteinte
        if (MediaQuery.of(context).disableAnimations) {
          _triggerExitAndNavigate(immediate: true);
        } else if (_minDurationPassed && _holdTimerFired) {
          _triggerExitAndNavigate();
        }
      }
    }
  }

  void _triggerExitAndNavigate({bool immediate = false}) {
    if (_navigated || !mounted) return;

    if (immediate) {
      _navigated = true;
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
      context.go(AppRoutes.home);
      return;
    }

    // Arrêter la respiration si elle tournait
    if (_breathingCtrl.isAnimating) {
      _breathingCtrl.stop();
    }

    // Lancer le voile blanc montant puis naviguer
    _exitVeilCtrl.forward().then((_) {
      if (mounted && !_navigated) {
        _navigated = true;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
        context.go(AppRoutes.home);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _breathingCtrl.dispose();
    _exitVeilCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mode "Réduire les animations" (accessibilité)
    if (MediaQuery.of(context).disableAnimations) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF288585),
                AppColors.primary,
                Color(0xFF0D2B2F),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, val, child) {
                return Opacity(
                  opacity: val.clamp(0.0, 1.0),
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grand sac Dokan statique
                  CustomPaint(
                    size: const Size(130, 140),
                    painter: SplashCinematicPainter(
                      progress: 0.70, // État sac formé et stable
                      bagRiseY: 0.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Dokan',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    kSplashTagline,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fond dégradé officiel turquoise Dokan
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF288585), // Turquoise lumineux en haut
                  AppColors.primary,  // 0xFF1F7A7A Identité officielle Dokan
                  Color(0xFF0D2B2F), // Vert-canard / bleu pétrole profond
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. Scène vectorielle cinématique animée (CustomPainter)
          AnimatedBuilder(
            animation: Listenable.merge([_ctrl, _breathingCtrl]),
            builder: (context, child) {
              final p = _ctrl.value.clamp(0.0, 1.0);

              // Bag rise lors de l'apparition de la typographie (0.844 à 0.940)
              final riseP = ((p - 0.844) / 0.096).clamp(0.0, 1.0);
              final bagRiseY = -28.0 * Curves.easeInOutCubic.transform(riseP);

              // Facteur de respiration si en attente post-animation (1.0 -> 1.03)
              final breathingScale = 1.0 + (_breathingCtrl.value * 0.03);

              return Transform.scale(
                scale: breathingScale,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: SplashCinematicPainter(
                    progress: p,
                    bagRiseY: bagRiseY,
                  ),
                ),
              );
            },
          ),

          // 3. Typographie : Nom « Dokan » (staggered) & Slogan « Vos achats, livrés chez vous »
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final p = _ctrl.value.clamp(0.0, 1.0);
              if (p < 0.840) return const SizedBox.shrink();

              final size = MediaQuery.of(context).size;
              final textTop = (size.height * 0.42) + 76.0;

              return Positioned(
                left: 0,
                right: 0,
                top: textTop,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A. Nom « Dokan » lettre par lettre
                    _buildStaggeredDokanTitle(p),

                    const SizedBox(height: 10),

                    // B. Slogan Dokan en fondu doux
                    _buildFadeTagline(p),
                  ],
                ),
              );
            },
          ),

          // 4. Voile blanc montant à bord courbé révélant l'accueil
          AnimatedBuilder(
            animation: _exitVeilCtrl,
            builder: (context, child) {
              if (_exitVeilCtrl.value <= 0.001) return const SizedBox.shrink();
              return ClipPath(
                clipper: _CurvedRisingClipper(_exitVeilCtrl.value),
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

  /// Lettres « D », « o », « k », « a », « n » apparaissant avec décalage fluide
  Widget _buildStaggeredDokanTitle(double p) {
    const letters = ['D', 'o', 'k', 'a', 'n'];
    const startP = 0.844;
    const letterStagger = 0.016; // ~70ms par lettre

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(letters.length, (index) {
        final letterStart = startP + (index * letterStagger);
        final lp = ((p - letterStart) / 0.040).clamp(0.0, 1.0);
        final curvedLp = Curves.easeOutBack.transform(lp);
        final slideY = (1.0 - curvedLp) * 20.0;

        return Transform.translate(
          offset: Offset(0, slideY),
          child: Opacity(
            opacity: lp.clamp(0.0, 1.0),
            child: Text(
              letters[index],
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Slogan officiel Dokan avec montée douce et fondu
  Widget _buildFadeTagline(double p) {
    final tp = ((p - 0.890) / 0.080).clamp(0.0, 1.0);
    final curvedTp = Curves.easeOut.transform(tp);
    final slideY = (1.0 - curvedTp) * 10.0;

    return Transform.translate(
      offset: Offset(0, slideY),
      child: Opacity(
        opacity: tp.clamp(0.0, 1.0),
        child: const Text(
          kSplashTagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
            letterSpacing: 0.3,
          ),
        ),
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
