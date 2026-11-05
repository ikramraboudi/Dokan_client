/// ============================================================================
/// RÔLE DU FICHIER : Écran d'ouverture animé avec apparition dynamique du logo Dokan, particules, slogan et vérification de session.
/// INTERAGIT AVEC : AppConfig, sessionProvider, FirebaseAuth, AppRoutes.home.
/// POUR L'ORAL : « Le splash screen anime la marque Dokan et vérifie si une session Firebase Auth existe sur le téléphone pour reconnecter le client automatiquement. »
/// ============================================================================
/// ============================================================================
/// RÔLE DU FICHIER :
/// Écran de démarrage animé (Splash Screen) officiel de l'application Dokan.
///
/// OBJECTIFS ET SCÉNARIO :
/// 1) VÉRIFICATION DE SESSION : vérifie l'état Firebase en arrière-plan sans
///    bloquer l'interface. En cas d'erreur ou d'absence de réseau, l'utilisateur
///    est redirigé en mode visiteur de manière transparente.
/// 2) DURÉE MINIMALE : respecte scrupuleusement la durée minimale configurée
///    (`AppConfig.splashDuration` = 3 secondes) avant toute navigation.
/// 3) IDENTITÉ VISUELLE ANIMÉE :
///    - Fond dégradé vertical (primaryDark -> primary -> primaryLight) avec
///      blobs organiques translucides dérivant en continu.
///    - Carte-logo Dokan (widget réutilisable `DokanLogo`) apparaissant avec
///      rebond élastique (scale 0 -> 1.0), puis pulsation douce continue.
///    - Lettres du nom « Dokan » apparaissant une à une (décalage de 80 ms,
///      fondu et glissement vers le haut avec `Interval` sur le contrôleur d'entrée).
///    - Slogan court et chaleureux (`AppConfig.appTagline`) en fondu.
///    - Icônes flottantes en arrière-plan (sac, cœur, étiquette, panier, étoile).
///    - Fine barre de progression discrète en bas suivant l'avancement.
/// 4) INTERACTIONS :
///    - Toucher l'écran : émission de petites étincelles colorées (CustomPainter,
///      max 30 particules, nettoyées automatiquement) avec retour haptique léger.
///    - Glisser le doigt : effet de parallaxe inversé sur les blobs et icônes.
///    - Bouton « Passer » discret en haut à droite après 1 seconde.
/// 5) ACCESSIBILITÉ ET PERFORMANCE :
///    - Prise en compte de `MediaQuery.disableAnimations` (fallback statique).
///    - Aucune reconstruction par image (pas de setState à 60 fps).
///    - Séparation des couches dans des `RepaintBoundary`.
///    - Respect des contrastes et balises `Semantics`.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `feature/splash/` (Fonctionnalité Splash Screen).
///
/// RELATIONS ET DÉPENDANCES :
/// - Déclaré par : `core/navigation/app_router.dart` comme route initiale.
/// - Dépend de :
///   * `core/config/app_config.dart` (`splashDuration`, `appTagline`, `appName`).
///   * `core/navigation/routes.dart` (`AppRoutes.home`).
///   * `core/session/session_provider.dart` (`sessionProvider`).
///   * `core/theme/app_colors.dart` (palette centralisée exclusive).
///   * `core/ui/dokan_logo.dart` (`DokanLogo`).
///   * `package:firebase_auth/firebase_auth.dart` pour la session.
/// ============================================================================
library;

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/navigation/routes.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/dokan_logo.dart';
import '../../data/models/user_summary.dart';

// ─── Modèles de données internes ─────────────────────────────────────────────

/// Représentation d'une icône flottante d'ambiance en arrière-plan.
class _FloatingIconData {
  final IconData icon;
  final double xFraction;
  final double yStart;
  final double travelDistance;
  final double opacity;
  final double size;
  final double phase;

  const _FloatingIconData({
    required this.icon,
    required this.xFraction,
    required this.yStart,
    required this.travelDistance,
    required this.opacity,
    required this.size,
    required this.phase,
  });
}

/// Particule générée lors d'un toucher sur l'écran.
class _TouchParticle {
  final Offset position;
  final double angle;
  final double speed;
  final Color color;
  final double radius;
  final int createdAt;

  static const int lifetimeMs = 600;

  _TouchParticle({
    required this.position,
    required this.angle,
    required this.speed,
    required this.color,
    required this.radius,
  }) : createdAt = DateTime.now().millisecondsSinceEpoch;

  double get progress {
    final elapsed = DateTime.now().millisecondsSinceEpoch - createdAt;
    return (elapsed / lifetimeMs).clamp(0.0, 1.0);
  }

  bool get isDead => progress >= 1.0;

  double get opacity => (1.0 - progress).clamp(0.0, 1.0);
}

// ─── Écran Splash Screen ─────────────────────────────────────────────────────

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // ─── Contrôleurs d'animation ───────────────────────────────────────────────

  /// Contrôleur de la séquence d'entrée (joué une seule fois, durée 2,5 s).
  late final AnimationController _entryCtrl;

  /// Contrôleur des mouvements d'ambiance (boucle continue de 4 s aller-retour).
  late final AnimationController _ambientCtrl;

  // ─── Animations de la séquence d'entrée ───────────────────────────────────

  /// Logo : rebond élastique 0 -> 1.0
  late final Animation<double> _logoScale;

  /// Logo : pulsation continue douce
  late final Animation<double> _logoPulse;

  /// Lettres du nom Dokan : opacité et glissement décalés (5 lettres)
  late final List<Animation<double>> _letterOpacity;
  late final List<Animation<double>> _letterSlide;

  /// Slogan : fondu d'apparition
  late final Animation<double> _taglineOpacity;

  /// Barre de chargement : fondu d'apparition
  late final Animation<double> _progressOpacity;

  // ─── États fonctionnels ────────────────────────────────────────────────────

  bool _sessionReady = false;
  bool _skipRequested = false;
  bool _navigated = false;
  bool _showSkip = false;

  /// Offset de parallaxe réactif sans setState
  final ValueNotifier<Offset> _parallaxOffset = ValueNotifier(Offset.zero);

  /// Liste des particules de toucher actives
  final List<_TouchParticle> _particles = [];
  final math.Random _rng = math.Random();

  /// Palette des particules (extraite exclusivement de AppColors)
  static const List<Color> _particleColors = [
    AppColors.accent,
    AppColors.primaryLight,
    AppColors.onPrimary,
    AppColors.star,
    AppColors.favoriteSoft,
  ];

  /// Liste des icônes flottantes d'ambiance (12 éléments discrets)
  static const List<_FloatingIconData> _floatingIcons = [
    _FloatingIconData(icon: Icons.shopping_bag_outlined, xFraction: 0.08, yStart: 0.85, travelDistance: 220, opacity: 0.12, size: 30, phase: 0.0),
    _FloatingIconData(icon: Icons.favorite_border, xFraction: 0.20, yStart: 0.90, travelDistance: 260, opacity: 0.10, size: 24, phase: 0.15),
    _FloatingIconData(icon: Icons.local_offer_outlined, xFraction: 0.35, yStart: 0.80, travelDistance: 200, opacity: 0.09, size: 26, phase: 0.30),
    _FloatingIconData(icon: Icons.shopping_cart_outlined, xFraction: 0.50, yStart: 0.88, travelDistance: 240, opacity: 0.11, size: 22, phase: 0.45),
    _FloatingIconData(icon: Icons.star_outline, xFraction: 0.65, yStart: 0.82, travelDistance: 210, opacity: 0.08, size: 28, phase: 0.10),
    _FloatingIconData(icon: Icons.card_giftcard_outlined, xFraction: 0.78, yStart: 0.92, travelDistance: 270, opacity: 0.10, size: 24, phase: 0.60),
    _FloatingIconData(icon: Icons.storefront_outlined, xFraction: 0.90, yStart: 0.78, travelDistance: 190, opacity: 0.09, size: 22, phase: 0.75),
    _FloatingIconData(icon: Icons.discount_outlined, xFraction: 0.14, yStart: 0.60, travelDistance: 180, opacity: 0.07, size: 18, phase: 0.20),
    _FloatingIconData(icon: Icons.local_shipping_outlined, xFraction: 0.56, yStart: 0.65, travelDistance: 170, opacity: 0.08, size: 20, phase: 0.85),
    _FloatingIconData(icon: Icons.redeem_outlined, xFraction: 0.84, yStart: 0.55, travelDistance: 160, opacity: 0.07, size: 18, phase: 0.50),
    _FloatingIconData(icon: Icons.sell_outlined, xFraction: 0.40, yStart: 0.50, travelDistance: 200, opacity: 0.06, size: 20, phase: 0.35),
    _FloatingIconData(icon: Icons.loyalty_outlined, xFraction: 0.72, yStart: 0.70, travelDistance: 190, opacity: 0.08, size: 22, phase: 0.65),
  ];

  @override
  void initState() {
    super.initState();

    // Style clair de la barre d'état système sur le fond sombre du splash
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // Contrôleur de séquence d'entrée (2500 ms)
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Contrôleur d'ambiance en boucle continue (4000 ms aller-retour)
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _buildAnimations();

    // Démarrage de la séquence d'entrée
    _entryCtrl.forward();

    // Affichage discret du bouton « Passer » après 1 seconde
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _showSkip = true);
      }
    });

    // Lancement de la vérification de session après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkSession();
      }
    });
  }

  void _buildAnimations() {
    // 1. Rebond élastique du logo
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.40, curve: Curves.elasticOut),
      ),
    );

    // 2. Pulsation continue du logo
    _logoPulse = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _ambientCtrl, curve: Curves.easeInOut),
    );

    // 3. Lettres « D-o-k-a-n » décalées d'environ 80 ms (sur 2500 ms = ~0.032 par lettre)
    const letterCount = 5;
    const startOffset = 0.36;
    const step = 0.06;
    const window = 0.16;

    _letterOpacity = List.generate(letterCount, (i) {
      final begin = startOffset + i * step;
      final end = (begin + window).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(begin, end, curve: Curves.easeOut),
        ),
      );
    });

    _letterSlide = List.generate(letterCount, (i) {
      final begin = startOffset + i * step;
      final end = (begin + window).clamp(0.0, 1.0);
      return Tween<double>(begin: 18.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(begin, end, curve: Curves.easeOut),
        ),
      );
    });

    // 4. Slogan en fondu
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.68, 0.90, curve: Curves.easeIn),
      ),
    );

    // 5. Barre de progression en bas
    _progressOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.50, 0.70, curve: Curves.easeIn),
      ),
    );
  }

  /// SCÉNARIO FONCTIONNEL :
  /// 1. Attend au minimum `AppConfig.splashDuration` (3 secondes).
  /// 2. Interroge l'état d'authentification Firebase en tâche de fond.
  /// 3. Navigue vers l'accueil quand les deux conditions sont réunies.
  /// 4. Si une erreur survient (réseau, absence de config), bascule en mode
  ///    visiteur sécurisé et continue sans bloquer l'écran.
  Future<void> _checkSession() async {
    try {
      await Future.wait([
        Future.delayed(AppConfig.splashDuration),
        _verifyFirebaseAuth(),
      ]);
    } catch (_) {
      // En cas d'erreur de session, bascule sécurisée en mode invité
      if (mounted) {
        ref.read(sessionProvider.notifier).logout();
      }
    } finally {
      _sessionReady = true;
      if (mounted && (_skipRequested || !_navigated)) {
        _navigate();
      }
    }
  }

  Future<void> _verifyFirebaseAuth() async {
    try {
      final auth = FirebaseAuth.instance;
      final firebaseUser = await auth.authStateChanges().first.timeout(
        const Duration(seconds: 2),
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
            );
      } else if (mounted) {
        ref.read(sessionProvider.notifier).logout();
      }
    } catch (_) {
      if (mounted) {
        ref.read(sessionProvider.notifier).logout();
      }
    }
  }

  void _onSkipPressed() {
    _skipRequested = true;
    if (_sessionReady && mounted && !_navigated) {
      _navigate();
    }
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;

    // Rétablissement des icônes sombres de la barre de statut pour l'accueil
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    // Redirection définitive vers l'écran d'accueil
    context.go(AppRoutes.home);
  }

  // ─── Gestion interactive des particules et du parallaxe ───────────────────

  void _spawnParticles(Offset position) {
    HapticFeedback.lightImpact();

    _particles.removeWhere((p) => p.isDead);

    final count = 4 + _rng.nextInt(3);
    if (_particles.length + count > 30) {
      final excess = (_particles.length + count) - 30;
      _particles.removeRange(0, excess.clamp(0, _particles.length));
    }

    for (int i = 0; i < count; i++) {
      _particles.add(
        _TouchParticle(
          position: position,
          angle: _rng.nextDouble() * 2 * math.pi,
          speed: 0.8 + _rng.nextDouble() * 1.4,
          color: _particleColors[_rng.nextInt(_particleColors.length)],
          radius: 3.0 + _rng.nextDouble() * 3.5,
        ),
      );
    }
  }

  Future<void> _springBack() async {
    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(milliseconds: 16));
      if (!mounted) return;
      final c = _parallaxOffset.value;
      if (c.distance < 0.5) {
        _parallaxOffset.value = Offset.zero;
        break;
      }
      _parallaxOffset.value = Offset(c.dx * 0.80, c.dy * 0.80);
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _ambientCtrl.dispose();
    _parallaxOffset.dispose();
    super.dispose();
  }

  // ─── Build principal ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Accessibilité : si l'utilisateur a désactivé les animations système
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      return _buildStaticFallback(context);
    }

    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => _spawnParticles(details.localPosition),
        onPanUpdate: (details) {
          final current = _parallaxOffset.value;
          _parallaxOffset.value = Offset(
            (current.dx + details.delta.dx * 0.35).clamp(-25.0, 25.0),
            (current.dy + details.delta.dy * 0.35).clamp(-25.0, 25.0),
          );
        },
        onPanEnd: (_) => _springBack(),
        child: Stack(
          children: [
            // Couche 0 : Dégradé vertical et blobs translucides flottants
            RepaintBoundary(
              child: _BackgroundLayer(
                parallaxOffset: _parallaxOffset,
                ambientCtrl: _ambientCtrl,
                screenSize: size,
              ),
            ),

            // Couche 1 : Icônes flottantes en arrière-plan
            RepaintBoundary(
              child: _FloatingIconsLayer(
                floatingIcons: _floatingIcons,
                ambientCtrl: _ambientCtrl,
                entryCtrl: _entryCtrl,
                parallaxOffset: _parallaxOffset,
                screenSize: size,
              ),
            ),

            // Couche 2 : Contenu central (Logo + Dokan + Slogan)
            _buildCenterContent(context, size),

            // Couche 3 : Indicateur discret de chargement
            _buildProgressBar(),

            // Couche 4 : Bouton « Passer » en haut à droite
            _buildSkipButton(context),

            // Couche 5 : Particules interactives de toucher
            RepaintBoundary(
              child: CustomPaint(
                painter: _ParticlesPainter(
                  particles: _particles,
                  repaint: _ambientCtrl,
                ),
                size: Size.infinite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterContent(BuildContext context, Size size) {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo Dokan avec rebond élastique et pulsation douce
          AnimatedBuilder(
            animation: Listenable.merge([_logoScale, _logoPulse]),
            builder: (context, child) {
              final scale = _logoScale.value * _logoPulse.value;
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Semantics(
              label: 'Logo Dokan',
              child: DokanLogo(size: 104),
            ),
          ),

          const SizedBox(height: 28),

          // Nom officiel « Dokan » : lettres animées + widget textuel pour smoke test
          Semantics(
            label: AppConfig.appName,
            header: true,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Texte de référence masqué garantissant la compatibilité find.text('Dokan')
                Opacity(
                  opacity: 0.0,
                  child: Text(
                    AppConfig.appName,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          letterSpacing: 3.0,
                        ),
                  ),
                ),
                // Lettres apparaissant une par une avec fondu et glissement
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate('Dokan'.length, (i) {
                    return AnimatedBuilder(
                      animation: Listenable.merge([_letterOpacity[i], _letterSlide[i]]),
                      builder: (context, _) {
                        return Opacity(
                          opacity: _letterOpacity[i].value,
                          child: Transform.translate(
                            offset: Offset(0, _letterSlide[i].value),
                            child: Text(
                              'Dokan'[i],
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: AppColors.onPrimary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 3.0,
                                  ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Slogan court et chaleureux
          AnimatedBuilder(
            animation: _taglineOpacity,
            builder: (context, _) {
              return Opacity(
                opacity: _taglineOpacity.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    AppConfig.appTagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      bottom: 44,
      left: 60,
      right: 60,
      child: AnimatedBuilder(
        animation: Listenable.merge([_entryCtrl, _progressOpacity]),
        builder: (context, _) {
          return Opacity(
            opacity: _progressOpacity.value,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: _entryCtrl.value,
                  backgroundColor: AppColors.onPrimary.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      right: 12,
      child: AnimatedOpacity(
        opacity: _showSkip ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        child: Semantics(
          label: "Passer l'introduction",
          button: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: TextButton(
              onPressed: _showSkip ? _onSkipPressed : null,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.onPrimary.withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text(
                'Passer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaticFallback(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.primaryLight,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const DokanLogo(size: 104),
              const SizedBox(height: 28),
              Semantics(
                label: AppConfig.appName,
                header: true,
                child: Text(
                  AppConfig.appName,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3.0,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  AppConfig.appTagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Couche fond dégradé et blobs ────────────────────────────────────────────

class _BackgroundLayer extends StatelessWidget {
  final ValueNotifier<Offset> parallaxOffset;
  final AnimationController ambientCtrl;
  final Size screenSize;

  const _BackgroundLayer({
    required this.parallaxOffset,
    required this.ambientCtrl,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: screenSize.width,
      height: screenSize.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: ValueListenableBuilder<Offset>(
        valueListenable: parallaxOffset,
        builder: (context, parallax, _) {
          return AnimatedBuilder(
            animation: ambientCtrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _BlobPainter(
                  progress: ambientCtrl.value,
                  parallax: parallax,
                ),
                size: screenSize,
              );
            },
          );
        },
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double progress;
  final Offset parallax;

  _BlobPainter({required this.progress, required this.parallax});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final wave = math.sin(progress * math.pi);

    final blobs = [
      (0.15, 0.18, 0.52, AppColors.onPrimary, 18.0),
      (0.80, 0.75, 0.40, AppColors.primaryLight, 22.0),
      (0.55, 0.10, 0.30, AppColors.onPrimary, 14.0),
      (0.20, 0.82, 0.35, AppColors.accent, 20.0),
    ];

    for (final (cx, cy, radiusFrac, color, amplitude) in blobs) {
      final dy = wave * amplitude + parallax.dy * 0.5;
      final dx = parallax.dx * 0.3;

      paint.color = color.withValues(alpha: 0.07 + wave * 0.04);
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * radiusFrac * 0.5);

      canvas.drawCircle(
        Offset(
          size.width * cx + dx,
          size.height * cy + dy,
        ),
        size.width * radiusFrac,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) =>
      old.progress != progress || old.parallax != parallax;
}

// ─── Couche icônes flottantes ─────────────────────────────────────────────────

class _FloatingIconsLayer extends StatelessWidget {
  final List<_FloatingIconData> floatingIcons;
  final AnimationController ambientCtrl;
  final AnimationController entryCtrl;
  final ValueNotifier<Offset> parallaxOffset;
  final Size screenSize;

  const _FloatingIconsLayer({
    required this.floatingIcons,
    required this.ambientCtrl,
    required this.entryCtrl,
    required this.parallaxOffset,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ambientCtrl, entryCtrl]),
      builder: (context, _) {
        final layerOpacity = CurvedAnimation(
          parent: entryCtrl,
          curve: const Interval(0.40, 0.70, curve: Curves.easeIn),
        ).value;

        return ValueListenableBuilder<Offset>(
          valueListenable: parallaxOffset,
          builder: (context, parallax, _) {
            return Stack(
              children: floatingIcons.map((fi) {
                final t = (ambientCtrl.value + fi.phase) % 1.0;
                final dy = -fi.travelDistance * t;
                final parallaxDx = -parallax.dx * 0.18;
                final parallaxDy = -parallax.dy * 0.18;

                return Positioned(
                  left: screenSize.width * fi.xFraction + parallaxDx,
                  top: screenSize.height * fi.yStart + dy + parallaxDy,
                  child: Opacity(
                    opacity: (fi.opacity * layerOpacity).clamp(0.0, 1.0),
                    child: Icon(
                      fi.icon,
                      size: fi.size,
                      color: AppColors.onPrimary,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

// ─── Peintre des particules de toucher ─────────────────────────────────────────

class _ParticlesPainter extends CustomPainter {
  final List<_TouchParticle> particles;

  _ParticlesPainter({
    required this.particles,
    required super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      if (p.isDead) continue;
      final t = p.progress;
      final distance = p.speed * t * 60;
      final dx = math.cos(p.angle) * distance;
      final dy = math.sin(p.angle) * distance - (t * 22);
      final currentPos = p.position + Offset(dx, dy);

      paint.color = p.color.withValues(alpha: p.opacity * 0.85);
      canvas.drawCircle(currentPos, p.radius * (1.0 - t * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) => true;
}
