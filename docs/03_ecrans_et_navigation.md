# 03 — Écrans, Navigation et Expérience Utilisateur

Ce document détaille le fonctionnement de la navigation dans l'application Dokan, la configuration de **GoRouter**, ainsi que le comportement exact de chaque écran selon le profil de l'utilisateur (Visiteur anonyme vs Client connecté).

---

## 1. Architecture de la Navigation avec GoRouter

L'application utilise la bibliothèque officielle **GoRouter** pour implémenter un routage déclaratif moderne.

### Le rôle de `StatefulShellRoute`

Dans une application e-commerce classique, il est très frustrant pour un utilisateur de faire défiler une liste d'articles, de cliquer sur l'onglet Panier pour vérifier un prix, puis de revenir sur l'onglet Accueil pour constater que la page est revenue tout en haut et a rechargé toutes les données.

Pour résoudre ce problème, Dokan utilise un **`StatefulShellRoute.indexedStack`** :
1. Chaque onglet de la barre de navigation inférieure constitue une **branche indépendante** (`StatefulShellBranch`).
2. Flutter conserve l'arborescence des widgets et les contrôleurs de défilement (`ScrollController`) de chaque onglet dans un `IndexedStack`.
3. Quand l'utilisateur bascule entre les onglets, la page inactive est simplement masquée (elle ne consomme pas de temps de calcul de rendu), mais son état mémoire et sa position de défilement restent intacts.

### Schéma des 5 branches de navigation :

```
                  +--------------------------------+
                  |           MainShell            |
                  | (Barre de navigation 5 onglets)|
                  +--------------------------------+
                                  |
    +--------------+--------------+--------------+--------------+
    |              |              |              |              |
    v              v              v              v              v
[Branche 0]    [Branche 1]    [Branche 2]    [Branche 3]    [Branche 4]
 Accueil       Catégories       Favoris        Panier         Profil
(/home)       (/categories)   (/favorites)    (/cart)       (/profile)
    |              |
    +--------------+---> Menant vers des sous-écrans empilés (push) :
                         - /catalog (avec paramètres ?category=...)
                         - /search
                         - /product/:id (Fiche détaillée)
                         - /login, /register, /forgot-password
```

---

## 2. Tableau comparatif : Comportement Visiteur vs Client Connecté

L'une des exigences fondamentales de Dokan est que l'interface s'adapte en temps réel selon que la personne utilise l'application en mode découverte (visiteur) ou avec un compte authentifié (client).

| Fonctionnalité | Visiteur non connecté | Client connecté |
| :--- | :--- | :--- |
| **Consulter l'Accueil** | Autorisé (parcours complet) | Autorisé (identique) |
| **Naviguer dans les Catégories** | Autorisé | Autorisé |
| **Rechercher et filtrer** | Autorisé | Autorisé |
| **Consulter une fiche produit** | Autorisé | Autorisé |
| **Cliquer sur le cœur Favori** | **Bloqué** : Ouvre un dialogue d'invitation avec mémorisation de l'action | **Autorisé** : Ajoute/retire immédiatement des favoris |
| **Onglet Favoris (Navigation)** | Affiche la vue « Connexion requise » avec boutons Connexion / Inscription | Affiche la grille réactive de ses favoris |
| **Ajouter un article au panier** | **Autorisé** : Panier local/temporaire conservé en mémoire | **Autorisé** : Panier client |
| **Passer la commande (Panier)** | **Bloqué** : Invite à la connexion puis reprend le flux | Affiche le SnackBar « *Fonctionnalité disponible prochainement* » |
| **Onglet Profil (Navigation)** | Affiche un écran de bienvenue avec boutons Connexion / Inscription | Affiche la carte d'identité client, ses options et la déconnexion |

---

## 3. Revue détaillée de chaque écran

### 1. SplashScreen (`/splash`)
* **Route** : `/splash` (route initiale au démarrage).
* **Affichage** : Fond clair, icône boutique teal, nom « Dokan », sous-titre et indicateur de chargement circulaire.
* **Fonctionnement** : Démarre une temporisation de **3 secondes** (définie dans `AppConfig.splashDuration`). À l'issue, il redirige automatiquement vers `/home`. En cas d'exception inattendue, il déconnecte la session par sécurité et redirige également vers l'accueil pour ne jamais bloquer l'utilisateur.

### 2. HomeScreen (`/home`)
* **Route** : `/home` (onglet 1).
* **Affichage** :
  1. *AppBar* avec logo et icône du panier avec badge d'articles.
  2. *Champ de recherche* sous forme de bouton tactile menant vers l'écran de recherche.
  3. *Carrousel de bannières* dégradées peintes en pur code avec pagination par points.
  4. *Raccourcis de catégories* avec icônes circulaires à défilement horizontal.
  5. *Trois carrousels horizontaux de produits* : « Nouveaux arrivages », « Promotions du moment », « Produits populaires ».
* **États gérés** : Chargement par boîtes de scintillement (shimmer), affichage des données réelles, et état d'erreur avec bouton de réessai.
* **Défilement** : Construit avec un unique `SingleChildScrollView` vertical et un padding inférieur dynamique pour garantir que la dernière section n'est jamais masquée par la barre de navigation.

### 3. CategoriesScreen (`/categories`)
* **Route** : `/categories` (onglet 2).
* **Affichage** : Liste verticale des 7 catégories de l'application (Électronique, Vêtements, Maison, etc.). Chaque élément présente une icône colorée, le nom de la catégorie, le nombre d'articles disponibles et une flèche d'accès.
* **Interaction** : Cliquer sur une catégorie ouvre le catalogue (`/catalog?category=...`) pré-filtré sur cette catégorie.

### 4. CatalogScreen (`/catalog`)
* **Route** : `/catalog` (accessible depuis l'accueil ou les catégories).
* **Affichage** :
  1. Barre d'outils supérieure indiquant le nombre d'articles correspondants, le bouton **Trier** et le bouton **Filtrer**.
  2. Rangée horizontale de puces actives (`InputChip`) permettant de supprimer un filtre d'un simple clic sur sa croix.
  3. Grille responsive d'articles avec chargement à l'approche de la fin de liste (pagination infinie simulée).
* **Conservation des filtres** : Le bouton Retour système ou de l'AppBar revient à la page précédente sans réinitialiser inutilement les filtres sélectionnés.

### 5. SearchScreen (`/search`)
* **Route** : `/search`.
* **Affichage** :
  * Champ de recherche textuel avec autofocus et bouton d'effacement rapide.
  * *État initial* : Liste des recherches récentes stockées en mémoire avec possibilité de suppression individuelle ou totale, suivie de suggestions de recherche populaires sous forme de puces cliquables.
  * *État résultats* : Grille des produits correspondants.
* **Technique clé** : Intègre un **Debounce de 400 millisecondes**. Si l'utilisateur tape « Robe », la recherche ne part pas à chaque frappe de lettre mais attend 400 ms de silence clavier, ce qui économise les ressources et évite les scintillements d'interface.

### 6. ProductDetailScreen (`/product/:id`)
* **Route** : `/product/:id` avec passage de l'identifiant dans l'URL.
* **Affichage** :
  1. Galerie d'images sous forme de `PageView` avec indicateurs de position par points.
  2. Catégorie et badge de disponibilité (En stock en vert, Stock limité en ambre, Épuisé en rouge).
  3. Titre complet du produit et note sur 5 étoiles avec nombre d'avis.
  4. Prix en dinars tunisiens avec prix d'origine barré et étiquette du pourcentage de remise.
  5. Variantes sélectionnables via des `ChoiceChip` (ex : Tailles, Couleurs).
  6. Sélecteur de quantité numérique.
  7. Description complète de l'article.
  8. *Barre d'action fixe en bas d'écran* : Bouton cœur et bouton large « Ajouter au panier ».

### 7. LoginScreen (`/login`), RegisterScreen (`/register`) & ForgotPasswordScreen (`/forgot-password`)
* **Routes** : Accessibles depuis le profil ou lorsqu'une action protégée le requiert.
* **Comportement rigoureux des formulaires** :
  * Validation immédiate des champs avant toute tentative d'envoi.
  * **Anti-double-clic** : Dès que l'utilisateur appuie sur le bouton de soumission, le bouton est automatiquement désactivé (`onPressed: null`) et son texte est remplacé par un indicateur de chargement circulaire miniature (`CircularProgressIndicator`).
  * En cas d'erreur (ex: identifiants incorrects), un encadré rouge thémé affiche l'explication sans perte de la saisie utilisateur.
  * À la réussite, la session est mise à jour et la page se ferme automatiquement via `Navigator.of(context).pop()`.

### 8. FavoritesScreen (`/favorites`)
* **Route** : `/favorites` (onglet 3).
* **Vue Visiteur** : Illustration de cadenas avec cœur, texte explicatif invitant à se connecter et deux boutons (« Se connecter », « Créer un compte »). Aucun article n'est exposé.
* **Vue Client** : Grille en temps réel des produits ajoutés aux favoris. Toucher l'icône cœur retire immédiatement l'article de la liste avec un message informatif (SnackBar).

### 9. CartScreen (`/cart`)
* **Route** : `/cart` (onglet 4).
* **Affichage** :
  * Liste des articles avec miniature, nom, variante choisie, prix unitaire, contrôle de quantité et bouton de suppression.
  * Option de suppression sécurisée avec possibilité d'annulation (*Undo*) : un SnackBar s'affiche pendant 4 secondes avec un bouton « Annuler » qui réinsère l'article exactement à son index d'origine.
  * Champ d'application de code promo avec validation (ex: `Dokan10` accorde 10 % de réduction).
  * Récapitulatif financier complet (`PriceSummary`).
  * Barre inférieure fixe avec le montant total à régler et le bouton « Continuer la commande ».

### 10. ProfileScreen (`/profile`)
* **Route** : `/profile` (onglet 5).
* **Vue Visiteur** : Écran d'accueil invitant à créer un compte ou se connecter.
* **Vue Client** :
  * Avatar avec initiales du client et coordonnées (nom complet, email).
  * Liens vers les rubriques hors périmètre (commandes, adresses, paramètres) qui affichent le SnackBar officiel.
  * Outil de test pédagogique « Simuler session expirée » pour vérifier le bon comportement de l'app si le jeton expire sans perdre le contenu de son panier.
  * Bouton de déconnexion ouvrant une boîte de dialogue de confirmation.
