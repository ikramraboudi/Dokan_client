/// ============================================================================
/// RÔLE DU FICHIER : Configuration centralisée des options produit (couleurs et tailles)
/// par catégorie et helpers d'affichage pour Dokan Client.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../../data/models/product_ui_model.dart';

/// Définition d'une couleur d'option produit avec libellé d'accessibilité et code couleur.
class ProductColor {
  final String key;
  final String name; // Utilisé pour l'accessibilité / Semantics (jamais affiché en texte brut)
  final Color color;
  final Color? borderColor;

  const ProductColor({
    required this.key,
    required this.name,
    required this.color,
    this.borderColor,
  });
}

/// Gestionnaire centralisé des options de couleurs et de tailles des produits.
class ProductOptions {
  ProductOptions._();

  /// Palette des 11 couleurs officielles Dokan.
  static const Map<String, ProductColor> allColors = {
    'blanc': ProductColor(
      key: 'blanc',
      name: 'Blanc',
      color: Color(0xFFFFFFFF),
      borderColor: Color(0xFFD0D0D0),
    ),
    'noir': ProductColor(
      key: 'noir',
      name: 'Noir',
      color: Color(0xFF111111),
    ),
    'beige': ProductColor(
      key: 'beige',
      name: 'Beige',
      color: Color(0xFFD8C3A5),
    ),
    'bleu_marine': ProductColor(
      key: 'bleu_marine',
      name: 'Bleu marine',
      color: Color(0xFF1F2A44),
    ),
    'rouge': ProductColor(
      key: 'rouge',
      name: 'Rouge',
      color: Color(0xFFD32F2F),
    ),
    'vert': ProductColor(
      key: 'vert',
      name: 'Vert',
      color: Color(0xFF2E7D32),
    ),
    'bleu': ProductColor(
      key: 'bleu',
      name: 'Bleu',
      color: Color(0xFF1976D2),
    ),
    'jaune': ProductColor(
      key: 'jaune',
      name: 'Jaune',
      color: Color(0xFFFBC02D),
    ),
    'bronze': ProductColor(
      key: 'bronze',
      name: 'Bronze',
      color: Color(0xFFCD7F32),
    ),
    'dore': ProductColor(
      key: 'dore',
      name: 'Doré',
      color: Color(0xFFD4AF37),
    ),
    'argent': ProductColor(
      key: 'argent',
      name: 'Argent',
      color: Color(0xFFC0C0C0),
    ),
    'rouge_bordeaux': ProductColor(
      key: 'rouge_bordeaux',
      name: 'Rouge bordeaux',
      color: Color(0xFF6B1D2F),
    ),
    'bordeaux': ProductColor(
      key: 'bordeaux',
      name: 'Rouge bordeaux',
      color: Color(0xFF6B1D2F),
    ),
    'gris': ProductColor(
      key: 'gris',
      name: 'Gris',
      color: Color(0xFF757575),
    ),
  };

  /// Normalisation de chaîne pour correspondance insensible à la casse et aux accents.
  static String normalize(String input) {
    var result = input.toLowerCase().trim();
    // Suppression des préfixes de catégorie (ex: 'cat_')
    if (result.startsWith('cat_')) {
      result = result.substring(4);
    }
    // Remplacement des caractères accentués
    result = result
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c');

    // Remplacement des séparateurs courants
    result = result
        .replaceAll('&', 'et')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    return result;
  }

  /// Détermine le groupe d'options (A, B, C, D, E) selon la catégorie.
  /// Renvoie null si la catégorie n'est pas concernée.
  static String? getGroupForCategory(String? categoryNameOrId) {
    if (categoryNameOrId == null || categoryNameOrId.trim().isEmpty) {
      return null;
    }
    final norm = normalize(categoryNameOrId);

    // Groupe A : Électroménager, Smartphones, Tech, Électronique
    if (norm == 'electromenager' ||
        norm == 'smartphones' ||
        norm == 'smartphone' ||
        norm == 'tech' ||
        norm == 'techs' ||
        norm == 'electronique') {
      return 'A';
    }

    // Groupe B : Chaussures
    if (norm == 'chaussures' || norm == 'chaussure') {
      return 'B';
    }

    // Groupe C : Vêtements
    if (norm == 'vetements' || norm == 'vetement') {
      return 'C';
    }

    // Groupe D : Accessoires
    if (norm == 'accessoires' || norm == 'accessoire') {
      return 'D';
    }

    // Groupe E : Papeterie et bureau, Sport et air
    if (norm == 'papeteriebureau' ||
        norm == 'papeterieetbureau' ||
        norm == 'sportair' ||
        norm == 'sportetair' ||
        norm == 'sportpleinair' ||
        norm == 'sportetpleinair') {
      return 'E';
    }

    return null;
  }

  /// Couleurs par défaut par groupe
  static List<String> getDefaultColorsForGroup(String group) {
    switch (group) {
      case 'A':
        return const ['blanc', 'noir', 'beige', 'rouge_bordeaux', 'gris'];
      case 'B':
        return const ['noir', 'blanc', 'bleu_marine'];
      case 'C':
        return const ['noir', 'blanc', 'rouge', 'vert', 'bleu', 'jaune'];
      case 'D':
        return const ['bronze', 'dore', 'argent'];
      case 'E':
        return const ['blanc', 'noir', 'beige'];
      default:
        return const [];
    }
  }

  /// Tailles par défaut par groupe
  static List<String> getDefaultSizesForGroup(String group) {
    switch (group) {
      case 'B':
        return const ['36', '38', '39', '40', '41', '42', '43', '44'];
      case 'C':
        return const ['S', 'M', 'L', 'XL', 'XXL'];
      default:
        return const [];
    }
  }

  /// Retourne les couleurs applicables pour un produit donné.
  static List<String> getColorsForProduct(ProductUiModel product) {
    if (product.colors != null && product.colors!.isNotEmpty) {
      return product.colors!;
    }
    final group = getGroupForCategory(product.categoryName);
    if (group != null) {
      return getDefaultColorsForGroup(group);
    }
    return const [];
  }

  /// Retourne les tailles applicables pour un produit donné.
  static List<String> getSizesForProduct(ProductUiModel product) {
    if (product.sizes != null && product.sizes!.isNotEmpty) {
      return product.sizes!;
    }
    final group = getGroupForCategory(product.categoryName);
    if (group != null) {
      return getDefaultSizesForGroup(group);
    }
    return const [];
  }

  /// Indique si un produit propose des options (couleur ou taille).
  static bool hasOptions(ProductUiModel product) {
    return getColorsForProduct(product).isNotEmpty ||
        getSizesForProduct(product).isNotEmpty;
  }

  /// Récupère la définition d'une couleur par sa clé.
  static ProductColor? getColor(String? key) {
    if (key == null) return null;
    final cleanKey = key.trim().toLowerCase().replaceAll(' ', '_');
    return allColors[cleanKey];
  }
}

/// Indicateur visuel compact (petit cube de couleur + taille) réutilisable
/// dans le panier, la commande et l'historique des commandes.
class ProductVariantIndicator extends StatelessWidget {
  final String? colorKey;
  final String? size;
  final double cubeSize;

  const ProductVariantIndicator({
    super.key,
    this.colorKey,
    this.size,
    this.cubeSize = 13.0,
  });

  @override
  Widget build(BuildContext context) {
    final productColor = ProductOptions.getColor(colorKey);
    final hasColor = productColor != null;
    final hasSize = size != null && size!.trim().isNotEmpty;

    if (!hasColor && !hasSize) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 3.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasColor) ...[
            Semantics(
              label: 'Couleur : ${productColor.name}',
              child: Container(
                width: cubeSize,
                height: cubeSize,
                decoration: BoxDecoration(
                  color: productColor.color,
                  borderRadius: BorderRadius.circular(3.0),
                  border: Border.all(
                    color: productColor.borderColor ?? AppColors.border,
                    width: productColor.borderColor != null ? 1.0 : 0.6,
                  ),
                ),
              ),
            ),
          ],
          if (hasColor && hasSize) ...[
            const SizedBox(width: AppDimens.space6),
            const Text(
              '·',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppDimens.space6),
          ],
          if (hasSize) ...[
            Text(
              size!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
