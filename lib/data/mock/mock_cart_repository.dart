/// ============================================================================
/// RÔLE DU FICHIER :
/// Implémentation simulée du panier d'achat (`MockCartRepository`), état immuable
/// (`CartState`) et gestionnaire d'état réactif (`CartNotifier`).
///
/// COMPORTEMENTS MÉTIER CLÉS :
/// 1) Maintient le panier d'achat en mémoire vive sans perte lors de la connexion.
/// 2) Calcule en continu le sous-total brut, les remises de code promo et la livraison.
/// 3) Code promo de démonstration : `Dokan10` (déduit -10% sur le sous-total).
/// 4) Frais de livraison forfaitaires de 7 DT, offerts dès 150 DT de commande.
/// 5) Mécanisme d'annulation (*Undo*) lors de la suppression d'une ligne d'article.
/// 6) Synchronisation automatique du badge numérique dans la barre d'onglets.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `data/mock/` (Source de Données Panier & Notifier).
///
/// RELATIONS ET DÉPENDANCES :
/// - Injecté par : `cartProvider`.
/// - Consommé par : `CartScreen`, `ProductDetailScreen`, `MainShell` (via `cartCountProvider`).
/// - Dépend de : `data/repositories/cart_repository.dart` et `data/models/cart_item_ui_model.dart`.
/// ============================================================================
// DONNÉES FICTIVES
// TODO API : Synchroniser le panier avec la session du panier persistant sur le serveur.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/navigation/main_shell.dart';
import '../models/cart_item_ui_model.dart';
import '../models/product_ui_model.dart';
import '../repositories/cart_repository.dart';

/// ÉTAT IMMUABLE DU PANIER (CartState)
class CartState {
  /// Liste des articles présents dans le panier.
  final List<CartItemUiModel> items;

  /// Code promotionnel actuellement actif (ex: 'Dokan10').
  final String? appliedPromoCode;

  /// Pourcentage de réduction appliqué (ex: 10.0 pour -10%).
  final double discountPercent;

  /// Indique si la vérification du code promo est en cours.
  final bool isApplyingPromo;

  /// Message d'erreur éventuel lié à la saisie du code promo.
  final String? promoError;

  const CartState({
    this.items = const [],
    this.appliedPromoCode,
    this.discountPercent = 0.0,
    this.isApplyingPromo = false,
    this.promoError,
  });

  /// Indique si le panier ne contient aucun article.
  bool get isEmpty => items.isEmpty;

  /// Indique si le panier contient au moins un article.
  bool get isNotEmpty => items.isNotEmpty;

  /// Nombre total d'unités physiques dans le panier (somme des quantités).
  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);

  /// Sous-total financier brut avant réductions.
  double get subtotal => items.fold(0.0, (sum, i) => sum + i.lineTotal);

  /// Montant déduit grâce au code promo.
  double get discountAmount => subtotal * (discountPercent / 100.0);

  /// Frais de port : 7,000 DT, ou Gratuits (0 DT) dès 150 DT de commande.
  double get deliveryFee {
    if (subtotal == 0) return 0.0;
    if (subtotal >= 150.0) return 0.0;
    return 7.000;
  }

  /// Montant total final TTC à régler.
  double get total {
    if (subtotal == 0) return 0.0;
    final discounted = subtotal - discountAmount;
    return (discounted + deliveryFee).clamp(0.0, double.infinity);
  }

  /// Copie immuable avec substitution ciblée.
  CartState copyWith({
    List<CartItemUiModel>? items,
    String? Function()? appliedPromoCode,
    double? discountPercent,
    bool? isApplyingPromo,
    String? Function()? promoError,
  }) {
    return CartState(
      items: items ?? this.items,
      appliedPromoCode: appliedPromoCode != null ? appliedPromoCode() : this.appliedPromoCode,
      discountPercent: discountPercent ?? this.discountPercent,
      isApplyingPromo: isApplyingPromo ?? this.isApplyingPromo,
      promoError: promoError != null ? promoError() : this.promoError,
    );
  }
}

/// Implémentation simulée du stockage du panier.
class MockCartRepository implements CartRepository {
  final List<CartItemUiModel> _items = [];

  @override
  Future<List<CartItemUiModel>> getCartItems() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_items);
  }

  @override
  Future<void> addItem(CartItemUiModel item) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      final existing = _items[index];
      final newQuantity = (existing.quantity + item.quantity).clamp(1, 10);
      _items[index] = existing.copyWith(quantity: newQuantity);
    } else {
      _items.add(item);
    }
  }

  @override
  Future<void> updateQuantity(String itemId, int quantity) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity.clamp(1, 10));
    }
  }

  @override
  Future<void> removeItem(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _items.removeWhere((i) => i.id == itemId);
  }

  @override
  Future<void> clearCart() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _items.clear();
  }
}

/// Provider d'injection du repository panier.
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return MockCartRepository();
});

/// GESTIONNAIRE D'OPÉRATIONS DU PANIER (CartNotifier)
class CartNotifier extends StateNotifier<CartState> {
  final Ref _ref;
  final CartRepository _repo;

  CartNotifier(this._ref, this._repo) : super(const CartState());

  /// Met à jour la pastille rouge sur l'icône du panier dans la barre de navigation.
  void _updateBadge() {
    _ref.read(cartCountProvider.notifier).state = state.totalItemCount;
  }

  /// SCÉNARIO MÉTIER : AJOUT D'UN PRODUIT DANS LE PANIER
  /// 1) Génère un identifiant composite combinant l'ID du produit et la variante choisie.
  /// 2) Si l'article existe déjà, incrémente sa quantité (plafonnée à 10 unités max).
  /// 3) Si l'article est nouveau, l'ajoute en tête de panier.
  /// 4) Recalcule immédiatement le sous-total et met à jour le badge de la barre d'onglets.
  Future<void> addProduct(
    ProductUiModel product, {
    int quantity = 1,
    String? variant,
  }) async {
    final compositeId = '${product.id}_${variant ?? ''}';
    final currentItems = List<CartItemUiModel>.from(state.items);
    final existingIndex = currentItems.indexWhere((i) => i.id == compositeId);

    if (existingIndex >= 0) {
      final existing = currentItems[existingIndex];
      final newQty = (existing.quantity + quantity).clamp(1, 10);
      currentItems[existingIndex] = existing.copyWith(quantity: newQty);
    } else {
      currentItems.add(
        CartItemUiModel(
          id: compositeId,
          productId: product.id,
          name: product.name,
          imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
          unitPrice: product.price,
          quantity: quantity.clamp(1, 10),
          variantLabel: variant,
          availability: product.availability,
        ),
      );
    }

    state = state.copyWith(items: currentItems);
    _updateBadge();
    await _repo.addItem(currentItems.firstWhere((i) => i.id == compositeId));
  }

  /// Modifie la quantité d'une ligne d'article existante.
  Future<void> updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity < 1) return;

    final currentItems = List<CartItemUiModel>.from(state.items);
    final index = currentItems.indexWhere((i) => i.id == itemId);

    if (index >= 0) {
      currentItems[index] = currentItems[index].copyWith(
        quantity: newQuantity.clamp(1, 10),
      );
      state = state.copyWith(items: currentItems);
      _updateBadge();
      await _repo.updateQuantity(itemId, newQuantity);
    }
  }

  /// Retire un article du panier et le renvoie pour alimenter l'action d'annulation (Undo).
  CartItemUiModel? removeItem(String itemId) {
    final currentItems = List<CartItemUiModel>.from(state.items);
    final index = currentItems.indexWhere((i) => i.id == itemId);

    if (index >= 0) {
      final removed = currentItems.removeAt(index);
      state = state.copyWith(items: currentItems);
      _updateBadge();
      _repo.removeItem(itemId);
      return removed;
    }
    return null;
  }

  /// SCÉNARIO MÉTIER : RESTAURATION D'UN ARTICLE (ACTION UNDO)
  /// Si l'utilisateur clique sur « Annuler » dans le SnackBar suite à une suppression,
  /// cette méthode réinsère l'article exactement à son index d'origine dans la liste.
  void restoreItem(CartItemUiModel item, int index) {
    final currentItems = List<CartItemUiModel>.from(state.items);
    final insertIndex = index.clamp(0, currentItems.length);
    currentItems.insert(insertIndex, item);

    state = state.copyWith(items: currentItems);
    _updateBadge();
    _repo.addItem(item);
  }

  /// SCÉNARIO MÉTIER : APPLICATION D'UN CODE PROMOTIONNEL
  /// - Code valide : `Dokan10` accorde 10 % de réduction immédiate.
  /// - Code erroné : Affiche le message « Code promo invalide ou expiré ».
  
  Future<bool> applyPromoCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return false;

    state = state.copyWith(
      isApplyingPromo: true,
      promoError: () => null,
    );

    // Latence artificielle de vérification (600 ms)
    await Future.delayed(const Duration(milliseconds: 600));

    if (trimmed == 'Dokan10') {
      state = state.copyWith(
        appliedPromoCode: () => 'Dokan10',
        discountPercent: 10.0,
        isApplyingPromo: false,
        promoError: () => null,
      );
      return true;
    } else {
      state = state.copyWith(
        isApplyingPromo: false,
        promoError: () => 'Code promo invalide ou expiré.',
      );
      return false;
    }
  }

  /// Supprime la remise promotionnelle en cours.
  void removePromoCode() {
    state = state.copyWith(
      appliedPromoCode: () => null,
      discountPercent: 0.0,
      promoError: () => null,
    );
  }

  /// Réinitialise l'ensemble du panier.
  Future<void> clearCart() async {
    state = const CartState();
    _updateBadge();
    await _repo.clearCart();
  }
}

/// Provider global du panier accessible via `ref.watch(cartProvider)`.
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final repo = ref.watch(cartRepositoryProvider);
  return CartNotifier(ref, repo);
});
