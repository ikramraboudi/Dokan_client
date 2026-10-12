/// ============================================================================
/// RÔLE DU FICHIER :
/// Effet d'animation de chargement squelette ("Shimmer") codé en natif pur Flutter.
/// Il remplace les spinners circulaires par des rectangles aux bords arrondis
/// parcourus d'une vague lumineuse, préfigurant la mise en page finale.
///
/// PARTICULARITÉ TECHNIQUE :
/// Réalisé SANS AUCUN PACKAGE EXTERNE grâce à `AnimationController`, `AnimatedBuilder`
/// et un masque de dégradé `ShaderMask`.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/ui/` (Composant d'État de Chargement).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par :
///   * `HomeScreen` (sections de chargement).
///   * `ProductGrid` (grille squelette pendant les requêtes).
///   * `CategoriesScreen` (chargement de la liste).
/// - Dépend de : `core/theme/app_colors.dart` et `core/theme/app_dimens.dart`.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Conteneur animant un dégradé linéaire lumineux sur tous ses enfants.
///
/// MOT TECHNIQUE - SingleTickerProviderStateMixin :
/// Fournit le signal de synchronisation d'images (ticks à 60 ou 120 FPS)
/// nécessaire au fonctionnement fluide de l'AnimationController.
class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({
    super.key,
    required this.child,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Boucle d'animation infinie d'une durée de 1,2 seconde par balayage
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    // Libération impérative de la ressource d'animation pour éviter toute fuite mémoire
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // MOT TECHNIQUE - ShaderMask :
        // Applique un shader graphique (ici un dégradé mobile) sur la forme du widget enfant.
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                AppColors.shimmerBase,
                AppColors.shimmerHigh,
                AppColors.shimmerBase,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Bloc rectangulaire teinté figurant une image ou une ligne de texte en cours de chargement.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppDimens.radius8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Liste squelette complète affichée par défaut pendant le chargement d'une collection.
class LoadingState extends StatelessWidget {
  final String? message;
  final int itemCount;

  const LoadingState({
    super.key,
    this.message,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppDimens.space16),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: AppDimens.space16),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(AppDimens.space12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radius12),
          ),
          child: Row(
            children: [
              const ShimmerBox(
                width: 72,
                height: 72,
                borderRadius: AppDimens.radius12,
              ),
              const SizedBox(width: AppDimens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(height: 16, width: double.infinity),
                    SizedBox(height: AppDimens.space8),
                    ShimmerBox(height: 14, width: 140),
                    SizedBox(height: AppDimens.space8),
                    ShimmerBox(height: 18, width: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
