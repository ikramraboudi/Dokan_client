import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// ============================================================
///  SOUKNA — SÉLECTEUR DE QUANTITÉ (+ / -)
/// ============================================================
class QuantitySelector extends StatelessWidget {
  final int quantity;
  final ValueChanged<int>? onChanged;
  final int min;
  final int max;
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
          // Bouton Diminuer (-)
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

          // Quantité affichée
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

          // Bouton Augmenter (+)
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
