import '../models/cart_item_ui_model.dart';

/// ============================================================
///  SOUKNA — INTERFACE DU REPOSITORY PANIER
/// ============================================================
abstract class CartRepository {
  /// Récupère la liste des articles du panier
  Future<List<CartItemUiModel>> getCartItems();

  /// Ajoute un article au panier
  Future<void> addItem(CartItemUiModel item);

  /// Modifie la quantité d'un article
  Future<void> updateQuantity(String itemId, int quantity);

  /// Retire un article du panier
  Future<void> removeItem(String itemId);

  /// Vide le panier
  Future<void> clearCart();
}
