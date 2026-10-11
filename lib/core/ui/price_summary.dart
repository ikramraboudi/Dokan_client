import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// ============================================================
///  SOUKNA — RÉCAPITULATIF DES PRIX DU PANIER (PRICESUMMARY)
/// ============================================================
class PriceSummary extends StatelessWidget {
  final double subtotal;
  final double discountAmount;
  final String? promoCode;
  final double deliveryFee;
  final double total;

  const PriceSummary({
    super.key,
    required this.subtotal,
    required this.discountAmount,
    this.promoCode,
    required this.deliveryFee,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Récapitulatif de la commande',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppDimens.space16),

          // Sous-total
          _buildRow(
            label: 'Sous-total',
            value: AppConfig.formatPrice(subtotal),
          ),
          const SizedBox(height: AppDimens.space8),

          // Remise si applicable
          if (discountAmount > 0) ...[
            _buildRow(
              label: promoCode != null ? 'Remise ($promoCode)' : 'Remise',
              value: '- ${AppConfig.formatPrice(discountAmount)}',
              valueColor: AppColors.success,
            ),
            const SizedBox(height: AppDimens.space8),
          ],

          // Frais de livraison
          _buildRow(
            label: 'Livraison estimée',
            value: deliveryFee == 0 ? 'Gratuite' : AppConfig.formatPrice(deliveryFee),
            valueColor: deliveryFee == 0 ? AppColors.success : AppColors.textPrimary,
          ),

          const Divider(
            color: AppColors.divider,
            height: AppDimens.space24,
          ),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total TTC',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Taxes incluses',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                ],
              ),
              Text(
                AppConfig.formatPrice(total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String value,
    Color valueColor = AppColors.textPrimary,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
