/// ============================================================================
/// RÔLE DU FICHIER :
/// REGISTRE UNIQUE ET EXCLUSIF DE TOUTES LES COULEURS DE L'APPLICATION Dokan.
///
/// RÈGLE ARCHITECTURALE ABSOLUE DU PROJET :
/// Aucune couleur ne doit être écrite en dur ailleurs dans le code source
/// (interdiction stricte de `Color(0x...)` ou de `Colors.xxx` dans tout autre fichier).
/// Tous les widgets consomment soit `AppColors.xxx`, soit `Theme.of(context)`.
///
/// OBJECTIF :
/// Permettre au designer ou au propriétaire du produit de modifier toute l'identité
/// colorée de l'application en éditant uniquement ce fichier.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/theme/` (Design System / Palette).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : Absolument tous les composants de `core/ui/`, `core/theme/`
///   et tous les écrans de `feature/`.
/// - Dépend de : `package:flutter/material.dart` pour la classe `Color`.
/// ============================================================================
library;

import 'package:flutter/material.dart';

/// Palette de couleurs complète de l'application mobile Dokan.
class AppColors {
  /// Constructeur privé pour empêcher toute instanciation.
  AppColors._();

  // --- Couleur principale : bleu pétrole / vert canard (Identité premium et chaleureuse) ---
  static const Color primary       = Color(0xFF1F7A7A);
  static const Color primaryDark   = Color(0xFF155B5E);
  static const Color primaryLight  = Color(0xFF5FA8A6);
  static const Color primarySoft   = Color(0xFFE3F1F0); // Fonds teintés légers (puces, cercles d'icônes)
  static const Color onPrimary     = Color(0xFFFFFFFF); // Texte ou icône posé sur la couleur primaire

  // --- Couleur d'accent : sable / ambre doux (Mise en avant des promotions et badges) ---
  static const Color accent        = Color(0xFFF2A65A);
  static const Color accentSoft    = Color(0xFFFDEFDD); // Fond du badge promo
  static const Color onAccent      = Color(0xFF3D2A14);

  // --- Favoris : corail doux ---
  static const Color favorite      = Color(0xFFE05A6D);
  static const Color favoriteSoft  = Color(0xFFFBE7EA); // Fond de l'icône cœur en grand format

  // --- Fonds et surfaces (Fond clair chaud pour un aspect convivial et reposant) ---
  static const Color background    = Color(0xFFF7F5F0); // Fond général de l'écran (Scaffold)
  static const Color surface       = Color(0xFFFFFFFF); // Surface des cartes, champs et dialogues
  static const Color surfaceAlt    = Color(0xFFEFEDE8); // Zones secondaires (puces neutres, séparateurs)
  static const Color border        = Color(0xFFE4E1DA); // Bordures des conteneurs et des cartes
  static const Color divider       = Color(0xFFECE9E3); // Lignes séparatrices fines

  // --- Textes (Hiérarchie de contraste optimisée pour la lisibilité) ---
  static const Color textPrimary   = Color(0xFF1E2B2F); // Titres et textes principaux (très contrasté)
  static const Color textSecondary = Color(0xFF5B6B70); // Textes secondaires, sous-titres, libellés
  static const Color textHint      = Color(0xFF8A979B); // Textes d'indications dans les champs (placeholders)
  static const Color textOnDark    = Color(0xFFFFFFFF); // Texte contrasté sur fond sombre ou coloré

  // --- États et retours visuels (Succès, Avertissement, Erreur) ---
  static const Color success       = Color(0xFF2E9E6B); // Validation, code promo appliqué, en stock
  static const Color successSoft   = Color(0xFFE2F4EB); // Fond teinté du message de succès
  static const Color warning       = Color(0xFFE0A030); // Stock limité, alerte non bloquante
  static const Color error         = Color(0xFFD64545); // Erreurs de formulaire, rupture de stock, échec
  static const Color errorSoft     = Color(0xFFFBE6E6); // Fond teinté du bandeau d'erreur
  static const Color info          = Color(0xFF3B82B6); // Informations neutres

  // --- Divers et effets visuels ---
  static const Color transparent   = Color(0x00000000); // Couleur transparente (remplace Colors.transparent)
  static const Color shadow        = Color(0x14000000); // Ombre portée très légère (8% d'opacité)
  static const Color overlay       = Color(0x66000000); // Fond obscurci des fenêtres modales
  static const Color shimmerBase   = Color(0xFFE9E6E0); // Base de l'animation de chargement
  static const Color shimmerHigh   = Color(0xFFF6F4EF); // Brillance de l'animation de chargement
  static const Color star          = Color(0xFFF2B01E); // Étoiles de notation des produits
}
