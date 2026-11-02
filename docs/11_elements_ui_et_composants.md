# 11 — Inventaire des Composants UI et Éléments Visuels (Dokan Client)

> **Guide de soutenance : « Avec quoi est fait chaque élément ? »**  
> Ce document fournit un tableau de référence exhaustif pour chaque composant et chaque écran de l'application Dokan. Il indique le widget Flutter exact, son emplacement dans le code, la raison de son choix et la phrase simple à énoncer au professeur.

---

## 1. Composants Transverses Réutilisables (`lib/core/ui/` et `core/navigation/`)

| Élément à l'écran | Widget / technique Flutter utilisé | Fichier : classe / fonction (lignes approx.) | Pourquoi ce choix | Phrase simple pour l'expliquer au prof |
|---|---|---|---|---|
| **Barre de navigation inférieure à 5 onglets** | `NavigationBar` (Material 3) piloté par `StatefulNavigationShell` | `lib/core/navigation/main_shell.dart` → `MainShell.build()` (lignes 72-146) | Conserve l'état de chaque onglet en mémoire sans recharger la page lors des allers-retours | « Nous utilisons le `NavigationBar` de Material 3 couplé au `StatefulShellRoute` de GoRouter pour mémoriser le défilement de chaque onglet. » |
| **Badge numérique sur le panier** | `Badge` (Material 3) superposé sur `Icon` | `lib/core/navigation/main_shell.dart` → destination panier (lignes 106-134) | Affiche le nombre d'articles en direct sans encombrer la barre | « C'est un widget `Badge` natif Flutter alimenté par un `StateProvider<int>` qui s'incrémente automatiquement à chaque ajout. » |
| **Barre du haut uniforme** | `AppBar` personnalisé (`PreferredSizeWidget`) | `lib/core/ui/app_top_bar.dart` → `AppTopBar` (lignes 20-75) | Standardise la hauteur (56 dp), les boutons retour et les icônes d'action | « C'est un composant sur-mesure implémentant `PreferredSizeWidget` pour garantir le même alignement et les mêmes marges sur tous nos écrans. » |
| **Champs de formulaire stylisés** | `TextFormField` avec `InputDecoration` isolée | `lib/core/ui/app_form_field.dart` → `AppFormField` (lignes 25-110) | Centralise les bordures arrondies, la gestion du focus et les messages d'erreur | « Nous avons encapsulé `TextFormField` dans `AppFormField` pour appliquer automatiquement notre palette de couleurs et nos règles de validation. » |
| **Logo Dokan dynamique** | `CustomPaint` / `Container` avec dégradé et ombre | `lib/core/ui/dokan_logo.dart` → `DokanLogo` (lignes 20-83) | Permet d'afficher le logo sous 3 tailles (small, medium, large) avec ou sans texte | « C'est un widget modulaire qui adapte sa typographie et ses rayons de courbure selon qu'il est affiché sur le splash ou dans la barre du haut. » |
| **Dialogue de connexion requise** | `showModalBottomSheet` avec `PopScope` | `lib/core/ui/auth_required_dialog.dart` → `AuthRequiredDialog.show()` (lignes 58-120) | Présente une feuille ergonomique par le bas avec mémorisation de l'action (`pendingAction`) | « C'est une feuille modale inférieure qui enregistre la fonction que le visiteur souhaitait exécuter pour la rejouer après sa connexion. » |
| **Sélecteur de quantité (+ / -)** | `Row` avec deux conteneurs tactiles `InkWell` et un texte central | `lib/core/ui/quantity_selector.dart` → `QuantitySelector` (lignes 25-90) | Permet un contrôle strict des bornes minimum (1) et maximum sans saisie clavier | « C'est un widget personnalisé composé de boutons tactiles `InkWell` qui désactive visuellement le bouton moins dès que la quantité atteint 1. » |
| **Carte produit individuelle** | `Container` avec `BoxDecoration`, `ClipRRect`, `Wrap` et `InkWell` | `lib/core/ui/product_card.dart` → `ProductCard` (lignes 60-140) | Structure la photo, le badge promo, le cœur interactif et le prix avec repli anti-débordement | « La carte utilise un `Wrap` sur les prix pour que l'ancien prix barré passe proprement à la ligne sur les petits téléphones sans provoquer d'erreur jaune et noire. » |
| **Grille responsive et pagination infinie** | `LayoutBuilder`, `CustomScrollView`, `SliverGrid` et `ScrollController` | `lib/core/ui/product_grid.dart` → `ProductGrid` (lignes 70-160) | Bascule automatiquement de 2 colonnes (smartphone) à 3 colonnes (tablette > 700 dp) | « Nous utilisons un `LayoutBuilder` qui mesure la largeur disponible et un écouteur sur le `ScrollController` pour charger la suite à 200 pixels du bas. » |
| **Feuille de filtrage par prix et stock** | `showModalBottomSheet` avec `RangeSlider` et `FilterChip` | `lib/core/ui/filter_sheet.dart` → `FilterSheet` (lignes 35-180) | Offre une expérience tactile pour filtrer sans quitter la vue des résultats | « C'est un `RangeSlider` couplé à des `FilterChip` Material 3 qui transmettent les critères sous forme d'un objet immuable `ProductFilterCriteria`. » |
| **Feuille de tri (Prix, Nouveautés)** | `showModalBottomSheet` avec `RadioListTile` | `lib/core/ui/sort_sheet.dart` → `SortSheet` (lignes 25-100) | Permet un choix exclusif rapide parmi 4 critères de tri | « Nous utilisons des `RadioListTile` regroupés dans une feuille modale pour sélectionner le critère de tri actif. » |
| **État vide (Aucun favori / Panier vide)** | `Column` centrée avec icône douce, titre et bouton d'action | `lib/core/ui/empty_state.dart` → `EmptyState` (lignes 20-75) | Évite de laisser un écran blanc déroutant pour l'utilisateur | « C'est un composant d'état vide qui guide l'utilisateur vers le catalogue via un bouton d'action contextuel. » |
| **État d'erreur avec relance** | `Column` avec `Icons.error_outline_rounded` et bouton « Réessayer » | `lib/core/ui/error_state.dart` → `ErrorState` (lignes 20-70) | Affiche le problème réseau et permet de ré-exécuter la requête sans fermer l'app | « C'est un widget qui capte les exceptions et propose un bouton appelant `ref.refresh()` pour relancer le provider. » |
| **Indicateur de chargement / Skeleton** | `CircularProgressIndicator` ou conteneurs grisés | `lib/core/ui/loading_state.dart` → `LoadingState` (lignes 20-55) | Informe que la requête réseau Firestore est en cours d'exécution | « C'est un indicateur de chargement circulaire centré utilisant la couleur primaire de notre thème. » |
| **Récapitulatif financier du panier/checkout** | `Container` avec `Column` et lignes `Row` (Sous-total, Remise, Frais, Total) | `lib/core/ui/price_summary.dart` → `PriceSummary` (lignes 30-140) | Met en valeur la remise en vert négatif et le total final en grand et gras | « C'est un bloc réutilisable dans le panier et le passage de commande pour assurer une cohérence stricte des calculs financiers. » |

---

## 2. Écran d'Ouverture et Splash Screen (`lib/feature/splash/`)

| Élément à l'écran | Widget / technique Flutter utilisé | Fichier : classe / fonction (lignes approx.) | Pourquoi ce choix | Phrase simple pour l'expliquer au prof |
|---|---|---|---|---|
| **Animation d'apparition du logo** | `ScaleTransition` et `FadeTransition` couplés à un `CurvedAnimation` | `lib/feature/splash/splash_screen.dart` (lignes 180-230) | Crée un effet de zoom progressif élégant à l'ouverture | « Nous avons synchronisé deux transitions (échelle et opacité) sur un seul `AnimationController` de 2000 ms avec une courbe `easeOutBack`. » |
| **Apparition lettre par lettre du nom Dokan** | `Row` de `FadeTransition` échelonnées par intervalles temporels | `lib/feature/splash/splash_screen.dart` (lignes 230-260) | Donne un rythme visuel premium lors du dévoilement de la marque | « Chaque lettre du nom possède son propre contrôleur d'opacité décalé dans le temps via `Interval(0.2, 0.6)`. » |
| **Particules lumineuses d'ambiance** | `Stack` avec `Positioned`, `Container` circulaires flous et `Opacity` | `lib/feature/splash/splash_screen.dart` (lignes 540-580) | Évite la monotonie d'un fond plat unicolore | « Nous avons superposé des cercles semi-transparents avec différents rayons pour créer un arrière-plan moderne en profondeur. » |
| **Bouton « Passer » (Skip)** | `TextButton` avec icône `Icons.skip_next_rounded` | `lib/feature/splash/splash_screen.dart` (lignes 480-510) | Respecte les directives d'accessibilité pour ne pas bloquer l'utilisateur pressé | « C'est un bouton `TextButton` en haut à droite qui interrompt l'animation dès que la session Firebase est prête. » |
| **Transition fluide vers l'accueil** | `CustomTransitionPage` avec fondu et zoom (`FadeTransition` + `ScaleTransition`) | `lib/core/navigation/app_router.dart` (lignes 48-65) | Supprime la coupure brutale entre le splash sombre et l'accueil clair | « Nous avons configuré une transition personnalisée dans GoRouter qui fond l'écran de démarrage dans la page d'accueil en 500 millisecondes. » |

---

## 3. Écran d'Accueil (`lib/feature/home/`)

| Élément à l'écran | Widget / technique Flutter utilisé | Fichier : classe / fonction (lignes approx.) | Pourquoi ce choix | Phrase simple pour l'expliquer au prof |
|---|---|---|---|---|
| **Carrousel de bannières publicitaires** | `PageView.builder` couplé à un `PageController` | `lib/feature/home/home_screen.dart` → `_buildBannerCarousel()` (lignes 160-230) | Permet un défilement horizontal fluide au doigt entre les annonces | « C'est un `PageView.builder` avec défilement horizontal dont l'indice de page met à jour les points de pagination. » |
| **Indicateurs de page du carrousel** | `Row` de petits `AnimatedContainer` | `lib/feature/home/home_screen.dart` (lignes 220-245) | Indique visuellement la bannière courante (barre allongée pour l'active) | « Ce sont des `AnimatedContainer` qui s'élargissent de 6 à 20 pixels avec animation pour montrer la bannière active. » |
| **Boutons ronds des catégories** | `ListView.separated` à défilement horizontal (`Axis.horizontal`) | `lib/feature/home/home_screen.dart` → `_buildCategoriesSection()` (lignes 250-310) | Offre un accès rapide aux univers produits sans prendre de hauteur | « C'est une liste horizontale avec des conteneurs circulaires `InkWell` qui redirigent vers le catalogue filtré sur la catégorie choisie. » |
| **Sections de produits défilantes** | `ListView.builder` horizontal imbriqué dans une `Column` | `lib/feature/home/home_screen.dart` → `_buildProductSection()` (lignes 320-380) | Met en avant les promotions, les nouveaux arrivages et les articles populaires | « Chaque section est une `ListView` horizontale recyclant des cartes `ProductCard` pour limiter la consommation mémoire. » |
| **Rafraîchissement par tirage (Pull-to-refresh)** | `RefreshIndicator` enveloppant le `SingleChildScrollView` | `lib/feature/home/home_screen.dart` (lignes 110-140) | Permet au client de recharger manuellement les données en glissant vers le bas | « Le `RefreshIndicator` appelle `ref.refresh()` sur tous les providers de l'accueil pour forcer la synchronisation avec Firestore. » |

---

## 4. Écran Catalogue et Recherche (`lib/feature/catalog/`)

| Élément à l'écran | Widget / technique Flutter utilisé | Fichier : classe / fonction (lignes approx.) | Pourquoi ce choix | Phrase simple pour l'expliquer au prof |
|---|---|---|---|---|
| **Barre de recherche avec temporisation (Debounce)** | `TextField` avec `prefixIcon`, `suffixIcon` et un `Timer` Dart | `lib/feature/catalog/search_screen.dart` (lignes 40-75) | Évite d'exécuter une requête réseau à chaque frappe de touche | « Nous utilisons un `Timer` de 300 ms qui annule la requête précédente si l'utilisateur continue de taper, préservant ainsi les quotas Firestore. » |
| **Bouton d'effacement rapide du texte** | `IconButton(icon: Icon(Icons.clear))` conditionné par `text.isNotEmpty` | `lib/feature/catalog/search_screen.dart` (lignes 65-80) | Améliore l'ergonomie pour vider le champ en un seul clic | « Dès qu'un texte est saisi, une croix apparaît pour réinitialiser le champ et la liste des résultats. » |
| **Barre d'outils de tri et filtrage** | `Row` avec deux `OutlinedButton.icon` (Filtres avec pastille, Tri) | `lib/feature/catalog/catalog_screen.dart` (lignes 80-120) | Donne un accès immédiat aux options sans encombrer la grille | « Ces deux boutons déclenchent l'ouverture des feuilles modales `FilterSheet` et `SortSheet`. » |
| **Pastille de filtre actif** | `Container` circulaire coloré superposé sur l'icône de filtre | `lib/feature/catalog/catalog_screen.dart` (lignes 95-110) | Signale clairement à l'utilisateur qu'un filtre de prix ou de stock est actif | « Si des critères de filtrage sont sélectionnés, un point ambre s'affiche sur le bouton pour rappeler que la liste est restreinte. » |

---

## 5. Fiche Produit Détaillée (`lib/feature/product/`)

| Élément à l'écran | Widget / technique Flutter utilisé | Fichier : classe / fonction (lignes approx.) | Pourquoi ce choix | Phrase simple pour l'expliquer au prof |
|---|---|---|---|---|
| **Galerie photos du produit** | `PageView` avec `Image.network` et gestion des erreurs de chargement | `lib/feature/product/product_detail_screen.dart` → `_buildImageGallery()` (lignes 180-240) | Permet de faire défiler toutes les photos de l'article en plein écran | « C'est un `PageView` affichant chaque image du tableau `imageUrls` avec un placeholder gris si le lien est invalide. » |
| **Pastilles des variantes (Tailles / Couleurs)** | `Wrap` de `ChoiceChip` | `lib/feature/product/product_detail_screen.dart` → `_buildVariantsSection()` (lignes 310-360) | Sélection exclusive claire de la taille ou couleur | « Nous utilisons des `ChoiceChip` Material 3 qui passent en surbrillance primaire dès qu'une variante est choisie. » |
| **Barre d'action fixe en bas (Ajout au panier)** | `SafeArea` avec `Row` contenant le prix total et `ElevatedButton.icon` | `lib/feature/product/product_detail_screen.dart` (lignes 450-510) | Le bouton reste accessible en permanence même pendant le défilement du descriptif | « La barre est fixée en bas du `Scaffold` via `bottomNavigationBar` pour que le client puisse commander à tout moment. » |
| **Désactivation du bouton si rupture de stock** | `ElevatedButton` avec `onPressed: null` | `lib/feature/product/product_detail_screen.dart` (lignes 480-495) | Empêche techniquement la commande d'un article épuisé | « En passant `onPressed` à `null` quand `isInStock` est faux, Flutter grise automatiquement le bouton et bloque les clics. » |

---

## 6. Écran Panier (`lib/feature/cart/`)

| Élément à l'écran | Widget / technique Flutter utilisé | Fichier : classe / fonction (lignes approx.) | Pourquoi ce choix | Phrase simple pour l'expliquer au prof |
|---|---|---|---|---|
| **Suppression d'article avec geste de glissement** | `Dismissible` avec arrière-plan rouge et icône poubelle | `lib/feature/cart/cart_screen.dart` → `_buildCartItem()` (lignes 180-240) | Permet de supprimer rapidement un article par un glissement vers la gauche | « Le widget `Dismissible` permet la suppression gestuelle et déclenche un `SnackBar` avec bouton "Annuler" pour restaurer l'article en cas d'erreur. » |
| **Récapitulatif financier réactif** | `PriceSummary` (`Container`, `Column`, `Row`, `Divider`) | `lib/core/ui/price_summary.dart` (lignes 30-140) | Calcule et affiche en direct le sous-total, les frais de livraison et le total TTC | « Le composant `PriceSummary` calcule les montants à partir de `cartState` et applique la gratuité de livraison dès 150 DT. » |

---

## 7. Écran de Passage de Commande (`lib/feature/checkout/`)

| Élément à l'écran | Widget / technique Flutter utilisé | Fichier : classe / fonction (lignes approx.) | Pourquoi ce choix | Phrase simple pour l'expliquer au prof |
|---|---|---|---|---|
| **Sélecteur d'adresse sous forme de carte** | `Container` bordé avec `Radio` / icône maison et bouton « Modifier » | `lib/feature/checkout/checkout_screen.dart` (lignes 140-220) | Présente clairement l'adresse de destination et son numéro de téléphone | « C'est une carte visuelle affichant l'adresse par défaut issue de Firestore, avec un bouton ouvrant la liste complète de ses adresses. » |
| **Bouton de confirmation anti-double clic** | `ElevatedButton` affichant `CircularProgressIndicator` si `_isSubmitting` | `lib/feature/checkout/checkout_screen.dart` (lignes 520-560) | Verrouille l'interface pendant la relecture des prix et le `WriteBatch` Firestore | « Dès l'appui, la variable d'état `_isSubmitting` passe à `true`, ce qui désactive le bouton et affiche une roulette de chargement. » |
| **Retour haptique à la confirmation** | `HapticFeedback.lightImpact()` | `lib/feature/checkout/checkout_screen.dart` (ligne 682) | Procure une sensation physique de validation sous le doigt | « Nous déclenchons une courte vibration native de confirmation via les canaux système Flutter avant d'émettre la commande. » |

---

## 8. Écran de Confirmation (`lib/feature/checkout/order_confirmation_screen.dart`)

| Élément à l'écran | Widget / technique Flutter utilisé | Fichier : classe / fonction (lignes approx.) | Pourquoi ce choix | Phrase simple pour l'expliquer au prof |
|---|---|---|---|---|
| **Animation de rebond de la coche verte** | `TweenAnimationBuilder<double>` avec `Curves.easeOutBack` et `Transform.scale` | `lib/feature/checkout/order_confirmation_screen.dart` (lignes 75-108) | Récompense visuellement l'acte d'achat avec une sensation d'accomplissement | « Nous utilisons un `TweenAnimationBuilder` qui anime l'échelle du cercle vert de 0 à 1 en 600 ms avec un léger rebond élastique. » |
| **Interception de la touche retour physique** | `PopScope(canPop: false, onPopInvokedWithResult: ...)` | `lib/feature/checkout/order_confirmation_screen.dart` (lignes 36-43) | Empêche de revenir accidentellement sur le formulaire de commande validé | « Le widget `PopScope` bloque le retour arrière système et redirige automatiquement vers `/home`. » |

---

## 9. Écran « Mes Commandes » (`lib/feature/orders/my_orders_screen.dart`)

| Élément à l'écran | Widget / technique Flutter utilisé | Fichier : classe / fonction (lignes approx.) | Pourquoi ce choix | Phrase simple pour l'expliquer au prof |
|---|---|---|---|---|
| **Ruban diagonal de statut (Badge incliné)** | `Transform.rotate(angle: 0.785398)` dans un `Positioned` avec `ClipRRect` | `lib/feature/orders/my_orders_screen.dart` (lignes 707-730) | Reproduit l'aspect des étiquettes de colis postaux modernes | « Nous plaçons un conteneur incliné à 45 degrés dans le coin supérieur droit de la carte, découpé proprement par un `ClipRRect`. » |
| **Barre d'étapes à 4 jalons avec camion** | `Row` avec lignes pointillées et conteneur circulaire `Icon(Icons.local_shipping_rounded)` | `lib/feature/orders/my_orders_screen.dart` → `_OrderProgressBar` (lignes 737-830) | Permet de visualiser en un coup d'œil où en est le colis (0: Reçue, 1: Préparation, 2: Livraison, 3: Livrée) | « C'est un composant sur-mesure calculant l'étape active selon le statut pour illuminer les jalons et déplacer l'icône de camion. » |
| **Pastilles de filtrage avec compteurs** | `SingleChildScrollView` horizontal de `ChoiceChip` avec label contenant `(N)` | `lib/feature/orders/my_orders_screen.dart` (lignes 210-270) | Affiche le nombre exact de commandes pour chaque statut sans requête supplémentaire | « Ce sont des `ChoiceChip` horizontaux affichant par exemple "En livraison (2)", calculés localement sur la liste reçue du Stream. » |

---

## 10. Écran Détail et Suivi (`lib/feature/orders/order_detail_screen.dart`)

| Élément à l'écran | Widget / technique Flutter utilisé | Fichier : classe / fonction (lignes approx.) | Pourquoi ce choix | Phrase simple pour l'expliquer au prof |
|---|---|---|---|---|
| **Chronologie verticale (Timeline)** | `Column` alternant cercles numérotés et `Container` verticaux (barres de liaison) | `lib/feature/orders/order_detail_screen.dart` → `_buildTimelineCard()` (lignes 392-498) | Retrace l'historique d'acheminement certifié par Firestore (`statusHistory`) | « Nous parcourons la liste chronologique `statusHistory` pour dessiner une ligne continue reliant chaque étape horodatée. » |
| **Carte Livreur assigné** | `Container` avec avatar, nom, téléphone et bouton de copie | `lib/feature/orders/order_detail_screen.dart` → `_buildDriverCard()` (lignes 501-570) | Permet au client de joindre directement le coursier en tournée | « Dès que l'administrateur renseigne le livreur dans Firestore, cette carte apparaît avec un bouton copiant son numéro dans le presse-papiers (`Clipboard`). » |
| **Bouton d'annulation sous condition** | `OutlinedButton` rouge conditionné par `order.status == OrderStatus.pending` | `lib/feature/orders/order_detail_screen.dart` (lignes 220-235) | Empêche l'annulation si la commande est déjà en cours de préparation ou expédiée | « Le bouton n'apparaît que si la commande est encore "En attente" et déclenche une transaction Firestore atomique. » |
