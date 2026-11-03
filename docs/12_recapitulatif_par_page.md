# 12 — Fiches Récapitulatives par Écran (Dokan Client)

> **Document de préparation à l'oral pour l'étudiante**  
> Ce document regroupe une fiche technique standardisée pour chaque écran de l'application Dokan. Chaque fiche détaille le rôle, les composants vus, les actions possibles, les flux d'écrans, les données utilisées et la question piège du professeur accompagnée de sa réponse immédiate.

---

## 1. Plan de Navigation Global (Schéma ASCII)

```text
                               ┌───────────────────┐
                               │   SplashScreen    │
                               │     (/splash)     │
                               └─────────┬─────────┘
                                         │ (Auto 3s ou Skip)
                                         ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                      MAIN SHELL (Barre de navigation 5 onglets)                        │
│                                                                                        │
│   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌────────────┐  ┌─────────┐ │
│   │  HomeScreen  │   │  Categories  │   │  Favorites   │   │ CartScreen │  │ Profile │ │
│   │   (/home)    │   │ (/categories)│   │ (/favorites) │   │  (/cart)   │  │(/profile│ │
│   └──────┬───────┘   └──────┬───────┘   └──────┬───────┘   └─────┬──────┘  └────┬────┘ │
└──────────┼──────────────────┼──────────────────┼─────────────────┼──────────────┼──────┘
           │                  │                  │                 │              │
           ├──────────────────┼──────────────────┘                 │              │
           ▼                  ▼                                    │              │
    ┌──────────────┐   ┌──────────────┐                            │              │
    │ SearchScreen │   │CatalogScreen │                            │              │
    │  (/search)   │   │  (/catalog)  │                            │              │
    └──────┬───────┘   └──────┬───────┘                            │              │
           │                  │                                    │              │
           └─────────┬────────┘                                    │              │
                     ▼                                             │              │
          ┌─────────────────────┐                                  │              │
          │ ProductDetailScreen │                                  │              │
          │    (/product/:id)   │                                  │              │
          └──────────┬──────────┘                                  │              │
                     │ (Ajouter au panier)                         │              │
                     └─────────────────────────────────────────────┤              │
                                                                   │              │
                                                                   ▼              │
                                                       ┌───────────────────────┐  │
                                                       │    CheckoutScreen     │  │
                                                       │      (/checkout)      │  │
                                                       └───────────┬───────────┘  │
                                                                   │              │
                                                                   ▼              │
                                                       ┌───────────────────────┐  │
                                                       │OrderConfirmationScreen│  │
                                                       │(/order-confirmation)  │  │
                                                       └───────────┬───────────┘  │
                                                                   │              │
                                 ┌─────────────────────────────────┴──────────────┤
                                 ▼                                                ▼
                     ┌───────────────────────┐                        ┌───────────────────────┐
                     │    MyOrdersScreen     │                        │    AddressesScreen    │
                     │       (/orders)       │                        │     (/addresses)      │
                     └───────────┬───────────┘                        └───────────┬───────────┘
                                 │                                                │
                                 ▼                                                ▼
                     ┌───────────────────────┐                        ┌───────────────────────┐
                     │   OrderDetailScreen   │                        │ AddEditAddressScreen  │
                     │     (/orders/:id)     │                        │(/addresses/add|edit)  │
                     └───────────────────────┘                        └───────────────────────┘

  [ MODULE D'AUTHENTIFICATION TRANSVERSE ]
  Accessible depuis n'importe quelle invite ou profil :
  ┌──────────────┐        ┌─────────────────┐        ┌────────────────────────┐
  │ LoginScreen  │ <----> │ RegisterScreen  │ -----> │ ForgotPasswordScreen   │
  │   (/login)   │        │   (/register)   │        │   (/forgot-password)   │
  └──────────────┘        └─────────────────┘        └────────────────────────┘
```

---

## 2. Fiches Écran par Écran

---

### Fiche 1 : Écran de Démarrage (`SplashScreen`)
* **Rôle de la page** : Présente l'identité de marque Dokan avec une animation soignée et restaure la session Firebase en tâche de fond.
* **Fichier** : `lib/feature/splash/splash_screen.dart` (`SplashScreen`).
* **Ce que l'utilisateur voit** : Logo Dokan s'animant au centre avec effet d'échelle, apparition progressive lettre par lettre du texte « DOKAN », particules lumineuses d'ambiance, slogan de l'app et bouton « Passer » en haut à droite.
* **Ce qu'il peut faire** : Attendre 3 secondes ou cliquer sur « Passer » pour aller directement à l'accueil.
* **Interactions et navigation** :
  - *Source* : Point d'entrée au lancement de l'application (route racine `/splash`).
  - *Cible* : Redirige vers `/home` (`context.go(AppRoutes.home)`).
* **Données utilisées** : `AppConfig.splashDuration` (3 secondes), `FirebaseAuth.instance.authStateChanges()`, `sessionProvider`.
* **États gérés** : Chargement fluide sans coupure ; bascule silencieuse en mode visiteur si absence de réseau.
* **Fonctionnalité précise** : Cette page sert à initialiser l'environnement technique tout en offrant un accueil visuel haut de gamme.
* **Question probable du prof** : *« Pourquoi avoir mis un délai de 3 secondes sur le splash ? N'est-ce pas trop long ? »*
  - **Réponse simple** : *« C'est un choix de design pour laisser le temps à l'animation de marque de se déployer et vérifier la session Firebase Auth en tâche de fond. De plus, nous avons ajouté un bouton "Passer" en haut à droite pour respecter l'ergonomie et ne jamais bloquer l'utilisateur. »*

---

### Fiche 2 : Écran d'Accueil (`HomeScreen`)
* **Rôle de la page** : Vitrine principale présentant les bannières promotionnelles, les rubriques majeures et les sélections de produits.
* **Fichier** : `lib/feature/home/home_screen.dart` (`HomeScreen`).
* **Ce que l'utilisateur voit** : Barre supérieure avec logo Dokan et raccourci recherche, carrousel automatique de 3 bannières avec indicateurs de points, liste horizontale des catégories, trois carrousels horizontaux de produits (Promotions, Nouveautés, Populaires).
* **Ce qu'il peut faire** : Faire défiler les bannières, toucher une catégorie pour voir ses produits, faire défiler les produits horizontalement, toucher un produit pour voir sa fiche, cliquer sur un cœur pour ajouter aux favoris, tirer vers le bas pour rafraîchir.
* **Interactions et navigation** :
  - *Source* : Onglet 1 du `MainShell` (`/home`).
  - *Cibles* : `/search`, `/catalog`, `/product/:id`, `/login` (si clic favori en mode visiteur).
* **Données utilisées** : `productServiceProvider` (flux Firestore en temps réel pour `isNew`, `hasDiscount`, `isPopular`), `catalogRepositoryProvider`.
* **États gérés** : Chargement (roulette), Erreur (`ErrorState` avec bouton Réessayer), pull-to-refresh (`RefreshIndicator`).
* **Fonctionnalité précise** : Cette page sert à orienter rapidement l'acheteur vers les meilleures offres et les tendances du moment.
* **Question probable du prof** : *« Comment faites-vous pour que les sections de produits défilent sans bloquer le défilement de toute la page ? »*
  - **Réponse simple** : *« Nous utilisons un `SingleChildScrollView` vertical principal, et à l'intérieur des `ListView.builder` horizontaux avec la propriété `scrollDirection: Axis.horizontal`. Flutter gère parfaitement l'indépendance des axes sans conflit de gestes. »*

---

### Fiche 3 : Écran Catégories (`CategoriesScreen`)
* **Rôle de la page** : Présente l'ensemble des rayons du magasin sous forme de liste structurée.
* **Fichier** : `lib/feature/catalog/categories_screen.dart` (`CategoriesScreen`).
* **Ce que l'utilisateur voit** : Liste des 7 catégories de l'enseigne avec icône ronde Material, libellé en gras, nombre d'articles disponibles et flèche de navigation.
* **Ce qu'il peut faire** : Toucher une catégorie pour ouvrir le catalogue filtré sur cette sélection.
* **Interactions et navigation** :
  - *Source* : Onglet 2 du `MainShell` (`/categories`).
  - *Cibles* : `/catalog?category=NomDeLaCategorie`.
* **Données utilisées** : `allCategoriesProvider` interrogeant `catalogRepositoryProvider`.
* **États gérés** : `loading` (spinner centré), `error` (bouton réessayer), `data` (liste des cartes).
* **Fonctionnalité précise** : Cette page sert à naviguer méthodiquement dans l'arbre des univers de produits.
* **Question probable du prof** : *« Pourquoi utiliser un FutureProvider plutôt qu'un StreamProvider pour les catégories ? »*
  - **Réponse simple** : *« Les catégories changent rarement en cours de session. Une requête asynchrone ponctuelle `FutureProvider` suffit largement et consomme moins de batterie et de bande passante qu'un Stream permanent. »*

---

### Fiche 4 : Écran Catalogue Général et Filtré (`CatalogScreen`)
* **Rôle de la page** : Affiche les produits sous forme de grille paginée avec outils avancés de tri et filtrage.
* **Fichier** : `lib/feature/catalog/catalog_screen.dart` (`CatalogScreen`).
* **Ce que l'utilisateur voit** : Barre du haut avec nom de la catégorie active, barre d'outils avec boutons « Filtres » (avec pastille si actif) et « Trier », grille à 2 colonnes de cartes produits, indicateur de chargement en bas lors du défilement infini.
* **Ce qu'il peut faire** : Ouvrir la feuille de filtres (prix min/max, en stock uniquement), ouvrir la feuille de tri (prix croissant, popularité), cliquer sur une carte produit, cliquer sur le cœur de favori.
* **Interactions et navigation** :
  - *Source* : `/home` ou `/categories`.
  - *Cibles* : `/product/:id`, dialogues de filtres (`FilterSheet`, `SortSheet`).
* **Données utilisées** : `catalogRepositoryProvider.getProductsByCategory()` et `searchProducts()`.
* **États gérés** : Chargement initial, chargement de page suivante (`isLoadingMore`), état vide (« Aucun produit ne correspond »), erreur.
* **Fonctionnalité précise** : Cette page sert à explorer et affiner un large volume d'articles selon des critères personnalisés.
* **Question probable du prof** : *« Comment fonctionne votre pagination infinie dans la grille ? »*
  - **Réponse simple** : *« Notre widget `ProductGrid` attache un écouteur sur le `ScrollController`. Dès que la position de défilement atteint les 200 derniers pixels de l'écran, il déclenche automatiquement le chargement du lot de 6 produits suivant. »*

---

### Fiche 5 : Écran Recherche Multicritères (`SearchScreen`)
* **Rôle de la page** : Moteur de recherche textuel instantané dans tout le catalogue.
* **Fichier** : `lib/feature/catalog/search_screen.dart` (`SearchScreen`).
* **Ce que l'utilisateur voit** : Champ de recherche avec focus automatique et croix d'effacement, historique ou suggestions populaires si vide, grille de résultats dès la saisie.
* **Ce qu'il peut faire** : Taper un nom de produit ou de marque, effacer d'un clic, toucher un résultat.
* **Interactions et navigation** :
  - *Source* : Raccourci loupe depuis `/home`.
  - *Cible* : `/product/:id`.
* **Données utilisées** : `searchProducts()` dans `FirestoreCatalogRepository`.
* **États gérés** : Saisie vide (invite à chercher), recherche en cours (spinner discret), aucun résultat trouvé (`EmptyState`).
* **Fonctionnalité précise** : Cette page sert à trouver un article en moins de 3 secondes grâce à la saisie assistée.
* **Question probable du prof** : *« Qu'est-ce qu'un "debounce" et pourquoi l'avez-vous mis sur la recherche ? »*
  - **Réponse simple** : *« Le debounce est un délai de 300 ms avec un `Timer` Dart. Si l'utilisateur tape vite "chaussures", l'app n'envoie pas 10 requêtes pour chaque lettre, mais une seule requête à la fin de la frappe. Cela économise les ressources du serveur. »*

---

### Fiche 6 : Fiche Produit Détaillée (`ProductDetailScreen`)
* **Rôle de la page** : Présentation exhaustive d'un article avant prise de décision d'achat.
* **Fichier** : `lib/feature/product/product_detail_screen.dart` (`ProductDetailScreen`).
* **Ce que l'utilisateur voit** : Galerie photo à défilement horizontal avec indicateurs, badges de disponibilité (En stock / Rupture), nom complet, note avec nombre d'avis, ancien prix barré et prix courant, sélecteur de variantes (tailles/couleurs), descriptif complet, sélecteur de quantité (+/-), et barre fixe en bas avec bouton « Ajouter au panier ».
* **Ce qu'il peut faire** : Faire défiler les photos, changer de variante, ajuster la quantité, ajouter aux favoris, ajouter au panier.
* **Interactions et navigation** :
  - *Source* : Carte produit depuis l'accueil, le catalogue ou la recherche.
  - *Cibles* : Ajout direct au panier (mise à jour du badge dans `MainShell`), retour en arrière.
* **Données utilisées** : `productDetailProvider(id)`, `cartProvider.notifier.addProduct()`, `favoritesProvider`.
* **États gérés** : Chargement, produit inexistant, produit en rupture de stock (bouton d'achat grisé).
* **Fonctionnalité précise** : Cette page sert à convertir l'intérêt de l'utilisateur en ajout concret au panier.
* **Question probable du prof** : *« Comment empêchez-vous d'ajouter un produit épuisé au panier ? »*
  - **Réponse simple** : *« Nous vérifions la propriété `product.isInStock`. Si elle est fausse, le bouton "Ajouter au panier" passe son paramètre `onPressed` à `null`, ce qui désactive visuellement et fonctionnellement le clic. »*

---

### Fiche 7 : Écran de Connexion (`LoginScreen`)
* **Rôle de la page** : Permet à un utilisateur existant de s'authentifier par adresse email et mot de passe.
* **Fichier** : `lib/feature/auth/login_screen.dart` (`LoginScreen`).
* **Ce que l'utilisateur voit** : Avatar stylisé Dokan, titre accueillant, champs email et mot de passe (avec œil pour afficher/masquer), lien « Mot de passe oublié », bouton de connexion et lien vers l'inscription.
* **Ce qu'il peut faire** : Saisir ses identifiants, valider le formulaire, naviguer vers mot de passe oublié ou inscription.
* **Interactions et navigation** :
  - *Source* : Profil, dialogues d'invitation (`AuthRequiredDialog`), passage de commande.
  - *Cibles* : `/register`, `/forgot-password`, reprise de l'action en attente (`pendingProtectedAction`), ou retour arrière.
* **Données utilisées** : `AuthService.signIn()`, `sessionProvider.notifier.loginSuccess()`.
* **États gérés** : Validation des formats de champs, spinner sur le bouton pendant la requête Firebase, messages d'erreurs d'identifiants incorrects.
* **Fonctionnalité précise** : Cette page sert à identifier le client pour déverrouiller ses fonctionnalités privées (commandes, adresses, favoris).
* **Question probable du prof** : *« Que devient le panier d'un visiteur quand il se connecte sur cet écran ? »*
  - **Réponse simple** : *« Le panier reste intact en mémoire dans le `CartNotifier`. L'utilisateur ne perd aucun article et peut finaliser directement sa commande une fois connecté. »*

---

### Fiche 8 : Écran d'Inscription (`RegisterScreen`)
* **Rôle de la page** : Permet la création d'un nouveau compte client dans Firebase Authentication.
* **Fichier** : `lib/feature/auth/register_screen.dart` (`RegisterScreen`).
* **Ce que l'utilisateur voit** : Formulaire complet : Nom complet, adresse email, mot de passe avec critères de sécurité, case à cocher des conditions générales d'utilisation (CGU) et bouton de validation.
* **Ce qu'il peut faire** : Remplir les champs, cocher les CGU, soumettre l'inscription.
* **Interactions et navigation** :
  - *Source* : Lien depuis `LoginScreen`.
  - *Cible* : Fermeture de l'écran après succès et connexion automatique.
* **Données utilisées** : `AuthService.signUp()`, mise à jour du `displayName`, enregistrement dans `sessionProvider`.
* **États gérés** : Mot de passe trop court, email déjà utilisé, case CGU non cochée.
* **Fonctionnalité précise** : Cette page sert à enrôler de nouveaux clients dans l'écosystème Dokan.
* **Question probable du prof** : *« Comment enregistrez-vous le nom complet puisque Firebase Auth ne demande que l'email et le mot de passe ? »*
  - **Réponse simple** : *« Juste après le `createUserWithEmailAndPassword`, nous récupérons le `User` créé et appelons `user.updateDisplayName(fullName)` pour associer son nom au compte. »*

---

### Fiche 9 : Écran Mot de Passe Oublié (`ForgotPasswordScreen`)
* **Rôle de la page** : Envoi d'un courriel officiel de réinitialisation sécurisée du mot de passe.
* **Fichier** : `lib/feature/auth/forgot_password_screen.dart` (`ForgotPasswordScreen`).
* **Ce que l'utilisateur voit** : Explication didactique, champ de saisie email, bouton d'envoi. Après envoi : vue de succès avec enveloppe verte invitant à consulter sa boîte mail.
* **Ce qu'il peut faire** : Saisir son email, demander le lien de réinitialisation, retourner à la connexion.
* **Interactions et navigation** :
  - *Source* : Lien depuis `LoginScreen`.
  - *Cible* : Retour vers `LoginScreen`.
* **Données utilisées** : `AuthService.sendPasswordResetEmail(email)`.
* **États gérés** : Format email invalide, confirmation neutre de sécurité.
* **Fonctionnalité précise** : Cette page sert à restaurer l'accès au compte sans intervention humaine du support.
* **Question probable du prof** : *« Que se passe-t-il si je tape une adresse email qui n'existe pas dans votre base ? »*
  - **Réponse simple** : *« L'application affiche tout de même l'écran de succès invitant à vérifier ses mails. C'est une recommandation de cybersécurité stricte appelée "confirmation neutre", qui empêche des pirates de tester des listes d'emails pour savoir qui possède un compte chez nous. »*

---

### Fiche 10 : Écran des Favoris (`FavoritesScreen`)
* **Rôle de la page** : Espace personnel regroupant les articles mis de côté par l'utilisateur.
* **Fichier** : `lib/feature/favorites/favorites_screen.dart` (`FavoritesScreen`).
* **Ce que l'utilisateur voit** :
  - *En mode Visiteur* : Écran d'avertissement avec cadenas et bouton « Se connecter ».
  - *En mode Client* : Grille des produits enregistrés avec possibilité de les retirer d'un clic sur le cœur rouge.
* **Ce qu'il peut faire** : Consulter ses coups de cœur, ouvrir la fiche produit, retirer un article.
* **Interactions et navigation** :
  - *Source* : Onglet 3 du `MainShell` (`/favorites`).
  - *Cibles* : `/login` (si invité), `/product/:id`.
* **Données utilisées** : `sessionProvider` (test `isGuest`), `favoritesProvider`.
* **États gérés** : Visiteur non connecté (accès bloqué conforme au cahier des charges), liste vide (`EmptyState` avec bouton vers catalogue).
* **Fonctionnalité précise** : Cette page sert de pense-bête d'achat pour inciter le client à concrétiser ses envies ultérieurement.
* **Question probable du prof** : *« Pourquoi bloquer l'accès aux favoris pour les visiteurs ? »*
  - **Réponse simple** : *« C'est une exigence formelle de notre cahier des charges : les favoris représentent une donnée personnelle persistante qui nécessite d'être rattachée à un compte client. »*

---

### Fiche 11 : Écran Panier (`CartScreen`)
* **Rôle de la page** : Gestion des articles sélectionnés, ajustement réactif des quantités, application de coupons Firestore en temps réel et calcul des montants.
* **Fichier** : `lib/feature/cart/cart_screen.dart` (`CartScreen`).
* **Ce que l'utilisateur voit** : Liste déroulante des articles avec photo, nom, option choisie, prix, sélecteur numérique de quantité (+/-), bouton poubelle avec annulation (Undo), section code promotionnel Firestore, récapitulatif `PriceSummary` (Sous-total, Remise coupon, Livraison estimée, Total TTC), et barre inférieure fixe avec bouton « Continuer la commande ».
* **Ce qu'il peut faire** : Ajuster les quantités (1 à 10), supprimer un article (avec possibilité d'annulation immédiate via le SnackBar *Undo*), saisir et valider un code promo Firestore (ex: `PROMO70`, `BIENVENUE10`), retirer un coupon appliqué, vider le panier en un clic, continuer vers la commande.
* **Interactions et navigation** :
  - *Source* : Onglet 4 du `MainShell` (`/cart`) ou ajout direct via le bouton `QuickAddButton` sur les cartes produits.
  - *Cibles* : `/checkout` (si client connecté), `AuthRequiredDialog` (si visiteur).
* **Données utilisées** : `cartProvider` (`CartNotifier`), collection Cloud Firestore `coupons`.
* **États gérés** : Panier vide (`EmptyState` invitant à découvrir les produits), panier garni, validation de coupon en cours (`isApplyingPromo`), message d'erreur de coupon (`promoError`), récapitulatif avec remise appliquée.
* **Fonctionnalité précise** : Cette page sert d'entonnoir d'achat (« checkout funnel ») pour préparer et vérifier son panier avant de finaliser la commande.
* **Question probable du prof** : *« Comment fonctionne la validation des codes promo dans le panier ? »*
  - **Réponse simple** : *« L'utilisateur saisit son code qui est interrogé directement dans la collection Firestore `coupons`. Le repository vérifie si le code est actif, non expiré, si le sous-total respecte le `minCartAmount`, si l'usage n'est pas dépassé (`oncePerUser`, `singleUse`, `totalLimit`), et si le code n'est pas restreint à une première commande. Si tout est valide, la réduction (% plafonné ou montant fixe) est appliquée instantanément au total. »*

---

### Fiche 12 : Écran de Passage de Commande (`CheckoutScreen`)
* **Rôle de la page** : Écran récapitulatif contractuel final pour choisir l'adresse et confirmer l'achat.
* **Fichier** : `lib/feature/checkout/checkout_screen.dart` (`CheckoutScreen`).
* **Ce que l'utilisateur voit** : Liste compacte des articles, carte d'adresse de livraison sélectionnée avec bouton « Modifier », choix du mode de livraison standard, mode de paiement à la livraison, récapitulatif financier et bouton « Confirmer la commande ».
* **Ce qu'il peut faire** : Sélectionner une autre adresse parmi celles enregistrées, en ajouter une nouvelle, appuyer sur confirmer.
* **Interactions et navigation** :
  - *Source* : Bouton continuer de `CartScreen`.
  - *Cibles* : `OrderConfirmationScreen` (`/order-confirmation/:id`), `/addresses/add`.
* **Données utilisées** : `cartProvider`, `addressesStreamProvider`, `ordersRepositoryProvider.createOrder()`.
* **États gérés** : Client non connecté (bloqué), aucune adresse sélectionnée, indicateur de chargement anti-double clic, capture des ruptures de stock (`ProductUnavailableException`).
* **Fonctionnalité précise** : Cette page sert à contractualiser la vente et à écrire le document de commande dans Firestore.
* **Question probable du prof** : *« Que se passe-t-il dans Firestore quand le client clique sur Confirmer ? »*
  - **Réponse simple** : *« Le repository relit d'abord les prix et la disponibilité des produits directement dans `products`. Si tout est valide, il crée le document dans `orders` avec un `WriteBatch` atomique et un horodatage serveur `serverTimestamp()`. Ensuite seulement, le panier local est vidé. »*

---

### Fiche 13 : Écran Confirmation de Commande (`OrderConfirmationScreen`)
* **Rôle de la page** : Affichage rassurant du succès de l'enregistrement de la commande.
* **Fichier** : `lib/feature/checkout/order_confirmation_screen.dart` (`OrderConfirmationScreen`).
* **Ce que l'utilisateur voit** : Grande coche verte animée avec effet d'échelle rebondissant, message « Commande enregistrée ! », numéro de commande lisible formaté (`DK-AAMMJJ-XXXX`), montant total, bouton « Suivre ma commande » et bouton « Retour à l'accueil ».
* **Ce qu'il peut faire** : Cliquer pour basculer sur le suivi en direct ou revenir faire des achats.
* **Interactions et navigation** :
  - *Source* : Redirection automatique depuis `CheckoutScreen`.
  - *Cibles* : `/orders/:id` (suivi) ou `/home`.
* **Données utilisées** : `singleOrderStreamProvider(orderId)`.
* **États gérés** : `PopScope` actif empêchant de revenir en arrière vers le panier vidé.
* **Fonctionnalité précise** : Cette page sert à rassurer le client sur la prise en compte de sa commande et lui fournir son numéro de suivi.
* **Question probable du prof** : *« Pourquoi interdire le bouton retour physique Android sur cet écran ? »*
  - **Réponse simple** : *« Parce que la commande a déjà été enregistrée dans Firestore et le panier a été vidé. Revenir en arrière réafficherait un formulaire vide ou risquerait de faire croire au client que sa commande a été annulée. »*

---

### Fiche 14 : Écran « Mes Commandes » (`MyOrdersScreen`)
* **Rôle de la page** : Historique et tableau de bord en direct de l'ensemble des colis de l'utilisateur.
* **Fichier** : `lib/feature/orders/my_orders_screen.dart` (`MyOrdersScreen`).
* **Ce que l'utilisateur voit** : Barre de recherche par numéro ou par article, pastilles de filtrage par statut avec compteurs en direct `(N)`, cartes de commandes décorées d'un ruban diagonal incliné et d'une barre de progression à 4 jalons avec camion.
* **Ce qu'il peut faire** : Rechercher, filtrer par statut (En cours, Livrées, Annulées), toucher une carte pour voir les détails.
* **Interactions et navigation** :
  - *Source* : Profil client ou bouton depuis la confirmation.
  - *Cibles* : `/orders/:id`, `/login` (si invité).
* **Données utilisées** : `myOrdersStreamProvider` (`FirestoreOrdersRepository.watchMyOrders`).
* **États gérés** : Flux temps réel (`Stream`), chargement shimmer, aucune commande (`EmptyState`).
* **Fonctionnalité précise** : Cette page sert à suivre l'évolution de tous ses colis en temps réel sans rafraîchir.
* **Question probable du prof** : *« Pourquoi votre requête Firestore a-t-elle besoin d'un index composite ici ? »*
  - **Réponse simple** : *« Parce que nous combinons un filtre d'égalité sur l'utilisateur (`userId == uid`) avec un tri descendant sur la date (`createdAt DESC`). Firestore exige un index composite pour exécuter cette combinaison sans dégrader les performances. »*

---

### Fiche 15 : Écran Détail et Suivi de Commande (`OrderDetailScreen`)
* **Rôle de la page** : Suivi fin d'un colis avec chronologie détaillée des étapes et coordonnées du transporteur.
* **Fichier** : `lib/feature/orders/order_detail_screen.dart` (`OrderDetailScreen`).
* **Ce que l'utilisateur voit** : Numéro et date, carte du destinataire, timeline verticale horodatée, carte chauffeur avec bouton d'appel/copie si assigné, articles achetés avec prix payés à la commande, récapitulatif financier et bouton rouge d'annulation (si statut pending).
* **Ce qu'il peut faire** : Copier le numéro du livreur, annuler sa commande tant qu'elle est en attente, revenir à la liste.
* **Interactions et navigation** :
  - *Source* : Clic sur une carte dans `MyOrdersScreen`.
  - *Cibles* : Dialogue d'annulation, retour arrière.
* **Données utilisées** : `singleOrderStreamProvider(orderId)`, `cancelOrder()` via transaction Firestore.
* **États gérés** : Mise à jour en direct via WebSocket dès que l'Admin ou le Livreur avance le statut.
* **Fonctionnalité précise** : Cette page sert à offrir une traçabilité totale et transparente de l'acheminement du colis.
* **Question probable du prof** : *« Comment sécurisez-vous l'annulation pour éviter qu'un client annule un colis déjà expédié ? »*
  - **Réponse simple** : *« Nous utilisons une transaction Firestore (`runTransaction`) couplée à nos règles de sécurité `firestore.rules`. La base vérifie que le statut est encore strictement `pending` au millième de seconde où la requête est exécutée. »*

---

### Fiche 16 : Écran « Mes Adresses » (`AddressesScreen`)
* **Rôle de la page** : Carnet d'adresses personnel du client pour la gestion de ses lieux de livraison.
* **Fichier** : `lib/feature/address/addresses_screen.dart` (`AddressesScreen`).
* **Ce que l'utilisateur voit** : Liste des adresses avec badge « Par défaut » sur la première, nom du destinataire, adresse postale, numéro de téléphone, bouton « Modifier », icône de suppression et bouton flottant d'ajout (+).
* **Ce qu'il peut faire** : Ajouter une adresse, modifier une existante, en supprimer une, la sélectionner pour le checkout.
* **Interactions et navigation** :
  - *Source* : Profil ou feuille de choix d'adresse du checkout.
  - *Cibles* : `/addresses/add`, `/addresses/edit/:id`.
* **Données utilisées** : `addressesStreamProvider` écoutant `users/{uid}/addresses`.
* **États gérés** : Chargement, aucune adresse, suppression confirmée par dialogue.
* **Fonctionnalité précise** : Cette page sert à mémoriser ses adresses habituelles pour commander en un clic.
* **Question probable du prof** : *« Où sont stockées ces adresses dans Firebase ? »*
  - **Réponse simple** : *« Elles sont stockées dans une sous-collection Firestore : `users/{uid}/addresses`. Cela garantit que chaque client n'a accès qu'à ses propres adresses conformément à nos règles de sécurité. »*

---

### Fiche 17 : Écran Ajout / Modification d'Adresse (`AddEditAddressScreen`)
* **Rôle de la page** : Formulaire de saisie d'un nouveau point de livraison ou de mise à jour.
* **Fichier** : `lib/feature/address/add_edit_address_screen.dart` (`AddEditAddressScreen`).
* **Ce que l'utilisateur voit** : Champs : Nom du destinataire, Téléphone (8 chiffres tunisiens), Adresse, Ville, Zone/Délégation, Complément d'adresse, Instructions coursier, et case à cocher « Définir comme adresse par défaut ».
* **Ce qu'il peut faire** : Remplir le formulaire, cocher l'adresse par défaut, valider l'enregistrement.
* **Interactions et navigation** :
  - *Source* : `/addresses` ou `/checkout`.
  - *Cible* : Retour à l'écran appelant avec mise à jour immédiate.
* **Données utilisées** : `AddressesRepository.addAddress()` ou `updateAddress()`.
* **États gérés** : Validation des numéros de téléphone tunisiens via `Validators`, désactivation du bouton pendant l'enregistrement.
* **Fonctionnalité précise** : Cette page sert à qualifier précisément le point de contact physique pour le livreur.
* **Question probable du prof** : *« Comment gérez-vous l'adresse par défaut pour qu'il n'y en ait qu'une seule à la fois ? »*
  - **Réponse simple** : *« Lorsque le client coche "Par défaut", nous utilisons un lot `WriteBatch` dans le repository d'adresses qui réinitialise `isDefault: false` sur toutes ses anciennes adresses avant de passer la nouvelle à `isDefault: true`. »*

---

### Fiche 18 : Écran Profil Client / Visiteur (`ProfileScreen`)
* **Rôle de la page** : Centre de gestion du compte utilisateur, des préférences et de l'état de session.
* **Fichier** : `lib/feature/profile/profile_screen.dart` (`ProfileScreen`).
* **Ce que l'utilisateur voit** :
  - *En mode Visiteur* : Bannière invitant à se connecter, bouton de connexion/création, options d'aide et paramètres généraux.
  - *En mode Client* : Avatar avec initiales, nom complet et email, raccourcis vers « Mes commandes », « Mes adresses », « Mes favoris », bouton de test « Simuler session expirée » et bouton rouge de déconnexion.
* **Ce qu'il peut faire** : Accéder à ses commandes, gérer ses adresses, se déconnecter, tester l'expiration de session.
* **Interactions et navigation** :
  - *Source* : Onglet 5 du `MainShell` (`/profile`).
  - *Cibles* : `/login`, `/orders`, `/addresses`, `/favorites`.
* **Données utilisées** : `sessionProvider`, `AuthService.signOut()`.
* **États gérés** : Bascule immédiate entre vue Visiteur et vue Client sans rechargement.
* **Fonctionnalité précise** : Cette page sert de point d'ancrage pour administrer ses informations personnelles et se déconnecter.
* **Question probable du prof** : *« À quoi sert le bouton "Simuler session expirée" présent sur votre profil ? »*
  - **Réponse simple** : *« C'est un outil pédagogique que nous avons intégré pour démontrer devant vous ce qui se passe quand le jeton client expire : l'application repasse en mode visiteur avec un message clair, mais sans jamais effacer le panier en cours ! »*

---

### Fiche 19 : Passerelle de Contrôle d'Accès (`AuthGate`)
* **Rôle de la page** : Aiguillage réactif automatique entre l'accueil et la connexion selon l'état d'authentification natif Firebase.
* **Fichier** : `lib/feature/auth/auth_gate.dart` (`AuthGate`).
* **Ce que l'utilisateur voit** : Un indicateur de chargement très court pendant la vérification, puis affichage direct de `HomeScreen` si connecté ou `LoginScreen` si non connecté.
* **Ce qu'il peut faire** : Aucun contrôle direct ; composant purement architectural.
* **Interactions et navigation** :
  - Utilisé comme alternative déclarative ou composant de secours pour tester l'écoute de session en direct.
* **Données utilisées** : `FirebaseAuth.instance.authStateChanges()`.
* **États gérés** : `ConnectionState.waiting`, `hasData` (connecté), absence de données (déconnecté).
* **Fonctionnalité précise** : Ce composant sert d'aiguilleur déclaratif en écoutant directement le Stream natif du SDK Firebase Auth.
* **Question probable du prof** : *« Quelle est la différence entre AuthGate et votre sessionProvider Riverpod ? »*
  - **Réponse simple** : *« AuthGate est un widget Flutter classique basé sur un StreamBuilder Firebase pur. Dans Dokan, nous avons préféré centraliser l'état dans un `sessionProvider` Riverpod pour supporter le concept métier de "Visiteur invité" qui peut naviguer librement dans le catalogue sans être forcé de se connecter dès l'ouverture. »*
