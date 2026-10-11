import 'package:flutter/material.dart';

/// ============================================================
///  SOUKNA — MODÈLE D'AFFICHAGE CATÉGORIE
/// ============================================================
class CategoryUiModel {
  final String id;
  final String name;
  final IconData icon;
  final int productCount;

  const CategoryUiModel({
    required this.id,
    required this.name,
    required this.icon,
    this.productCount = 0,
  });

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
