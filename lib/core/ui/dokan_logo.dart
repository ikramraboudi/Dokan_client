/// ============================================================================
/// RÔLE DU FICHIER :
/// Widget réutilisable `DokanLogo` — la carte-logo officielle de l'application.
///
/// OBJECTIF :
/// Centraliser la représentation visuelle du logo Dokan en un seul endroit.
/// Pour remplacer l'icône par un vrai fichier image (PNG/SVG), il suffit de
/// modifier uniquement ce widget ; tous les écrans qui l'utilisent se mettent
/// à jour automatiquement.
///
/// UTILISATION PRINCIPALE :
/// - Splash Screen (avec animation de rebond élastique pilotée par le parent).
/// - Potentiellement : écran de connexion, en-tête, page d'erreur.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/ui/` (Composants Communs Réutilisables).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : `lib/feature/splash/splash_screen.dart`.
/// - Dépend de : `AppColors` (palette de couleurs centralisée).
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Carte-logo arrondie de l'application Dokan.
///
/// PARAMÈTRE [size] : Taille du côté de la carte carrée (par défaut 96 dp).
/// Le parent est responsable des animations (scale, pulsation, etc.) :
/// il suffit d'envelopper ce widget dans un `ScaleTransition` ou `Transform.scale`.
class DokanLogo extends StatelessWidget {
  /// Taille du côté de la carte carrée en dp.
  final double size;

  const DokanLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    // Rayon des coins proportionnel à la taille pour un résultat cohérent
    // quelle que soit la taille demandée.
    final radius = size * 0.22;

    // Taille de l'icône intérieure (environ 55 % de la carte).
    final iconSize = size * 0.55;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Fond blanc légèrement teinté pour contraster avec le gradient sombre du splash.
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        // Ombre douce et colorée pour « soulever » la carte du fond.
        boxShadow: [
          BoxShadow(
            // Ombre principale (large et diffuse)
            color: AppColors.primaryDark.withValues(alpha: 0.35),
            blurRadius: size * 0.28,
            spreadRadius: size * 0.04,
            offset: Offset(0, size * 0.08),
          ),
          BoxShadow(
            // Reflet blanc en haut à gauche (effet glassmorphism léger)
            color: AppColors.surface.withValues(alpha: 0.6),
            blurRadius: size * 0.10,
            offset: Offset(-(size * 0.04), -(size * 0.04)),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          // Icône de vitrine / boutique Material Design.
          // TODO Logo : remplacer par Image.asset('assets/logo.png') ou SvgPicture
          // lorsque le vrai logo du client sera disponible.
          Icons.storefront_rounded,
          size: iconSize,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
