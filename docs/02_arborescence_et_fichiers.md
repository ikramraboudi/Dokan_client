# 02 — Arborescence et Inventaire des Fichiers

Ce document répertorie et décrit en détail **l'intégralité des 48 fichiers source** situés dans le dossier `lib/` de l'application Dokan Client, ainsi que les fichiers de tests.

---

## 1. Arborescence complète de `lib/`

```
lib/
├── app.dart                                 <- Configuration racine de l'application (Theme + GoRouter)
├── main.dart                                <- Point d'entrée exécutable (runApp + ProviderScope)
├── core/
│   ├── config/
│   │   └── app_config.dart                  <- Constantes globales (Nom, devise, durée du splash)
│   ├── navigation/
│   │   ├── app_router.dart                  <- Déclaration de l'arbre des routes GoRouter
│   │   ├── main_shell.dart                  <- Squelette des 5 onglets persistants avec badge panier
│   │   └── routes.dart                      <- Constantes textuelles des routes (URLs)
│   ├── session/
│   │   └── session_provider.dart            <- Gestion de l'état de connexion & action en attente
│   ├── theme/
│   │   ├── app_colors.dart                  <- PALETTE UNIQUE de couleurs (Aucune couleur ailleurs)
│   │   ├── app_dimens.dart                  <- Espacements, rayons d'arrondis et zones tactiles
│   │   └── app_theme.dart                   <- Construction du ThemeData Material 3
│   ├── ui/
│   │   ├── app_form_field.dart              <- Champ de saisie personnalisé et thémé
│   │   ├── app_top_bar.dart                 <- Barre d'en-tête (AppBar) réutilisable
│   │   ├── auth_required_dialog.dart        <- Boîte de dialogue pour inviter à la connexion
│   │   ├── empty_state.dart                 <- Vue pour liste vide (icône + texte + bouton)
│   │   ├── error_state.dart                 <- Vue pour erreur réseau avec bouton réessayer
│   │   ├── filter_sheet.dart                <- Feuille modale de filtres (prix, catégorie, stock)
│   │   ├── loading_state.dart               <- Animation de chargement squelette (shimmer natif)
│   │   ├── price_summary.dart               <- Récapitulatif du panier (sous-total, remise, total)
│   │   ├── product_card.dart                <- Carte produit (image, prix, badge, cœur favori)
│   │   ├── product_grid.dart                <- Grille responsive de cartes avec pagination au scroll
│   │   ├── quantity_selector.dart           <- Sélecteur de quantité [-] 1 [+]
│   │   └── sort_sheet.dart                  <- Feuille modale de sélection du critère de tri
│   └── utils/
│       └── validators.dart                  <- Validateurs de formulaires (email, mot de passe)
├── data/
│   ├── mock/
│   │   ├── mock_auth_repository.dart        <- Simulation de connexion/inscription avec latence
│   │   ├── mock_cart_repository.dart        <- Gestionnaire en mémoire du panier & code promo
│   │   ├── mock_catalog_repository.dart     <- 7 catégories et ~35 produits simulés avec filtres
│   │   └── mock_favorites_repository.dart   <- Gestionnaire en mémoire de la liste de favoris
│   ├── models/
│   │   ├── cart_item_ui_model.dart          <- Modèle d'une ligne du panier
│   │   ├── category_ui_model.dart           <- Modèle d'une catégorie (nom, icône, total)
│   │   ├── favorite_ui_model.dart           <- Modèle d'un favori
│   │   ├── product_ui_model.dart            <- Modèle d'un produit complet
│   │   └── user_summary.dart                <- Modèle du profil client connecté
│   └── repositories/
│       ├── auth_repository.dart             <- Interface abstraite d'authentification
│       ├── cart_repository.dart             <- Interface abstraite du panier
│       ├── catalog_repository.dart          <- Interface abstraite du catalogue
│       └── favorites_repository.dart        <- Interface abstraite des favoris
└── feature/
    ├── auth/
    │   ├── forgot_password_screen.dart      <- Écran de récupération de mot de passe
    │   ├── login_screen.dart                <- Écran de connexion client
    │   └── register_screen.dart             <- Écran d'inscription nouveau compte
    ├── cart/
    │   └── cart_screen.dart                 <- Écran du panier d'achat
    ├── catalog/
    │   ├── catalog_screen.dart              <- Catalogue complet avec filtres, tri et chips
    │   ├── categories_screen.dart           <- Liste détaillée des 7 catégories
    │   └── search_screen.dart               <- Recherche avec debounce et historique récent
    ├── favorites/
    │   └── favorites_screen.dart            <- Écran des favoris (protégé pour le visiteur)
    ├── home/
    │   └── home_screen.dart                 <- Écran d'accueil principal (bannières, sélections)
    ├── product/
    │   └── product_detail_screen.dart       <- Fiche produit détaillée (galerie, variantes, ajout)
    ├── profile/
    │   └── profile_screen.dart              <- Écran de profil (invite visiteur ou compte client)
    └── splash/
        └── splash_screen.dart               <- Écran d'ouverture avec temporisation de 3 secondes
```

---

## 2. Description détaillée fichier par fichier

### Fichiers Racine

#### `lib/main.dart`
* **Rôle** : Point d'entrée universel du binaire Flutter.
* **Classes et éléments clés** :
  * `main()` : Fonction initiale qui appelle `runApp()`.
* **Dépendances** : Dépend de `package:flutter_riverpod` et de `lib/app.dart`.
* **Utilisé par** : Le moteur Flutter au démarrage.

#### `lib/app.dart`
* **Rôle** : Widget racine de l'arbre (`DokanApp`), initialisant le système de thème et le routage.
* **Classes et éléments clés** :
  * `DokanApp` (`StatelessWidget`) : Renvoie le `MaterialApp.router`.
* **Dépendances** : `app_theme.dart`, `app_router.dart`, `app_config.dart`.
* **Utilisé par** : `main.dart` et les tests d'intégration (`widget_test.dart`).

---

### Couche `core/config/`

#### `lib/core/config/app_config.dart`
* **Rôle** : Fichier de configuration globale du produit.
* **Classes et éléments clés** :
  * `AppConfig` : Classe à constructeur privé contenant les constantes `appName` ('Dokan'), `currencyCode` ('TND'), `currencySymbol` ('DT'), `splashDuration` (3 secondes).
  * `formatPrice(double price)` : Fonction de conversion renvoyant par exemple `"49,900 DT"`.
* **Utilisé par** : Les cartes produits, la fiche détaillée, le récapitulatif panier et le splash screen.

---

### Couche `core/theme/`

#### `lib/core/theme/app_colors.dart`
* **Rôle** : Registre d'or et unique source de vérité des couleurs.
* **Classes et éléments clés** :
  * `AppColors` : Définit les constantes `primary` (vert canard 0xFF1F7A7A), `accent` (ambre 0xFFF2A65A), `favorite` (corail 0xFFE05A6D), `background` (crème 0xFFF7F5F0), `surface`, `border`, `textPrimary`, `error`, etc.
* **Règle absolue** : Aucun autre fichier dans toute l'application ne contient `Color(0x...)` ou `Colors.xxx`.

#### `lib/core/theme/app_dimens.dart`
* **Rôle** : Constantes harmonisées pour la mise en page et les transitions.
* **Classes et éléments clés** :
  * `AppDimens` : `space4` à `space40`, `radius8` à `radiusFull`, `minTouchTarget` (48.0), `buttonHeight` (52.0), durées d'animations (`animFast`, `animMedium`).

#### `lib/core/theme/app_theme.dart`
* **Rôle** : Assemblage du `ThemeData` Material 3 (clair uniquement).
* **Classes et éléments clés** :
  * `AppTheme.lightTheme` : Configure le `ColorScheme`, les typographies, `AppBarTheme`, `ElevatedButtonThemeData`, `InputDecorationTheme`, `CardThemeData`, `NavigationBarThemeData`.

---

### Couche `core/navigation/`

#### `lib/core/navigation/routes.dart`
* **Rôle** : Centralisation des chaînes de caractères représentant les chemins de navigation.
* **Constantes** : `splash`, `home`, `categories`, `favorites`, `cart`, `profile`, `catalog`, `search`, `productDetail`, `login`, `register`, `forgotPassword`.

#### `lib/core/navigation/app_router.dart`
* **Rôle** : Création et configuration du singleton `GoRouter`.
* **Éléments clés** :
  * `appRouterProvider` : Provider Riverpod exposant le routeur.
  * `StatefulShellRoute.indexedStack` : Découpe l'application en branches d'onglets persistants pour préserver la mémoire de chaque page.

#### `lib/core/navigation/main_shell.dart`
* **Rôle** : Conteneur visuel des 5 onglets.
* **Classes et éléments clés** :
  * `cartCountProvider` (`StateProvider<int>`) : Compteur réactif du nombre d'articles dans le panier.
  * `MainShell` (`ConsumerWidget`) : Affiche le `NavigationBar` Material 3 avec les icônes d'Accueil, Catégories, Favoris, Panier (avec son Badge) et Profil.

---

### Couche `core/session/`

#### `lib/core/session/session_provider.dart`
* **Rôle** : Gestion d'état de l'authentification et mémoire de l'action utilisateur en attente.
* **Classes et éléments clés** :
  * `SessionState` : Objet immuable (`user`, `isGuest`, `pendingProtectedAction`).
  * `SessionNotifier` (`StateNotifier<SessionState>`) : Méthodes `loginSuccess()`, `logout()`, `setPendingAction()`, `simulateSessionExpired()`.
  * `sessionProvider` : Provider global pour observer la session.

---

### Couche `core/utils/`

#### `lib/core/utils/validators.dart`
* **Rôle** : Logique de validation des champs de formulaires textuels.
* **Méthodes statiques** :
  * `email(String? value)` : Valide la présence d'un format email conforme.
  * `password(String? value)` : Vérifie au moins 8 caractères, 1 chiffre et 1 majuscule.
  * `confirmPassword(String? value, String original)` : Vérifie l'égalité stricte des mots de passe.
  * `fullName(String? value)` : Vérifie au moins 2 caractères alphabétiques.

---

### Couche `core/ui/` (Composants Réutilisables)

#### `lib/core/ui/app_top_bar.dart`
* **Rôle** : En-tête d'écran (`AppBar`) standardisé avec logo Dokan ou titre textuel, et bouton retour paramétrable.

#### `lib/core/ui/app_form_field.dart`
* **Rôle** : Champ de saisie personnalisé (`TextFormField`) avec label, icône, état de mot de passe masquable et bordures thémées.

#### `lib/core/ui/loading_state.dart`
* **Rôle** : Animation de chargement squelette (shimmer) codée en pur Flutter via un `AnimationController` sans dépendance externe.
* **Composants** : `ShimmerLoading`, `ShimmerBox`.

#### `lib/core/ui/empty_state.dart`
* **Rôle** : Affichage d'un état sans données (icône grise, titre, description explicative et bouton d'action optionnel).

#### `lib/core/ui/error_state.dart`
* **Rôle** : Affichage d'un état d'erreur avec icône d'alerte, message explicatif et bouton « Réessayer ».

#### `lib/core/ui/product_card.dart`
* **Rôle** : Carte visuelle affichant un produit individuel :
  * Image avec chargement sécurisé et fallback en cas d'erreur.
  * Badges d'état (promotion, stock épuisé).
  * Bouton cœur pour l'ajout aux favoris.
  * Prix avec composant `Wrap` pour garantir l'absence de débordement graphique (`RenderFlex overflow`).

#### `lib/core/ui/product_grid.dart`
* **Rôle** : Grille responsive (2 colonnes sur smartphone, 3 sur tablette) bâtie sur un `CustomScrollView` et un `SliverGrid`, gérant la détection du bas de page pour déclencher le chargement de la page suivante.

#### `lib/core/ui/quantity_selector.dart`
* **Rôle** : Contrôle interactif permettant d'ajuster une quantité avec boutons `[-]` et `[+]` et bornes minimales et maximales.

#### `lib/core/ui/sort_sheet.dart`
* **Rôle** : Dialogue modale glissant depuis le bas (`showModalBottomSheet`) proposant 5 choix de tri (pertinence, prix croissant/décroissant, popularité, nouveautés).

#### `lib/core/ui/filter_sheet.dart`
* **Rôle** : Dialogue modale de filtrage avec `RangeSlider` pour le prix (0 à 300 DT), choix de catégorie via `ChoiceChip` et interrupteur « En stock uniquement ».

#### `lib/core/ui/price_summary.dart`
* **Rôle** : Encadré récapitulatif calculant le sous-total, la déduction d'un code promo, les frais de livraison et le total final.

#### `lib/core/ui/auth_required_dialog.dart`
* **Rôle** : Boîte de dialogue non cumulable informant un visiteur qu'une action nécessite un compte, avec enregistrement de l'action en attente et redirection vers la connexion ou l'inscription.

---

### Couche `data/models/`

* `lib/data/models/user_summary.dart` : Profil utilisateur (`id`, `fullName`, `email`).
* `lib/data/models/category_ui_model.dart` : Catégorie (`id`, `name`, `icon`, `productCount`).
* `lib/data/models/product_ui_model.dart` : Produit complet (`id`, `name`, `description`, `price`, `oldPrice`, `imageUrls`, `availability`, `rating`, `reviewCount`, `variants`).
* `lib/data/models/favorite_ui_model.dart` : Modèle de favori avec date d'ajout.
* `lib/data/models/cart_item_ui_model.dart` : Article du panier (`id`, `name`, `unitPrice`, `quantity`, `imageUrl`, `variantLabel`).

---

### Couche `data/repositories/` (Contrats Abstraits)

* `lib/data/repositories/auth_repository.dart` : Contrat `login()`, `register()`, `sendPasswordReset()`.
* `lib/data/repositories/catalog_repository.dart` : Contrat `getCategories()`, `getNewProducts()`, `getDiscountedProducts()`, `getPopularProducts()`, `searchProducts()`, `getProductById()`.
* `lib/data/repositories/favorites_repository.dart` : Contrat `getFavorites()`, `addFavorite()`, `removeFavorite()`.
* `lib/data/repositories/cart_repository.dart` : Contrat `getCart()`, `addToCart()`, `updateQuantity()`, `removeFromCart()`.

---

### Couche `data/mock/` (Implémentations Fictives)

#### `lib/data/mock/mock_catalog_repository.dart`
* **Rôle** : Génère en mémoire 7 catégories et ~35 articles avec des images uniques Picsum Photos. Simule un délai de 400 à 700 ms, la pagination par lots de 6, et intercepte `#error` pour tester les pannes et `#empty` pour tester les recherches infructueuses.

#### `lib/data/mock/mock_auth_repository.dart`
* **Rôle** : Simule l'authentification avec un compte de démonstration (`demo@Dokan.com` / `Demo1234`) et un compte de test d'échec (`fail@Dokan.com`).

#### `lib/data/mock/mock_favorites_repository.dart`
* **Rôle** : `FavoritesNotifier` gère la liste réactive des favoris avec notification en temps réel de tous les écrans qui l'écoutent.

#### `lib/data/mock/mock_cart_repository.dart`
* **Rôle** : `CartNotifier` gère les ajouts, modifications de quantité, application du code promo `Dokan10` (-10 %) et restauration d'un article supprimé (*Undo*).

---

### Couche `feature/` (Écrans Utilisateurs)

* `lib/feature/splash/splash_screen.dart` : Affiche l'identité visuelle de Dokan pendant 3 secondes avant de rediriger automatiquement vers l'Accueil.
* `lib/feature/home/home_screen.dart` : Page d'accueil : champ de recherche cliquable, carrousel de bannières avec dégradés, catégories en défilement horizontal et 3 sections horizontales d'articles. Défilement vertical unique via `SingleChildScrollView`.
* `lib/feature/catalog/categories_screen.dart` : Liste verticale des 7 catégories avec compteur de produits et redirection vers le catalogue pré-filtré.
* `lib/feature/catalog/catalog_screen.dart` : Catalogue général avec barre d'outils, modales de tri et filtres, puces amovibles (`InputChip`) et grille paginée.
* `lib/feature/catalog/search_screen.dart` : Moteur de recherche avec délai d'attente (debounce de 400 ms), historique récent en mémoire et raccourcis de suggestions populaires.
* `lib/feature/product/product_detail_screen.dart` : Fiche détaillée : carrousel d'images, avis, variante au choix (`ChoiceChip`), sélecteur de quantité, description et barre fixe avec cœur et bouton d'ajout au panier.
* `lib/feature/auth/login_screen.dart` : Écran de connexion avec validation de formulaire, bouton désactivé pendant le chargement et lien vers mot de passe oublié.
* `lib/feature/auth/register_screen.dart` : Écran d'inscription avec case à cocher des conditions générales d'utilisation.
* `lib/feature/auth/forgot_password_screen.dart` : Demande d'e-mail de réinitialisation avec bascule vers un écran de confirmation bienveillant.
* `lib/feature/favorites/favorites_screen.dart` : Écran alternatif affichant une invite de connexion pour le visiteur ou la grille dynamique pour le client connecté.
* `lib/feature/cart/cart_screen.dart` : Gestion du panier d'achat, saisie du code promo, récapitulatif chiffré et bouton de passage de commande conditionné au statut de connexion.
* `lib/feature/profile/profile_screen.dart` : Écran de bienvenue avec boutons de connexion pour le visiteur, ou affichage du profil, simulateur d'expiration de session et déconnexion sécurisée pour le client.

---

### Tests Automatisés

#### `test/widget_test.dart`
* **Rôle** : Test d'intégration et de fumée (*Smoke test*) validant le bon démarrage de l'application, l'affichage initial du splash screen, l'écoulement de la durée de 3 secondes, et l'arrivée effective sur l'écran d'accueil avec sa barre de navigation.
