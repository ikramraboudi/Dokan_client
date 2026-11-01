/// ============================================================================
/// RÔLE DU FICHIER :
/// Écran « Mes adresses » (liste, sélection, modification, suppression).
/// Utilisé depuis le Profil et depuis le passage de commande (Checkout).
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche feature/address/ (Interface Utilisateur / Adresses).
///
/// RELATIONS ET DÉPENDANCES :
/// - Déclenché par : ProfileScreen ou CheckoutScreen via AppRoutes.addresses.
/// - Dépend de : addressesStreamProvider, addressesRepositoryProvider,
///   address_ui_model.dart, app_colors.dart, app_dimens.dart.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_top_bar.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/error_state.dart';
import '../../core/ui/loading_state.dart';
import '../../data/models/address_ui_model.dart';
import '../../data/repositories/firestore_addresses_repository.dart';
import '../../services/auth_service.dart';

class AddressesScreen extends ConsumerWidget {
  /// Si true, l'écran permet de sélectionner une adresse et de la renvoyer par pop().
  final bool selectMode;

  const AddressesScreen({
    super.key,
    this.selectMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppTopBar(
          title: selectMode ? 'Choisir une adresse' : 'Mes adresses',
          showBackButton: true,
        ),
        body: const Center(
          child: Text('Veuillez vous connecter pour gérer vos adresses.'),
        ),
      );
    }

    final addressesAsync = ref.watch(addressesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: selectMode ? 'Choisir une adresse' : 'Mes adresses',
        showBackButton: true,
        actions: [
          IconButton(
            tooltip: 'Ajouter une adresse',
            icon: const Icon(Icons.add_location_alt_outlined, color: AppColors.primary),
            onPressed: () => context.push(AppRoutes.addAddress),
          ),
        ],
      ),
      body: addressesAsync.when(
        loading: () => const LoadingState(message: 'Chargement de vos adresses...'),
        error: (err, _) => ErrorState(
          message: 'Impossible de charger vos adresses.',
          onRetry: () => ref.refresh(addressesStreamProvider),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return EmptyState(
              icon: Icons.location_off_outlined,
              title: 'Aucune adresse enregistrée',
              message: 'Ajoutez une adresse de livraison pour pouvoir passer commande en toute simplicité.',
              buttonText: 'Ajouter une adresse',
              onAction: () => context.push(AppRoutes.addAddress),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimens.space16),
            itemCount: addresses.length,
            separatorBuilder: (ctx, index) => const SizedBox(height: AppDimens.space12),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _AddressCard(
                address: address,
                userId: user.uid,
                selectMode: selectMode,
                onSelect: selectMode ? () => Navigator.of(context).pop(address) : null,
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter une nouvelle adresse'),
            onPressed: () => context.push(AppRoutes.addAddress),
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends ConsumerWidget {
  final AddressUiModel address;
  final String userId;
  final bool selectMode;
  final VoidCallback? onSelect;

  const _AddressCard({
    required this.address,
    required this.userId,
    required this.selectMode,
    this.onSelect,
  });

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette adresse ?'),
        content: Text(
          'Voulez-vous vraiment supprimer l\'adresse "${address.summary}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnDark,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(addressesRepositoryProvider)
                  .deleteAddress(userId, address.id);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(addressesRepositoryProvider);

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(AppDimens.radius16),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.space16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radius16),
          border: Border.all(
            color: address.isDefault ? AppColors.primary : AppColors.border,
            width: address.isDefault ? 1.8 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  address.isDefault
                      ? Icons.home_rounded
                      : Icons.location_on_outlined,
                  color: address.isDefault
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: AppDimens.space8),
                Expanded(
                  child: Text(
                    address.recipientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space8,
                      vertical: AppDimens.space4,
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
            const SizedBox(height: AppDimens.space8),
            Text(
              address.summary,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppDimens.space4),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: AppDimens.space4),
                Text(
                  address.phone,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (address.deliveryInstructions != null &&
                address.deliveryInstructions!.isNotEmpty) ...[
              const SizedBox(height: AppDimens.space6),
              Text(
                'Note : ${address.deliveryInstructions}',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const Divider(height: AppDimens.space20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!address.isDefault)
                  TextButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Définir par défaut', style: TextStyle(fontSize: 12)),
                    onPressed: () => repo.setDefaultAddress(userId, address.id),
                  ),
                IconButton(
                  tooltip: 'Modifier',
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                  onPressed: () => context.push('${AppRoutes.editAddress}/${address.id}'),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
