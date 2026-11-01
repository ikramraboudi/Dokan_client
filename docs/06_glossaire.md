# 06 — Glossaire Technique Complet

Ce glossaire définit simplement tous les termes techniques rencontrés dans le projet Dokan. Chaque définition est accompagnée d'un exemple concret tiré directement de notre code.

---

## 1. Flutter & Arbre de Widgets

### Widget
* **Définition** : Le bloc de construction élémentaire de toute interface Flutter. Tout élément visuel (bouton, texte), de mise en page (colonne, marge) ou structurel est un widget.
* **Exemple dans le code** : `ProductCard` dans [`lib/core/ui/product_card.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/core/ui/product_card.dart).

### StatelessWidget
* **Définition** : Un widget immuable qui ne possède pas d'état interne susceptible de changer au cours du temps. Il se dessine une fois à partir des paramètres qu'il reçoit.
* **Exemple dans le code** : `PriceSummary` dans [`lib/core/ui/price_summary.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/core/ui/price_summary.dart).

### StatefulWidget & State
* **Définition** : Un widget dynamique associé à un objet `State`. Il peut stocker des variables locales et redessiner son interface quand ces variables changent via `setState()`.
* **Exemple dans le code** : `_LoginScreenState` dans [`lib/feature/auth/login_screen.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/feature/auth/login_screen.dart) qui mémorise si le mot de passe est masqué ou visible.

### build & BuildContext
* **Définition** : La méthode `build` décrit la hiérarchie visuelle du widget. Le `BuildContext` représente l'emplacement exact de ce widget dans l'arbre global de l'application (permet d'accéder au thème, aux dimensions d'écran, etc.).
* **Exemple dans le code** : `Widget build(BuildContext context)` présent dans tous les écrans.

### Scaffold
* **Définition** : La structure visuelle de base d'un écran respectant les normes Material Design. Il fournit des emplacements prédéfinis pour la barre supérieure (`appBar`), le contenu principal (`body`), et la barre de navigation inférieure (`bottomNavigationBar`).
* **Exemple dans le code** : Le widget racine retourné par `HomeScreen.build()`.

### Column & Row
* **Définition** : Widgets de disposition organisant leurs enfants de manière séquentielle : verticale pour `Column` et horizontale pour `Row`.
* **Exemple dans le code** : Les lignes de prix dans [`lib/core/ui/price_summary.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/core/ui/price_summary.dart).

### SingleChildScrollView
* **Définition** : Un conteneur qui rend un enfant unique défilable s'il dépasse la hauteur de l'écran.
* **Exemple dans le code** : Utilisé dans [`lib/feature/home/home_screen.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/feature/home/home_screen.dart) pour permettre le défilement vertical complet de l'accueil.

### ListView & GridView
* **Définition** : Conteneurs à défilement optimisés pour de multiples éléments. Le constructeur `.builder` recycle la mémoire en ne créant que les éléments actuellement visibles à l'écran (*lazy loading*).
* **Exemple dans le code** : `ListView.separated` dans [`lib/feature/catalog/categories_screen.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/feature/catalog/categories_screen.dart).

### PageView
* **Définition** : Un widget permettant de faire défiler des pages écran par écran d'un glissement de doigt, horizontalement ou verticalement.
* **Exemple dans le code** : Le carrousel d'images de la fiche produit dans [`lib/feature/product/product_detail_screen.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/feature/product/product_detail_screen.dart).

### Slivers & CustomScrollView
* **Définition** : Un `Sliver` est une portion élémentaire d'une zone défilable optimisée pour les performances. `CustomScrollView` permet de combiner plusieurs slivers (ex: une grille et une liste) dans un défilement unique et fluide.
* **Exemple dans le code** : `ProductGrid` dans [`lib/core/ui/product_grid.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/core/ui/product_grid.dart) qui associe un `SliverGrid` et un `SliverToBoxAdapter`.

### Expanded & SizedBox
* **Définition** : `Expanded` force un enfant à occuper tout l'espace disponible restant dans une `Row` ou `Column`. `SizedBox` force des dimensions fixes (largeur ou hauteur) ou crée un espace vide d'écartement.
* **Exemple dans le code** : `SizedBox(height: AppDimens.space16)` pour créer un espacement vertical constant.

### shrinkWrap
* **Définition** : Propriété booléenne ordonnant à un `ListView` ou `GridView` de limiter sa taille à la hauteur exacte de son contenu plutôt que de tenter de s'étendre à l'infini.
* **Exemple dans le code** : Utilisé sur les listes imbriquées pour éviter les erreurs de contraintes illimitées.

---

## 2. Gestion d'État avec Riverpod

### Provider
* **Définition** : L'objet fondamental de Riverpod qui encapsule un morceau d'état et le rend accessible en lecture et en écoute dans toute l'application.
* **Exemple dans le code** : `catalogRepositoryProvider` dans [`lib/data/mock/mock_catalog_repository.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/data/mock/mock_catalog_repository.dart).

### ConsumerWidget & WidgetRef
* **Définition** : La version Riverpod d'un `StatelessWidget`. Sa méthode `build` reçoit un paramètre supplémentaire `WidgetRef ref` permettant d'interagir avec les providers.
* **Exemple dans le code** : `CategoriesScreen` dans [`lib/feature/catalog/categories_screen.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/feature/catalog/categories_screen.dart).

### ref.watch vs ref.read
* **Définition** :
  * `ref.watch(provider)` : Souscrit à l'état du provider. Si l'état change, le widget se redessine automatiquement. À utiliser dans les méthodes `build`.
  * `ref.read(provider)` : Lit la valeur instantanée ou accède aux méthodes du provider sans souscription. À utiliser dans les callbacks d'actions (comme `onPressed`).
* **Exemple dans le code** : `ref.watch(cartProvider)` pour afficher les totaux du panier, et `ref.read(cartProvider.notifier).removeItem(...)` lors d'un clic de suppression.

### StateNotifier & StateNotifierProvider
* **Définition** : Une classe conçue pour gérer un état complexe qui évolue dans le temps via des méthodes explicites. `StateNotifierProvider` permet d'exposer ce gestionnaire à l'interface.
* **Exemple dans le code** : `CartNotifier` qui gère `CartState` dans [`lib/data/mock/mock_cart_repository.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/data/mock/mock_cart_repository.dart).

### AsyncValue (when)
* **Définition** : Un type Riverpod encapsulant les trois états d'une opération asynchrone : chargement (`loading`), succès avec données (`data`), ou échec (`error`). La méthode `.when()` garantit que le développeur traite obligatoirement ces trois cas.
* **Exemple dans le code** : L'affichage des catégories dans `HomeScreen._buildCategoriesSection()`.

---

## 3. Navigation et Routage

### GoRouter
* **Définition** : Package de routage déclaratif permettant de gérer les URLs, la pile de pages, les paramètres de requêtes et les redirections d'authentification.
* **Exemple dans le code** : Configuré dans [`lib/core/navigation/app_router.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/core/navigation/app_router.dart).

### StatefulShellRoute
* **Définition** : Mécanisme de GoRouter qui préserve l'état et le défilement de plusieurs branches d'onglets distinctes dans la barre de navigation.
* **Exemple dans le code** : La gestion des 5 onglets persistants de `MainShell`.

### context.go vs context.push
* **Définition** :
  * `context.go('/route')` : Remplace la localisation actuelle dans l'historique (idéal pour basculer d'onglet ou après connexion).
  * `context.push('/route')` : Empile un nouvel écran par-dessus l'écran actuel, conservant ainsi la flèche de retour arrière.
* **Exemple dans le code** : `context.push(AppRoutes.search)` depuis l'accueil pour pouvoir revenir en arrière.

---

## 4. Langage Dart & Programmation Moderne

### Future & async / await
* **Définition** : `Future` représente une valeur qui sera disponible plus tard (résultat d'une requête réseau, lecture d'un fichier). `async` marque une fonction asynchrone et `await` suspend temporairement l'exécution en attendant la fin de la tâche sans bloquer l'interface.
* **Exemple dans le code** : Le chargement simulé des produits dans `CatalogRepository.searchProducts()`.

### Null-Safety (?)
* **Définition** : Système du langage Dart empêchant les erreurs de pointeur nul (*NullPointerException*). Par défaut, une variable ne peut pas valoir `null`. Le point d'interrogation `?` indique explicitement qu'une valeur peut être absente.
* **Exemple dans le code** : `double? oldPrice` dans `ProductUiModel` (présent uniquement si le produit est en promotion).

### copyWith
* **Définition** : Méthode standard pour créer une copie d'un objet immuable en ne remplaçant que certains attributs ciblés.
* **Exemple dans le code** : `FilterCriteria.copyWith(...)` dans [`lib/core/ui/filter_sheet.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/core/ui/filter_sheet.dart).

### const
* **Définition** : Mot-clé indiquant que l'objet est une constante connue dès la compilation. Flutter optimise le rendu en évitant de reconstruire les widgets marqués `const`.
* **Exemple dans le code** : `const SizedBox(height: 16)` ou `const Icon(Icons.search)`.

### late
* **Définition** : Mot-clé indiquant au compilateur qu'une variable non-nullable sera initialisée plus tard, avant sa première utilisation.
* **Exemple dans le code** : `late FilterCriteria _filters;` dans `_CatalogScreenState.initState()`.

---

## 5. Architecture Logicielle & Design Patterns

### Repository Pattern
* **Définition** : Patron de conception séparant la logique métier de l'accès aux données. Il fournit une interface abstraite que l'UI consomme sans connaître l'origine des données (API REST, SQLite, Mock).
* **Exemple dans le code** : `CatalogRepository` implémenté par `MockCatalogRepository`.

### Mock (Données Simulées)
* **Définition** : Un composant logiciel qui simule le comportement d'un service réel (comme un serveur distant) en fournissant des réponses prévisibles avec une latence artificielle.
* **Exemple dans le code** : `MockAuthRepository` simulant les temps de réponse d'un serveur d'authentification.

### UiModel (Modèle UI)
* **Définition** : Classe de données simplifiée contenant uniquement les attributs requis pour l'affichage à l'écran, sans détails techniques liés à la base de données.
* **Exemple dans le code** : `CartItemUiModel` dans [`lib/data/models/cart_item_ui_model.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/data/models/cart_item_ui_model.dart).

---

## 6. Concepts Ergonomie & UI/UX

### Debounce (Temporisation)
* **Définition** : Technique retardant l'exécution d'un traitement coûteux (comme une recherche) jusqu'à ce qu'un certain délai d'inactivité se soit écoulé.
* **Exemple dans le code** : Minuteur de 400 ms dans `SearchScreen` pour ne lancer la recherche qu'après l'arrêt de la saisie utilisateur.

### Shimmer (Chargement Squelette)
* **Définition** : Effet d'animation lumineuse parcourant des formes grises mimant la mise en page finale, offrant un meilleur retour utilisateur qu'un simple cercle tournant.
* **Exemple dans le code** : `ShimmerBox` dans [`lib/core/ui/loading_state.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/core/ui/loading_state.dart).

### Semantics
* **Définition** : Système d'accessibilité de Flutter fournissant des annotations textuelles pour les technologies d'assistance (lecteurs d'écran TalkBack / VoiceOver).
* **Exemple dans le code** : `Semantics(label: 'Ouvrir mon panier', button: true, child: ...)` dans l'AppBar de l'accueil.


---

## 7. Firebase & Synchronisation Temps Réel

### Cloud Firestore
* **Définition** : Base de données NoSQL hébergée dans le Cloud par Google, organisée en collections et documents, offrant une synchronisation en direct bidirectionnelle.
* **Exemple dans le code** : Collections `products`, `orders` et `users/{uid}/addresses`.

### Stream (Flux Réactif Asynchrone)
* **Définition** : Tuyau de communication émettant une séquence d'événements dans le temps. Dans Flutter, un `Stream` branché sur Firestore permet à l'interface de s'actualiser toute seule dès qu'une modification survient en base sans aucun rechargement manuel.
* **Exemple dans le code** : `watchMyOrders()` et `myOrdersStreamProvider` qui mettent à jour l'écran « Mes commandes » quand l'Admin change le statut.

### Snapshot (Copie Figée)
* **Définition** : Capture immuable de l'état des données à un instant précis. Utilisé lors de la commande pour figer le nom, le prix unitaire et l'adresse de livraison, afin que les futures modifications de catalogue de l'Admin n'altèrent pas l'historique de la facture.
* **Exemple dans le code** : `OrderItemUiModel` et `OrderDeliveryAddress` dans `OrderUiModel`.

### WriteBatch & Transaction
* **Définition** : Mécanismes d'écriture atomique dans Firestore assurant le principe du « tout ou rien ». Soit l'ensemble des opérations réussit, soit aucune n'est appliquée, évitant les états incohérents en cas de coupure réseau.
* **Exemple dans le code** : `_firestore.batch()` lors de la création de commande et `_firestore.runTransaction()` lors de l'annulation d'une commande.

### Index Composite
* **Définition** : Structure de données Firestore combinant plusieurs champs indexés pour optimiser les requêtes combinant filtres d'égalité et tris (ex: `userId == uid` ET `createdAt DESC`).
* **Exemple dans le code** : `firestore.indexes.json` pour la collection `orders`.

### Règles de Sécurité (Firestore Security Rules)
* **Définition** : Règles exécutées directement sur les serveurs Google évaluant chaque tentative de lecture ou d'écriture selon l'identité de l'utilisateur (`request.auth`) et le contenu des données (`request.resource.data`).
* **Exemple dans le code** : `firestore.rules` garantissant qu'un client ne peut lire que ses propres commandes et ne peut annuler qu'une commande en attente.
