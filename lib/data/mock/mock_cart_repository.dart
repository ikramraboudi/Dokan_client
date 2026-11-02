/// ============================================================================
/// RÔLE DU FICHIER : Gestionnaire de panier en mémoire (CartNotifier Riverpod) avec recalcul automatique des totaux et support des coupons Firestore.
/// INTERAGIT AVEC : cartProvider, CartScreen, CheckoutScreen, PriceSummary.
/// POUR L'ORAL : « Le CartNotifier gère l'état du panier en mémoire à 60 FPS, recalcule le total à chaque modification et valide les coupons Firestore en temps réel. »
/// ============================================================================
/// ============================================================================
/// RÔLE DU FICHIER :
/// Implémentation simulée du panier d'achat (`MockCartRepository`), état immuable
/// (`CartState`) et gestionnaire d'état réactif (`CartNotifier`).
///
/// COMPORTEMENTS MÉTIER CLÉS :
/// 1) Maintient le panier d'achat en mémoire vive sans perte lors de la connexion.
/// 2) Calcule en continu le sous-total brut et la livraison.
/// 3) Frais de livraison forfaitaires de 7 DT, offerts dès 150 DT de commande.
/// 4) Mécanisme d'annulation (*Undo*) lors de la suppression d'une ligne d'article.
/// 5) Synchronisation automatique du badge numérique dans la barre d'onglets.
/// 6) Validation et application de codes promotionnels Firestore.
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
// TODO Firebase : à migrer (panier persistant Firestore)
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/navigation/main_shell.dart';
import '../models/cart_item_ui_model.dart';
import '../models/coupon_model.dart';
import '../models/product_ui_model.dart';
import '../repositories/cart_repository.dart';

/// ÉTAT IMMUABLE DU PANIER (CartState)
class CartState {
  /// Liste des articles présents dans le panier.
  final List<CartItemUiModel> items;

  /// Code promotionnel actuellement appliqué (null si aucun).
  final String? appliedPromoCode;

  /// Montant de la réduction appliquée par le coupon.
  final double discountAmount;

  /// Indique si une validation de code promo est en cours.
  final bool isApplyingPromo;

  /// Message d'erreur si la validation du code a échoué (null si OK).
  final String? promoError;

  const CartState({
    this.items = const [],
    this.appliedPromoCode,
    this.discountAmount = 0.0,
    this.isApplyingPromo = false,
    this.promoError,
  });

  /// Indique si le panier ne contient aucun article.
  bool get isEmpty => items.isEmpty;

  /// Indique si le panier contient au moins un article.
  bool get isNotEmpty => items.isNotEmpty;

  /// Nombre total d'unités physiques dans le panier (somme des quantités).
  int get totalItemCount => items.fold(0, (acc, i) => acc + i.quantity);

  /// Sous-total financier brut avant réductions.
  double get subtotal => items.fold(0.0, (acc, i) => acc + i.lineTotal);

  /// Frais de port : 7,000 DT, ou Gratuits (0 DT) dès 150 DT de commande.
  double get deliveryFee {
    if (subtotal == 0) return 0.0;
    if (subtotal >= 150.0) return 0.0;
    return 7.000;
  }

  /// Montant total final TTC à régler (sous-total - remise + frais de livraison).
  double get total {
    if (subtotal == 0) return 0.0;
    return (subtotal - discountAmount + deliveryFee).clamp(0.0, double.infinity);
  }

  /// Copie immuable avec substitution ciblée.
  CartState copyWith({
    List<CartItemUiModel>? items,
    String? appliedPromoCode,
    double? discountAmount,
    bool? isApplyingPromo,
    String? promoError,
    bool clearPromo = false,
    bool clearPromoError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      appliedPromoCode: clearPromo ? null : (appliedPromoCode ?? this.appliedPromoCode),
      discountAmount: clearPromo ? 0.0 : (discountAmount ?? this.discountAmount),
      isApplyingPromo: isApplyingPromo ?? this.isApplyingPromo,
      promoError: clearPromoError ? null : (promoError ?? this.promoError),
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
  /// 5) Retire automatiquement le code promo si le sous-total change (pour recalcul).
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

    // Retirer le code promo si le panier change (le montant a changé)
    state = state.copyWith(items: currentItems, clearPromo: true, clearPromoError: true);
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
      // Retirer le code promo si la quantité change (le montant a changé)
      state = state.copyWith(items: currentItems, clearPromo: true, clearPromoError: true);
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
      // Retirer le code promo si un article est supprimé
      state = state.copyWith(items: currentItems, clearPromo: true, clearPromoError: true);
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

    state = state.copyWith(items: currentItems, clearPromo: true, clearPromoError: true);
    _updateBadge();
    _repo.addItem(item);
  }

  /// Réinitialise l'ensemble du panier.
  Future<void> clearCart() async {
    state = const CartState();
    _updateBadge();
    await _repo.clearCart();
  }

  /// SCÉNARIO MÉTIER : APPLICATION D'UN CODE PROMOTIONNEL FIRESTORE
  /// 1) Nettoie le code saisi et interroge Firestore.
  /// 2) Valide toutes les règles métier (dates, montant min, limites d'usage, etc.).
  /// 3) Calcule la réduction et met à jour l'état du panier.
  Future<void> applyPromoCode(String code, {String? userId}) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return;

    // Indiquer le chargement
    state = state.copyWith(isApplyingPromo: true, clearPromoError: true);

    try {
      // Requête Firestore pour trouver le coupon par son champ 'code'
      final querySnapshot = await FirebaseFirestore.instance
          .collection('coupons')
          .where('code', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        state = state.copyWith(
          isApplyingPromo: false,
          promoError: 'Code promo invalide ou désactivé.',
        );
        return;
      }

      final coupon = CouponModel.fromFirestore(querySnapshot.docs.first);

      // Compter les commandes précédentes si nécessaire
      int userPreviousOrdersCount = 0;
      if (coupon.isFirstOrderOnly && userId != null && userId.isNotEmpty) {
        final ordersCount = await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .count()
            .get();
        userPreviousOrdersCount = ordersCount.count ?? 0;
      }

      // Validation métier complète
      final error = coupon.validate(
        subtotal: state.subtotal,
        userId: userId,
        userPreviousOrdersCount: userPreviousOrdersCount,
      );

      if (error != null) {
        state = state.copyWith(
          isApplyingPromo: false,
          promoError: error,
        );
        return;
      }

      // Calcul de la réduction
      final discount = coupon.calculateDiscount(state.subtotal);

      state = state.copyWith(
        isApplyingPromo: false,
        appliedPromoCode: cleanCode,
        discountAmount: discount,
        clearPromoError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isApplyingPromo: false,
        promoError: 'Erreur de connexion. Réessayez.',
      );
    }
  }

  /// Retire le code promo actuellement appliqué.
  void removePromoCode() {
    state = state.copyWith(clearPromo: true, clearPromoError: true);
  }
}

/// Provider global du panier accessible via `ref.watch(cartProvider)`.
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final repo = ref.watch(cartRepositoryProvider);
  return CartNotifier(ref, repo);
});
