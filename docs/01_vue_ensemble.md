# 01 — Vue d'ensemble du projet Dokan (Client)

Bienvenue dans la documentation technique de **Dokan**, une application mobile e-commerce développée avec le framework **Flutter** pour la cible Android. Ce document s'adresse particulièrement aux étudiantes et étudiants en informatique et développement des systèmes d'information qui souhaitent comprendre l'architecture, les choix de conception et le flux applicatif d'une application e-commerce moderne.

---

## 1. Objectif du produit et contexte

**Dokan** est une plateforme de commerce mobile destinée au grand public tunisien (prix libellés en dinars tunisiens `DT`). L'application permet de consulter un catalogue de produits variés (mode, électronique, maison, etc.), de rechercher et filtrer des articles, de gérer des favoris et de constituer un panier d'achat.

Le système complet comportera à terme trois applications distinctes :
1. **L'application Client** (l'objet de ce projet et de cette documentation).
2. **L'application Administrateur** (gestion des stocks, commandes, commerçants).
3. **L'application Livreur** (gestion des tournées et livraisons).

---

## 2. Périmètre fonctionnel (Étapes 1 à 5)

Le développement a été réalisé de manière incrémentale selon 5 étapes précises :

* **Étape 1 — Fondations et Navigation** : Initialisation du projet, mise en place d'un thème Material 3 totalement isolé (palette de couleurs unique sans valeurs codées en dur), barre de navigation inférieure persistante à 5 onglets (`MainShell`), gestionnaire de session et composants réutilisables.
* **Étape 2 — Accueil, Catégories et Cartes Produits** : Écran d'accueil dynamique avec bannières dégradées peintes en code, carrousels de catégories et de sélections produits, grille responsive et pagination simulée au défilement.
* **Étape 3 — Recherche, Filtres, Tri et Fiche Produit** : Moteur de recherche avec temporisation (*debounce* de 400 ms), panneau modal de tri, panneau modal de filtres multicritères (fourchette de prix, catégories, disponibilité en stock), et fiche produit détaillée (galerie d'images, variantes, quantités, disponibilité).
* **Étape 4 — Gestion des états Visiteur / Client & Authentification** : Écrans de connexion, inscription et mot de passe oublié. Mécanisme de protection d'accès avec boîte de dialogue contextuelle et reprise automatique de l'action souhaitée (*Pending Action*).
* **Étape 5 — Favoris Client & Panier Réactif** : Liste réactive des favoris synchronisée en temps réel, panier d'achat complet avec sélecteur de quantités, calcul dynamique des totaux, application de code promotionnel (`Dokan10`), suppression avec option d'annulation (*Undo*), et transition protégée vers la commande.

### Ce qui est volontairement HORS PÉRIMÈTRE (étapes futures) :
Conformément au cahier des charges, les éléments suivants ne sont pas implémentés et affichent un message informatif (*SnackBar* : « *Cette fonctionnalité sera disponible prochainement.* ») :
- Le tunnel de commande final (sélection de l'adresse de livraison, choix du mode de paiement, confirmation bancaire).
- Le suivi des commandes en temps réel ("Mes commandes").
- L'édition du profil utilisateur et la modification du carnet d'adresses.
- Le système complet de dépôt et modération d'avis clients.
- Le module de notifications push et les écrans de paramètres avancés.
- L'appel à un backend réel (on utilise actuellement des fausses données simulées ou *mocks*).

---

## 3. Architecture en couches (Clean Architecture allégée)

Le projet adopte une séparation stricte des responsabilités. Le code est organisé de telle sorte que l'interface graphique ne sache rien de la façon dont les données sont stockées ou téléchargées.

### Schéma conceptuel des dépendances (ASCII) :

```
+-------------------------------------------------------------------------+
|                              COUCHES UI                                 |
|                                                                         |
|  [ Écrans (lib/feature/) ]                                              |
|      (HomeScreen, CatalogScreen, CartScreen, ProductDetailScreen...)    |
|       |                                                                 |
|       | Écoutent l'état (ref.watch) et déclenchent des actions          |
|       v                                                                 |
|  [ Composants partagés (lib/core/ui/) ]                                 |
|      (ProductCard, ProductGrid, QuantitySelector, AppTopBar...)         |
+-------------------------------------------------------------------------+
                                    |
                                    | appelle
                                    v
+-------------------------------------------------------------------------+
|                           GESTION D'ÉTAT                                |
|                                                                         |
|  [ Providers Riverpod (lib/data/mock/ & lib/core/session/) ]            |
|      (cartProvider, favoritesProvider, sessionProvider...)              |
|      -> Reçoivent les intentions utilisateur                            |
|      -> Mettent à jour les objets d'état immuables                      |
|      -> Notifient les widgets pour redessiner l'interface               |
+-------------------------------------------------------------------------+
                                    |
                                    | utilise
                                    v
+-------------------------------------------------------------------------+
|                           CONTRATS MÉTIER                               |
|                                                                         |
|  [ Repositories Abstraits (lib/data/repositories/) ]                    |
|      (CatalogRepository, AuthRepository, CartRepository...)             |
|      -> Définissent "CE QUE" l'application peut faire                   |
|      -> Renvoient des modèles UI purs (ProductUiModel, UserSummary...)  |
+-------------------------------------------------------------------------+
                                    ^
                                    | implémente
                                    |
+-------------------------------------------------------------------------+
|                         SOURCES DE DONNÉES                              |
|                                                                         |
|  [ Implémentations Simulées / Mocks (lib/data/mock/) ]                 |
|      (MockCatalogRepository, MockAuthRepository...)                     |
|      -> Simulent les latences réseau (Future.delayed)                   |
|      -> Fournissent des données réalistes en mémoire                    |
|      -> Simulent les cas d'erreurs (#error) et de listes vides (#empty) |
|                                                                         |
|  [ FUTUR : Implémentations Réelles API (lib/data/api/) ]                |
|      -> Appelleront un serveur via HTTP (Dio / http)                    |
+-------------------------------------------------------------------------+
```

### Règle d'or du flux de dépendances :
Les flèches pointent toujours vers l'intérieur :
- L'écran dépend du Provider.
- Le Provider dépend du Repository (interface).
- Le Repository ne connaît ni les widgets, ni Flutter.
- Ainsi, le jour où nous remplacerons les données fictives par une vraie base de données ou API REST, **aucun écran de l'application n'aura besoin d'être réécrit**.

---

## 4. Parcours détaillé d'une action de bout en bout

Pour bien comprendre comment interagissent tous les blocs de code, suivons le cycle de vie d'une action courante : **« Le client ajoute un produit au panier depuis la fiche produit »**.

```
Utilisateur clique sur "Ajouter au panier"
                     |
                     v
1. WIDGET : ProductDetailScreen (lib/feature/product/product_detail_screen.dart)
   - La méthode _onAddToCart(product) est appelée.
   - Elle récupère la quantité sélectionnée (_quantity) et la variante choisie.
   - Elle appelle le provider via : 
     ref.read(cartProvider.notifier).addProduct(product, quantity: _quantity, variant: ...);
                     |
                     v
2. NOTIFIER : CartNotifier (lib/data/mock/mock_cart_repository.dart)
   - Le notifier reçoit l'objet ProductUiModel et la quantité.
   - Il vérifie si l'article existe déjà dans la liste state.items.
   - S'il existe déjà : il incrémente sa quantité (sans dépasser le stock max).
   - S'il n'existe pas : il crée une nouvelle instance de CartItemUiModel.
   - Il recalcule immédiatement :
     * Le sous-total (subtotal)
     * La remise du code promo éventuel (discountAmount)
     * Les frais de port (deliveryFee)
     * Le total général (total)
   - Il produit une nouvelle copie de l'état : state = state.copyWith(items: ...);
                     |
                     v
3. PROPAGATION DE L'ÉTAT (Riverpod)
   - Tous les widgets qui avaient souscrit à l'état du panier se réveillent automatiquement :
     a) CartCountProvider (lib/core/navigation/main_shell.dart) :
        Le badge numérique au-dessus de l'icône du panier dans la barre inférieure
        s'incrémente instantanément (ex: passe de 0 à 1).
     b) CartScreen (lib/feature/cart/cart_screen.dart) :
        S'il était ouvert, il reconstruit sa liste d'articles et son PriceSummary.
                     |
                     v
4. FEEDBACK VISUEL : SnackBar
   - ProductDetailScreen déclenche un message temporaire en bas de l'écran :
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Article ajouté au panier.'))
     );
```

Ce flux garantit une cohérence absolue : les données ne sont jamais dupliquées manuellement, et chaque widget reflète en temps réel la source unique de vérité (*Single Source of Truth*).
