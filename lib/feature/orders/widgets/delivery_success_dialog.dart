/// ============================================================================
/// RÔLE DU FICHIER : Boîte de dialogue festive de célébration de livraison réussie
///                   avec système de notation directe du livreur (1 à 5 étoiles)
///                   et passerelle vers les avis produits.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/firestore_orders_repository.dart';

class DeliverySuccessDialog extends ConsumerStatefulWidget {
  final OrderUiModel order;

  const DeliverySuccessDialog({
    super.key,
    required this.order,
  });

  static Future<void> show(BuildContext context, OrderUiModel order) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DeliverySuccessDialog(order: order),
    );
  }

  @override
  ConsumerState<DeliverySuccessDialog> createState() =>
      _DeliverySuccessDialogState();
}

class _DeliverySuccessDialogState extends ConsumerState<DeliverySuccessDialog> {
  int _rating = 5;
  final Set<String> _selectedCompliments = {};
  bool _isSavingRating = false;
  bool _ratingSaved = false;

  final List<String> _complimentTags = [
    'Ponctuel ⏱️',
    'Courtois & Souriant 😊',
    'Colis soigné 📦',
    'Professionnel ⭐',
  ];

  Future<void> _submitDriverFeedback() async {
    if (_isSavingRating || _ratingSaved) return;
    setState(() => _isSavingRating = true);

    try {
      final repo = ref.read(ordersRepositoryProvider);
      final feedback = _selectedCompliments.join(', ');
      await repo.confirmDelivery(
        orderId: widget.order.id,
        confirmationMethod: widget.order.deliveryConfirmedBy ?? 'client_confirmation',
        driverRating: _rating,
        driverFeedback: feedback,
      );
      if (mounted) {
        setState(() {
          _isSavingRating = false;
          _ratingSaved = true;
        });
        HapticFeedback.lightImpact();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSavingRating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverName = widget.order.driver?.name.trim();
    final effectiveDriverName =
        (driverName != null && driverName.isNotEmpty) ? driverName : 'votre livreur Dokan';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radius24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: AppColors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône animée de célébration
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 54,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Titre de succès
            const Text(
              '🎉 Commande bien reçue !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimens.space8),

            Text(
              'Merci pour votre confiance ! Votre commande ${widget.order.displayNumber} est officiellement validée.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),

            const SizedBox(height: AppDimens.space20),
            const Divider(),
            const SizedBox(height: AppDimens.space12),

            // Section notation livreur
            Text(
              'Comment s\'est passée la livraison avec $effectiveDriverName ?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimens.space12),

            // Étoiles de notation interactives
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final isSelected = starIndex <= _rating;
                return IconButton(
                  iconSize: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  icon: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSelected ? Colors.amber : AppColors.border,
                  ),
                  onPressed: _ratingSaved
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          setState(() => _rating = starIndex);
                        },
                );
              }),
            ),

            const SizedBox(height: AppDimens.space8),

            // Tags de compliments rapides
            if (!_ratingSaved) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _complimentTags.map((tag) {
                  final isSelected = _selectedCompliments.contains(tag);
                  return FilterChip(
                    label: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedCompliments.add(tag);
                        } else {
                          _selectedCompliments.remove(tag);
                        }
                      });
                    },
                    selectedColor: AppColors.primarySoft,
                    backgroundColor: AppColors.surfaceAlt,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimens.space16),

              // Bouton valider la note du livreur
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radius12),
                  ),
                ),
                onPressed: _isSavingRating ? null : _submitDriverFeedback,
                icon: _isSavingRating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  _isSavingRating
                      ? 'Enregistrement...'
                      : 'Envoyer la note du livreur',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radius12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 16, color: AppColors.success),
                    SizedBox(width: 6),
                    Text(
                      'Merci pour votre note !',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppDimens.space20),

            // Action : Noter les articles
            if (widget.order.items.isNotEmpty) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radius12),
                  ),
                ),
                icon: const Icon(Icons.rate_review_rounded, size: 20),
                label: const Text(
                  'Donner mon avis sur les articles',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Ouvre directement l'avis pour le premier produit de la commande
                  final firstProduct = widget.order.items.first;
                  context.push(
                    '${AppRoutes.myOrders}/${widget.order.id}/review/${firstProduct.productId}',
                  );
                },
              ),
              const SizedBox(height: AppDimens.space10),
            ],

            // Bouton Terminer
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Fermer',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
