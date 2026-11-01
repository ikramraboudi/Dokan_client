/// ============================================================================
/// RÔLE DU FICHIER :
/// Écran « Passage de commande » (Checkout).
/// Regroupe le récapitulatif des articles, le choix de l'adresse de livraison,
/// le mode de livraison standard, le paiement à la livraison et la validation atomique.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche feature/checkout/ (Interface Utilisateur / Commande).
///
/// RELATIONS ET DÉPENDANCES :
/// - Déclenché par : CartScreen (« Commander »).
/// - Dépend de : cartProvider, addressesStreamProvider, ordersRepositoryProvider,
///   PriceSummary, OrderDeliveryAddress, routes.dart.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_top_bar.dart';
import '../../core/ui/price_summary.dart';
import '../../data/mock/mock_cart_repository.dart';
import '../../data/models/address_ui_model.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/firestore_addresses_repository.dart';
import '../../data/repositories/firestore_orders_repository.dart';
import '../../data/repositories/orders_repository.dart';
import '../../services/auth_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  AddressUiModel? _selectedAddress;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final cart = ref.watch(cartProvider);
    final authService = AuthService();
    final firebaseUser = authService.currentUser;

    // Si le client n'est pas connecté, afficher l'invitation à se connecter
    if (session.isGuest || firebaseUser == null) {
      return Scaffold(
        appBar: const AppTopBar(
          title: 'Finaliser la commande',
          showBackButton: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppDimens.space16),
                const Text(
                  'Connexion requise',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimens.space8),
                const Text(
                  'Veuillez vous connecter pour renseigner votre adresse de livraison et confirmer votre commande.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.space24),
                ElevatedButton(
                  onPressed: () {
                    // Mémorise la reprise de l'action après connexion
                    ref
                        .read(sessionProvider.notifier)
                        .setPendingAction(() {
                      context.push(AppRoutes.checkout);
                    });
                    context.push(AppRoutes.login);
                  },
                  child: const Text('Se connecter ou créer un compte'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Si le panier est vide (ex: retour arrière après commande)
    if (cart.isEmpty) {
      return Scaffold(
        appBar: const AppTopBar(
          title: 'Finaliser la commande',
          showBackButton: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppDimens.space16),
                const Text(
                  'Votre panier est vide',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimens.space16),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Découvrir les produits'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final addressesAsync = ref.watch(addressesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(
        title: 'Finaliser la commande',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. RÉCAPITULATIF DES ARTICLES ───────────────────────────────
            _buildSectionHeader(
              title: 'Articles commandés (${cart.totalItemCount})',
              icon: Icons.shopping_basket_outlined,
            ),
            const SizedBox(height: AppDimens.space8),
            _buildItemsCard(cart),
            const SizedBox(height: AppDimens.space20),

            // ── 2. ADRESSE DE LIVRAISON ─────────────────────────────────────
            _buildSectionHeader(
              title: 'Adresse de livraison',
              icon: Icons.location_on_outlined,
              action: TextButton(
                onPressed: () => _openAddressSelectionSheet(context),
                child: const Text('Changer'),
              ),
            ),
            const SizedBox(height: AppDimens.space8),
            addressesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimens.space16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _buildNoAddressCard(),
              data: (addresses) {
                if (addresses.isEmpty) {
                  return _buildNoAddressCard();
                }
                // Si aucune sélection manuelle, prendre l'adresse par défaut ou la 1ère
                _selectedAddress ??= addresses.firstWhere(
                  (a) => a.isDefault,
                  orElse: () => addresses.first,
                );

                return _buildSelectedAddressCard(_selectedAddress!);
              },
            ),
            const SizedBox(height: AppDimens.space20),

            // ── 3. MODE DE LIVRAISON ────────────────────────────────────────
            _buildSectionHeader(
              title: 'Mode de livraison',
              icon: Icons.local_shipping_outlined,
            ),
            const SizedBox(height: AppDimens.space8),
            _buildDeliveryModeCard(),
            const SizedBox(height: AppDimens.space20),

            // ── 4. MODE DE PAIEMENT ─────────────────────────────────────────
            _buildSectionHeader(
              title: 'Mode de paiement',
              icon: Icons.payments_outlined,
            ),
            const SizedBox(height: AppDimens.space8),
            _buildPaymentMethodCard(),
            const SizedBox(height: AppDimens.space20),

            // ── 5. RÉSUMÉ DU PRIX ───────────────────────────────────────────
            PriceSummary(
              subtotal: cart.subtotal,
              discountAmount: cart.discountAmount,
              promoCode: cart.appliedPromoCode,
              deliveryFee: cart.deliveryFee,
              total: cart.total,
            ),
            const SizedBox(height: AppDimens.space32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedAddress == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppDimens.space8),
                  child: Text(
                    '⚠️ Veuillez ajouter ou choisir une adresse de livraison.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: (_isSubmitting || _selectedAddress == null)
                    ? null
                    : () => _confirmAndSubmitOrder(context),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 20),
                          const SizedBox(width: AppDimens.space8),
                          Text(
                            'Confirmer la commande (${cart.total.toStringAsFixed(3)} DT)',
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    Widget? action,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppDimens.space8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ?action,
      ],
    );
  }

  Widget _buildItemsCard(CartState cart) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: cart.items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimens.space6),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radius8),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: AppColors.surfaceAlt,
                    child: item.imageUrl.isNotEmpty
                        ? Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.image_outlined,
                              color: AppColors.textHint,
                            ),
                          )
                        : const Icon(
                            Icons.image_outlined,
                            color: AppColors.textHint,
                          ),
                  ),
                ),
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (item.variantLabel != null)
                        Text(
                          'Variante : ${item.variantLabel}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      Text(
                        'Qté : ${item.quantity} × ${item.unitPrice.toStringAsFixed(3)} DT',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${item.lineTotal.toStringAsFixed(3)} DT',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedAddressCard(AddressUiModel address) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: AppDimens.space8),
              Expanded(
                child: Text(
                  address.recipientName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space8,
                    vertical: AppDimens.space2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppDimens.radius8),
                  ),
                  child: const Text(
                    'Par défaut',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.space6),
          Text(
            address.summary,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimens.space4),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: AppDimens.space4),
              Text(
                address.phone,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoAddressCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        children: [
          const Text(
            'Aucune adresse enregistrée.',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppDimens.space8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Ajouter une adresse'),
            onPressed: () => context.push(AppRoutes.addAddress),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryModeCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.space8),
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.speed_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppDimens.space12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Livraison standard',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppDimens.space2),
                Text(
                  'Expédition rapide à domicile sous 24 à 48 heures.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.space8),
            decoration: const BoxDecoration(
              color: AppColors.successSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments_rounded, color: AppColors.success, size: 24),
          ),
          const SizedBox(width: AppDimens.space12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiement à la livraison (Espèces)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppDimens.space2),
                Text(
                  'Réglez le montant exact en espèces auprès du livreur à la réception.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
        ],
      ),
    );
  }

  void _openAddressSelectionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radius24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final addressesAsync = ref.watch(addressesStreamProvider);
            return Padding(
              padding: const EdgeInsets.all(AppDimens.space20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Choisir une adresse',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  addressesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => const Text('Erreur de chargement'),
                    data: (addresses) {
                      return Column(
                        children: [
                          ...addresses.map((a) {
                            final isCurrent = _selectedAddress?.id == a.id;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                isCurrent
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isCurrent ? AppColors.primary : AppColors.textHint,
                              ),
                              title: Text(a.recipientName,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${a.summary}\n${a.phone}'),
                              onTap: () {
                                setState(() => _selectedAddress = a);
                                Navigator.of(ctx).pop();
                              },
                            );
                          }),
                          const SizedBox(height: AppDimens.space12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter une autre adresse'),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              context.push(AppRoutes.addAddress);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndSubmitOrder(BuildContext context) async {
    if (_isSubmitting || _selectedAddress == null) return;

    final cart = ref.read(cartProvider);
    final firebaseUser = AuthService().currentUser;
    final session = ref.read(sessionProvider);

    if (firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expirée, veuillez vous reconnecter.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    HapticFeedback.lightImpact();
    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(ordersRepositoryProvider);

      final addressSnapshot = OrderDeliveryAddress(
        recipientName: _selectedAddress!.recipientName,
        phone: _selectedAddress!.phone,
        addressLine: _selectedAddress!.addressLine,
        city: _selectedAddress!.city,
        zone: _selectedAddress!.zone,
        additionalInfo: _selectedAddress!.additionalInfo,
        deliveryInstructions: _selectedAddress!.deliveryInstructions,
      );

      final createdOrder = await repo.createOrder(
        userId: firebaseUser.uid,
        customerName: _selectedAddress!.recipientName.isNotEmpty
            ? _selectedAddress!.recipientName
            : (session.user?.fullName ?? 'Client Dokan'),
        customerPhone: _selectedAddress!.phone,
        cartItems: cart.items,
        deliveryAddress: addressSnapshot,
        promoCode: cart.appliedPromoCode,
        discountPercent: cart.discountPercent,
        deliveryFee: cart.deliveryFee,
      );

      // Le panier n'est vidé QU'APRÈS confirmation de Firestore
      await ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        router.go('${AppRoutes.orderConfirmation}/${createdOrder.id}');
      }
    } on ProductUnavailableException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur réseau lors de la commande : $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
