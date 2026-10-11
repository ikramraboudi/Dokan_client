import 'package:flutter/material.dart';

/// ============================================================
///  SOUKNA — PALETTE DE COULEURS (SEUL ENDROIT À MODIFIER)
///  Pour changer le style de l'app, modifiez uniquement ce fichier.
/// ============================================================
class AppColors {
  AppColors._();

  // --- Couleur principale : bleu pétrole / vert canard ---
  static const Color primary       = Color(0xFF1F7A7A);
  static const Color primaryDark   = Color(0xFF155B5E);
  static const Color primaryLight  = Color(0xFF5FA8A6);
  static const Color primarySoft   = Color(0xFFE3F1F0); // fonds teintés (chips, icônes)
  static const Color onPrimary     = Color(0xFFFFFFFF);

  // --- Couleur d'accent : sable / ambre doux (promos, badges) ---
  static const Color accent        = Color(0xFFF2A65A);
  static const Color accentSoft    = Color(0xFFFDEFDD);
  static const Color onAccent      = Color(0xFF3D2A14);

  // --- Favoris ---
  static const Color favorite      = Color(0xFFE05A6D);
  static const Color favoriteSoft  = Color(0xFFFBE7EA);

  // --- Fonds et surfaces ---
  static const Color background    = Color(0xFFF7F5F0); // fond clair chaud
  static const Color surface       = Color(0xFFFFFFFF); // cartes, champs
  static const Color surfaceAlt    = Color(0xFFEFEDE8); // zones secondaires
  static const Color border        = Color(0xFFE4E1DA);
  static const Color divider       = Color(0xFFECE9E3);

  // --- Textes ---
  static const Color textPrimary   = Color(0xFF1E2B2F); // texte foncé
  static const Color textSecondary = Color(0xFF5B6B70); // gris secondaire
  static const Color textHint      = Color(0xFF8A979B);
  static const Color textOnDark    = Color(0xFFFFFFFF);

  // --- États ---
  static const Color success       = Color(0xFF2E9E6B);
  static const Color successSoft   = Color(0xFFE2F4EB);
  static const Color warning       = Color(0xFFE0A030);
  static const Color error         = Color(0xFFD64545);
  static const Color errorSoft     = Color(0xFFFBE6E6);
  static const Color info          = Color(0xFF3B82B6);

  // --- Divers ---
  static const Color transparent   = Color(0x00000000);
  static const Color shadow        = Color(0x14000000); // ombre très légère
  static const Color overlay       = Color(0x66000000); // fond des dialogues
  static const Color shimmerBase   = Color(0xFFE9E6E0);
  static const Color shimmerHigh   = Color(0xFFF6F4EF);
  static const Color star          = Color(0xFFF2B01E); // étoiles de notation
}
