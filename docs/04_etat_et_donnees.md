# 04 — Gestion d'État (Riverpod) et Modèles de Données

Ce document décrit en détail la gestion d'état réactive avec **Riverpod**, la structure des modèles de données et la manière de faire évoluer le projet vers une véritable API backend.

---

## 1. La Gestion d'État avec Riverpod

**Riverpod** est un gestionnaire d'état déclaratif et réactif pour Flutter. Contrairement au `setState` classique (qui ne fonctionne qu'à l'intérieur d'un seul widget) ou à l'ancien package `provider` (qui dépendait du `BuildContext`), Riverpod permet de déclarer des états accessibles de manière globale et sécurisée au moment de la compilation.

### Inventaire des Providers de l'application :

| Provider | Fichier source | Type Riverpod | Rôle et données contenues | Qui l'écoute ? | Qui le modifie ? |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `sessionProvider` | `lib/core/session/session_provider.dart` | `StateNotifierProvider` | Contient `SessionState` (`user`, `isGuest`, `pendingAction`). | Tous les écrans pour adapter la vue visiteur/client. | `LoginScreen`, `RegisterScreen`, `ProfileScreen` (déconnexion). |
| `cartProvider` | `lib/data/mock/mock_cart_repository.dart` | `StateNotifierProvider` | Contient `CartState` (liste d'articles, promo, totaux). | `CartScreen`, `MainShell` (via cartCountProvider). | `ProductDetailScreen` (ajout), `CartScreen` (quantités, suppression, code promo). |
| `cartCountProvider` | `lib/core/navigation/main_shell.dart` | `StateProvider<int>` | Nombre total d'articles dans le panier. | Le badge rouge de la barre de navigation. | Synchronisé automatiquement par les mutations de `cartProvider`. |
| `favoritesProvider` | `lib/data/mock/mock_favorites_repository.dart` | `StateNotifierProvider` | Liste des articles favoris du client. | `FavoritesScreen`, `HomeScreen`, `CatalogScreen`, `ProductCard`. | Bouton cœur sur n'importe quel écran. |
| `homeCategoriesProvider` | `lib/feature/home/home_screen.dart` | `FutureProvider` | Liste asynchrone des catégories de l'accueil. | Section catégories de l'accueil. | `RefreshIndicator` de l'accueil (`ref.invalidate`). |
| `newProductsProvider` | `lib/feature/home/home_screen.dart` | `FutureProvider` | Liste des nouveautés. | Première section de l'accueil. | `RefreshIndicator` (`ref.invalidate`). |
| `discountedProductsProvider` | `lib/feature/home/home_screen.dart` | `FutureProvider` | Liste des promotions. | Deuxième section de l'accueil. | `RefreshIndicator` (`ref.invalidate`). |
| `popularProductsProvider` | `lib/feature/home/home_screen.dart` | `FutureProvider` | Liste des produits populaires. | Troisième section de l'accueil. | `RefreshIndicator` (`ref.invalidate`). |
| `productDetailProvider(id)` | `lib/feature/product/product_detail_screen.dart` | `FutureProvider.family` | Données complètes d'un produit par son identifiant. | `ProductDetailScreen`. | Chargement automatique à l'ouverture de l'écran. |
| `recentSearchesProvider` | `lib/feature/catalog/search_screen.dart` | `StateNotifierProvider` | Historique des 6 dernières recherches textuelles. | `SearchScreen`. | Formulaire de recherche et bouton « Effacer tout ». |

---

## 2. Modèles de Données (UI Models)

Dans une application Flutter propre, les données manipulées par les widgets sont appelées des **UiModels**. Ce sont des classes Dart pures, immuables (*immutable*).

### Pourquoi des modèles immuables avec `copyWith` ?
En programmation fonctionnelle et réactive, on ne modifie jamais directement les propriétés d'un objet existant (ex: `cart.total = 100` est interdit). Au lieu de cela, on crée une **nouvelle copie** de l'objet avec uniquement les valeurs modifiées grâce à une méthode appelée `copyWith` :

```dart
// Exemple dans CartNotifier :
state = state.copyWith(
  items: updatedItems,
  appliedPromoCode: 'Dokan10',
);
```
Grâce à ce mécanisme, Riverpod compare l'ancienne et la nouvelle référence mémoire : s'il détecte un nouvel objet, il reconstruit uniquement les widgets concernés.

### Revue des champs principaux de `ProductUiModel` :

* `id` (`String`) : Identifiant unique de l'article (ex: `'prod_1'`).
* `name` (`String`) : Désignation commerciale de l'article.
* `description` (`String`) : Texte descriptif complet.
* `price` (`double`) : Prix de vente actuel.
* `oldPrice` (`double?`, optionnel) : Prix barré d'origine. Nul si l'article n'est pas en promotion.
* `imageUrls` (`List<String>`) : Liste des URLs d'images pour alimenter la galerie.
* `categoryName` (`String`) : Nom de la catégorie associée.
* `availability` (`ProductAvailability`) : Énumération (`inStock`, `limitedStock`, `outOfStock`).
* `rating` (`double?`, optionnel) : Note moyenne sur 5 étoiles. Nul si le produit n'a pas encore été évalué.
* `reviewCount` (`int`) : Nombre d'avis déposés par les acheteurs.
* `variants` (`List<String>?`, optionnel) : Choix possibles pour le produit (ex: `['S', 'M', 'L']` ou `['Noir', 'Blanc']`). Nul si l'article est unique.

---

## 3. Le Pattern Repository et la transition vers une vraie API

### Pourquoi avoir créé des Interfaces et des Mocks ?
Le projet utilise le **Repository Pattern** :
1. Une classe abstraite définit le contrat technique (ex: `abstract class CatalogRepository`).
2. Une classe concrète implémente ce contrat avec de fausses données (ex: `MockCatalogRepository`).
3. L'application consomme l'interface sans jamais savoir d'où viennent les données.

### Ce qu'il faudra faire le jour où l'API réelle sera prête :

Lorsque l'équipe backend aura déployé l'API REST ou GraphQL, **aucun écran de l'application n'aura besoin d'être touché**. Il suffira simplement de :

1. **Créer un client HTTP** (ex: dans `lib/data/api/api_client.dart` avec le package `dio` ou `http`) pour gérer les en-têtes d'authentification (`Bearer token`) et les requêtes HTTP.
2. **Créer les implémentations réelles des dépôts** :
   * Créer `lib/data/repositories/api_catalog_repository.dart` qui implémente `CatalogRepository`.
   * Créer `lib/data/repositories/api_auth_repository.dart` qui implémente `AuthRepository`.
   * Créer `lib/data/repositories/api_cart_repository.dart` qui implémente `CartRepository`.
   * Créer `lib/data/repositories/api_favorites_repository.dart` qui implémente `FavoritesRepository`.
3. **Mettre à jour l'injection de dépendances** :
   Dans le fichier de chaque provider, remplacer l'instanciation du mock par la classe d'API :
   ```dart
   // AVANT (Mock) :
   final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
     return MockCatalogRepository();
   });

   // APRÈS (Vraie API) :
   final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
     final apiClient = ref.watch(apiClientProvider);
     return ApiCatalogRepository(apiClient);
   });
   ```

---

## 4. Données Fictives et Outils de Démonstration

L'application intègre plusieurs outils pratiques pour tester et démontrer tous les cas d'usage sans connexion réseau réelle :

### 1. Comptes de test d'authentification
* **Compte Valide (Succès)** :
  * E-mail : `demo@Dokan.com`
  * Mot de passe : `Demo1234`
  * Comportement : Ouvre une session client avec le nom "Amine Ben Salem".
* **Compte d'échec (Erreur)** :
  * E-mail : `fail@Dokan.com`
  * Comportement : Simule un rejet de connexion avec message d'erreur d'identifiants incorrects.

### 2. Code Promotionnel dans le panier
* **Code valide** : `Dokan10`
  * Effet : Déduit immédiatement **10 %** du montant du sous-total.
* **Tout autre code** (ex: `TEST`) :
  * Effet : Affiche le message d'erreur « *Code promotionnel invalide ou expiré.* ».

### 3. Mots-clés spéciaux dans le moteur de recherche
* Tapez **`#error`** dans la barre de recherche : Déclenche volontairement une exception réseau pour vérifier le bon affichage de l'écran d'erreur (`ErrorState`) et le fonctionnement du bouton « Réessayer ».
* Tapez **`#empty`** dans la barre de recherche : Renvoie une liste vide pour vérifier l'affichage de l'écran de résultat nul (`EmptyState`).

### 4. Source des images
Toutes les images proviennent du service fiable **Picsum Photos** avec des graines (*seeds*) d'URL stables (ex: `https://picsum.photos/seed/Dokan_prod_1/600/600`). Chaque image possède une gestion d'attente fluide (`loadingBuilder`) et une image de secours en icône vectorielle si le smartphone est hors-ligne (`errorBuilder`).
