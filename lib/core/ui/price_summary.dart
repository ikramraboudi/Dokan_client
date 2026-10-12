/// ============================================================================
/// RÔLE DU FICHIER :
/// Encadré de synthèse financière de la commande (`PriceSummary`).
/// Affiche la ventilation complète des coûts du panier : sous-total brut,
/// remise promotionnelle déduite (en vert si code appliqué), frais de livraison
/// estimés (ou "Gratuite" dès le seuil atteint), et le total général TTC.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `core/ui/` (Composant Récapitulatif Financier).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : `lib/feature/cart/cart_screen.dart` au bas de la liste d'articles.
/// - Dépend de :
///   * `core/config/app_config.dart` pour le formatage monétaire `formatPrice()`.
///   * `core/theme/app_colors.dart` et `core/theme/app_dimens.dart`.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Carte affichant les totaux chiffrés du panier d'achat.
class PriceSummary extends StatelessWidget {
  /// Montant brut de l'ensemble des articles.
  final double subtotal;

  /// Montant de la réduction accordée par le code promo (0.0 si aucun).
  final double discountAmount;

  /// Libellé du code promo actuellement appliqué (ex: 'Dokan10').
  final String? promoCode;

  /// Frais d'expédition (0.0 si livraison offerte).
  final double deliveryFee;

  /// Montant final toutes taxes comprises à régler.
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
          // Titre de la section
          Text(
            'Récapitulatif de la commande',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppDimens.space16),

          // Ligne 1 : Sous-total brut
          _buildRow(
            label: 'Sous-total',
            value: AppConfig.formatPrice(subtotal),
          ),
          const SizedBox(height: AppDimens.space8),

          // Ligne 2 : Remise promotionnelle conditionnelle
          if (discountAmount > 0) ...[
            _buildRow(
              label: promoCode != null ? 'Remise ($promoCode)' : 'Remise',
              value: '- ${AppConfig.formatPrice(discountAmount)}',
              valueColor: AppColors.success,
            ),
            const SizedBox(height: AppDimens.space8),
          ],

          // Ligne 3 : Frais de port estimés
          _buildRow(
            label: 'Livraison estimée',
            value: deliveryFee == 0 ? 'Gratuite' : AppConfig.formatPrice(deliveryFee),
            valueColor: deliveryFee == 0 ? AppColors.success : AppColors.textPrimary,
          ),

          const Divider(
            color: AppColors.divider,
            height: AppDimens.space24,
          ),

          // Ligne 4 : Total TTC mis en valeur
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

  /// Méthode d'aide pour générer une ligne clé/valeur alignée
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
