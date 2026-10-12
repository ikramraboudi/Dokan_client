/// ============================================================================
/// RÔLE DU FICHIER :
/// Interface abstraite définissant le contrat technique du panier d'achat.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche `data/repositories/` (Contrats Abstraits).
///
/// RELATIONS ET DÉPENDANCES :
/// - Implémenté par : `lib/data/mock/mock_cart_repository.dart`.
/// - Dépend de : `data/models/cart_item_ui_model.dart`.
/// ============================================================================
library;

import '../models/cart_item_ui_model.dart';

/// Contrat de gestion des articles du panier d'achat.
abstract class CartRepository {
  /// Récupère la liste de toutes les lignes d'articles actuellement dans le panier.
  Future<List<CartItemUiModel>> getCartItems();

  /// Ajoute une nouvelle ligne d'article dans le panier.
  Future<void> addItem(CartItemUiModel item);

  /// Met à jour la quantité d'un article existant.
  Future<void> updateQuantity(String itemId, int quantity);

  /// Supprime définitivement un article du panier.
  Future<void> removeItem(String itemId);

  /// Vide l'ensemble des articles du panier.
  Future<void> clearCart();
}
