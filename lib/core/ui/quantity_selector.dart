/// ============================================================================
/// RÔLE DU FICHIER :
/// Contrôle interactif d'ajustement numérique de quantité (`QuantitySelector`).
/// Permet à l'acheteur d'augmenter (`[+]`) ou de diminuer (`[-]`) le nombre
/// d'exemplaires d'un produit dans son panier ou sur la fiche détaillée, avec
/// protection stricte des bornes minimales et des stocks disponibles.
///
/// ERGONOMIE ET ACCESSIBILITÉ :
/// - Les boutons tactiles mesurent au moins 48 × 48 dp (`AppDimens.minTouchTarget`).
/// - Les boutons s'estompent et se désactivent automatiquement aux bornes.
/// - Chaque bouton comporte un libellé sémantique vocal (`Semantics`) et un `tooltip`.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/ui/` (Composant de Sélection Numérique).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par :
///   * `lib/feature/product/product_detail_screen.dart` (choix avant ajout au panier).
///   * `lib/feature/cart/cart_screen.dart` (modification de quantité dans le panier).
/// - Dépend de : `core/theme/app_colors.dart` et `core/theme/app_dimens.dart`.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Sélecteur de quantité numérique borné [-] quantité [+].
class QuantitySelector extends StatelessWidget {
  /// Quantité actuelle sélectionnée.
  final int quantity;

  /// Fonction de rappel déclenchée lors d'un changement de valeur.
  final ValueChanged<int>? onChanged;

  /// Valeur minimale autorisée (par défaut 1).
  final int min;

  /// Valeur maximale autorisée (stock disponible du produit, par défaut 10).
  final int max;

  /// Indique si le contrôle est interactif (désactivé si article en rupture).
  final bool enabled;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.min = 1,
    this.max = 10,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Calcul de l'état d'activation des deux boutons aux extrémités
    final canDecrease = enabled && quantity > min;
    final canIncrease = enabled && quantity < max;

    return Container(
      decoration: BoxDecoration(
        color: enabled ? AppColors.surface : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppDimens.radius12),
        border: Border.all(
          color: enabled ? AppColors.border : AppColors.divider,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Bouton Diminuer (-) ---
          Semantics(
            label: 'Diminuer la quantité',
            button: true,
            enabled: canDecrease,
            child: SizedBox(
              width: AppDimens.minTouchTarget,
              height: AppDimens.minTouchTarget,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.remove_rounded, size: 18),
                color: canDecrease ? AppColors.textPrimary : AppColors.textHint,
                tooltip: 'Diminuer',
                onPressed: canDecrease ? () => onChanged?.call(quantity - 1) : null,
              ),
            ),
          ),

          // --- Affichage du nombre actuel ---
          Container(
            constraints: const BoxConstraints(minWidth: 36),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space8),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: enabled ? AppColors.textPrimary : AppColors.textHint,
              ),
            ),
          ),

          // --- Bouton Augmenter (+) ---
          Semantics(
            label: 'Augmenter la quantité',
            button: true,
            enabled: canIncrease,
            child: SizedBox(
              width: AppDimens.minTouchTarget,
              height: AppDimens.minTouchTarget,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add_rounded, size: 18),
                color: canIncrease ? AppColors.textPrimary : AppColors.textHint,
                tooltip: 'Augmenter',
                onPressed: canIncrease ? () => onChanged?.call(quantity + 1) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
