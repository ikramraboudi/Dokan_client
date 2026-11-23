/// ============================================================================
/// RÔLE DU FICHIER :
/// Barre de résumé flottante (« FloatingCartBar ») affichée au-dessus de la
/// barre de navigation lorsque le panier contient des articles.
///
/// COMPORTEMENT :
/// - Glissement d'apparition vers le haut en 300 ms avec léger rebond.
/// - Compteur d'articles, total animé et bouton « Voir le panier ».
/// - N'apparaît pas sur l'écran du panier, ni checkout, ni détail produit.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_config.dart';
import '../../navigation/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../../data/mock/mock_cart_repository.dart';

class FloatingCartBar extends ConsumerWidget {
  final VoidCallback? onTap;

  const FloatingCartBar({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final itemCount = cartState.totalItemCount;
    final total = cartState.total;

    final isVisible = itemCount > 0;

    return AnimatedSlide(
      offset: isVisible ? Offset.zero : const Offset(0, 2.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
          child: Material(
            color: Colors.transparent,
            elevation: 8,
            shadowColor: AppColors.primary.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
            child: InkWell(
              onTap: () {
                if (onTap != null) {
                  onTap!();
                } else {
                  context.push(AppRoutes.cart);
                }
              },
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              child: Ink(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF288585),
                      AppColors.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Icône chariot avec pastille compteur
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space10),

                    // Libellé articles & total animé
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            itemCount == 1 ? '1 article' : '$itemCount articles',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            ' · ',
                            style: TextStyle(color: Colors.white38, fontSize: 14),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.4),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: FadeTransition(opacity: animation, child: child),
                              );
                            },
                            child: Text(
                              AppConfig.formatPrice(total),
                              key: ValueKey<double>(total),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bouton texte « Voir le panier » + flèche
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Voir le panier',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppDimens.space4),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
