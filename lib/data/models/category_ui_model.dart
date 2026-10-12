/// ============================================================================
/// RÔLE DU FICHIER :
/// Modèle d'affichage d'une catégorie du catalogue Dokan (`CategoryUiModel`).
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `data/models/` (Modèle d'Affichage UI).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par :
///   * `CatalogRepository` et `MockCatalogRepository`.
///   * `HomeScreen` (raccourcis ronds de catégories).
///   * `CategoriesScreen` (liste détaillée des rubriques).
/// - Dépend de : `package:flutter/material.dart` pour le type `IconData`.
/// ============================================================================
library;

import 'package:flutter/material.dart';

/// Catégorie de produits du catalogue Dokan.
class CategoryUiModel {
  /// Identifiant technique de la catégorie (ex: 'cat_1').
  final String id;

  /// Nom affiché en français (ex: 'Électronique et technologie').
  final String name;

  /// Icône vectorielle Material représentative.
  final IconData icon;

  /// Nombre total d'articles recensés dans cette catégorie.
  final int productCount;

  const CategoryUiModel({
    required this.id,
    required this.name,
    required this.icon,
    this.productCount = 0,
  });

  /// Méthode de clonage immuable avec substitution ciblée.
  CategoryUiModel copyWith({
    String? id,
    String? name,
    IconData? icon,
    int? productCount,
  }) {
    return CategoryUiModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      productCount: productCount ?? this.productCount,
    );
  }
}
