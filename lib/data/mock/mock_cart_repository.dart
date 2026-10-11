import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/navigation/main_shell.dart';
import '../models/cart_item_ui_model.dart';
import '../models/product_ui_model.dart';
import '../repositories/cart_repository.dart';

/// ============================================================
///  SOUKNA — ÉTAT GLOBAL DU PANIER
///  // TODO API : à confirmer côté serveur sur totaux, codes promo et disponibilités.
/// ============================================================
class CartState {
  final List<CartItemUiModel> items;
  final String? appliedPromoCode;
  final double discountPercent;
  final bool isApplyingPromo;
  final String? promoError;

  const CartState({
    this.items = const [],
    this.appliedPromoCode,
    this.discountPercent = 0.0,
    this.isApplyingPromo = false,
    this.promoError,
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);

  /// Sous-total brut
  double get subtotal => items.fold(0.0, (sum, i) => sum + i.lineTotal);

  /// Montant de la réduction
  double get discountAmount => subtotal * (discountPercent / 100.0);

  /// Frais de livraison estimés (7 DT, gratuit à partir de 150 DT)
  double get deliveryFee {
    if (subtotal == 0) return 0.0;
    if (subtotal >= 150.0) return 0.0;
    return 7.000;
  }

  /// Total final calculé
  double get total {
    if (subtotal == 0) return 0.0;
    final discounted = subtotal - discountAmount;
    return (discounted + deliveryFee).clamp(0.0, double.infinity);
  }

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

/// ============================================================
///  SOUKNA — MOCK REPOSITORY PANIER
/// ============================================================
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

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return MockCartRepository();
});

/// StateNotifier pour gérer les opérations du panier en temps réel
class CartNotifier extends StateNotifier<CartState> {
  final Ref _ref;
  final CartRepository _repo;

  CartNotifier(this._ref, this._repo) : super(const CartState());

  /// Met à jour le badge du shell de navigation
  void _updateBadge() {
    _ref.read(cartCountProvider.notifier).state = state.totalItemCount;
  }

  /// Ajoute un produit au panier
  /// // DÉCISION À CONFIRMER : conservation du panier invité sans perte lors de la connexion
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

  /// Met à jour la quantité d'un article
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

  /// Retire un article du panier et le retourne pour permettre l'annulation
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

  /// Restaure un article retiré (action Annuler / Undo du SnackBar)
  void restoreItem(CartItemUiModel item, int index) {
    final currentItems = List<CartItemUiModel>.from(state.items);
    final insertIndex = index.clamp(0, currentItems.length);
    currentItems.insert(insertIndex, item);

    state = state.copyWith(items: currentItems);
    _updateBadge();
    _repo.addItem(item);
  }

  /// Application d'un code promotionnel
  /// Code de démonstration : SOUKNA10 (-10 %)
  /// // TODO API : validation serveur
  Future<bool> applyPromoCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return false;

    state = state.copyWith(
      isApplyingPromo: true,
      promoError: () => null,
    );

    await Future.delayed(const Duration(milliseconds: 600));

    if (trimmed == 'SOUKNA10') {
      state = state.copyWith(
        appliedPromoCode: () => 'SOUKNA10',
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

  /// Suppression du code promotionnel actif
  void removePromoCode() {
    state = state.copyWith(
      appliedPromoCode: () => null,
      discountPercent: 0.0,
      promoError: () => null,
    );
  }

  /// Vider le panier
  Future<void> clearCart() async {
    state = const CartState();
    _updateBadge();
    await _repo.clearCart();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final repo = ref.watch(cartRepositoryProvider);
  return CartNotifier(ref, repo);
});
