# 05 — Système de Thème Isolé et Composants Visuels

Ce document explique l'architecture du design système de Dokan, la règle stricte d'isolation des couleurs, et le fonctionnement de chaque composant d'interface réutilisable.

---

## 1. Le Principe du Thème Isolé

L'une des contraintes d'architecture les plus fortes imposées sur ce projet est l'**interdiction formelle de coder des couleurs en dur dans les écrans** :
* Aucun fichier ne doit contenir `Color(0x...)` en dehors de `lib/core/theme/app_colors.dart`.
* Aucun fichier ne doit utiliser les couleurs par défaut du framework (`Colors.red`, `Colors.grey`, `Colors.white` ou même `Colors.transparent`).

### Pourquoi cette exigence ?
Dans une entreprise, l'identité visuelle d'une marque peut évoluer à tout moment (changement de charte graphique, rebranding, mode sombre).
Si les couleurs étaient disséminées dans les 48 fichiers du projet, un changement de couleur nécessiterait des jours de travail et créerait des régressions visuelles.
Avec notre architecture :
* Le propriétaire du projet peut modifier **l'intégralité de l'apparence de l'application en changeant uniquement `app_colors.dart`**.

### Comment changer les fondamentaux en quelques secondes :

1. **Changer la couleur principale** :
   Dans [`app_colors.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/core/theme/app_colors.dart), modifier simplement la valeur hexadécimale de `primary` (ex: passer de vert canard `0xFF1F7A7A` à un bleu royal `0xFF1A56DB`). Tous les boutons, indicateurs et icônes basculent instantanément.
2. **Changer la devise monétaire** :
   Dans [`app_config.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/core/config/app_config.dart), modifier `currencySymbol = '€'` ou `'\$'`. Toute l'application met à jour le formatage de ses prix.
3. **Changer la durée du splash screen** :
   Dans [`app_config.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/core/config/app_config.dart), modifier `splashDuration = Duration(seconds: 2)` ou `5`.

---

## 2. Inventaire des Composants Réutilisables (`lib/core/ui/`)

Ces composants sont des briques élémentaires réutilisables créées pour éviter la duplication de code (*principe DRY : Don't Repeat Yourself*).

### 1. `ProductCard` (`product_card.dart`)
* **Rôle** : Affiche un produit sous forme de carte verticale compacte.
* **Paramètres essentiels** :
  * `product` (`ProductUiModel`) : L'article à représenter.
  * `isFavorite` (`bool`) : État du cœur (plein en corail ou vide).
  * `onTap` (`VoidCallback`) : Action d'ouverture de la fiche détaillée.
  * `onFavoriteTap` (`VoidCallback`) : Action de bascule du favori.
* **Détail technique clé** : L'affichage du prix actuel et de l'ancien prix barré utilise un widget **`Wrap`** au lieu d'une `Row`. Sur les petits écrans de smartphones (largeur de carte < 160 dp), deux prix côte à côte risquaient de dépasser de 2 pixels et de provoquer une erreur visuelle Flutter (*RenderFlex overflow*). Le `Wrap` renvoie automatiquement le second prix à la ligne suivante si l'espace manque.

### 2. `ProductGrid` (`product_grid.dart`)
* **Rôle** : Organise les `ProductCard` en une grille fluide et gère le chargement infini.
* **Fonctionnement** :
  * Utilise un `LayoutBuilder` pour calculer la largeur disponible : si l'écran dépasse 700 dp (tablette ou paysage), il affiche 3 colonnes, sinon 2 colonnes.
  * Écoute le défilement via son `ScrollController` : quand l'utilisateur arrive à moins de 200 dp du bas de page, il déclenche le rappel `onLoadMore` pour charger les 6 produits suivants.
  * Intègre un indicateur de chargement rotatif dans un `SliverToBoxAdapter` en bas de grille pendant le chargement de la page suivante.

### 3. `LoadingState` (`loading_state.dart`)
* **Rôle** : Effet de chargement "squelette" (*Shimmer*).
* **Particularité** : Conçu sans aucun package externe pour minimiser les dépendances. Il s'appuie sur un `SingleTickerProviderStateMixin` animant un dégradé linéaire (`LinearGradient`) oscillant entre `AppColors.shimmerBase` et `AppColors.shimmerHigh`.

### 4. `EmptyState` (`empty_state.dart`) & `ErrorState` (`error_state.dart`)
* **Rôle** : Offrir une interface soignée lorsque les données font défaut.
* **Paramètres** : Icône vectorielle thémée, titre explicite, message réconfortant et bouton d'action contextuel (« Découvrir les produits » ou « Réessayer »).

### 5. `QuantitySelector` (`quantity_selector.dart`)
* **Rôle** : Bouton d'ajustement numérique avec protection des bornes.
* **Comportement** :
  * Le bouton `[-]` se désactive automatiquement si la quantité atteint `min` (par défaut 1).
  * Le bouton `[+]` se désactive automatiquement si la quantité atteint le stock maximal disponible (`max`).

### 6. `SortSheet` (`sort_sheet.dart`) & `FilterSheet` (`filter_sheet.dart`)
* **Rôle** : Panneaux modaux surgissant du bas de l'écran avec coins arrondis élégants (`AppDimens.radius24`).
* **Composants interactifs** :
  * `RangeSlider` : Curseur double pour restreindre la plage de prix entre 0 DT et 300 DT avec affichage des bulles d'étiquettes en temps réel.
  * `ChoiceChip` : Pastilles interactives permettant de sélectionner une catégorie.
  * `SwitchListTile` : Interrupteur moderne pour n'afficher que les articles immédiatement disponibles en stock.

### 7. `PriceSummary` (`price_summary.dart`)
* **Rôle** : Synthèse financière du panier d'achat.
* **Lignes calculées** :
  * Sous-total des articles.
  * Ligne verte dédiée à la remise si un code promotionnel est validé.
  * Frais de livraison (offerts à partir d'un seuil ou forfaitaires à 7,000 DT).
  * Montant total TTC mis en valeur en couleur primaire et typographie grasse.

### 8. `AuthRequiredDialog` (`auth_required_dialog.dart`)
* **Rôle** : Boîte de dialogue modale s'ouvrant quand un visiteur clique sur une action réservée aux membres.
* **Fonctionnement anti-cumul** :
  * Empêche l'empilement multiple de dialogues si l'utilisateur clique rapidement.
  * Enregistre la fonction de rappel souhaitée dans `SessionNotifier.pendingProtectedAction`.
  * Propose deux boutons bien distincts : « Se connecter » (bouton plein principal) et « Créer un compte » (bouton avec contour secondaire).

---

## 3. Règles d'Accessibilité et Design Responsive

L'application respecte les standards d'accessibilité mobile recommandés par Google et Material Design :

1. **Zones tactiles minimales (*Touch Targets*)** :
   Tous les boutons interactifs et icônes cliquables disposent d'une zone tactile d'au moins **48 × 48 dp** (`AppDimens.minTouchTarget`), ce qui facilite l'utilisation avec une seule main et pour les personnes ayant des difficultés motrices.
2. **Accessibilité vocale (*Semantics*)** :
   Chaque bouton icône est encapsulé dans un widget `Semantics` fournissant un libellé clair pour les lecteurs d'écran (ex. TalkBack sur Android) :
   * Exemple : `Semantics(label: 'Ajouter cet article à mes favoris', button: true, child: ...)`
3. **Infobulles (*Tooltips*)** :
   Tous les `IconButton` possèdent une propriété `tooltip` qui affiche un texte explicatif lors d'un appui long.
4. **Contraste typographique** :
   Les textes foncés (`AppColors.textPrimary` : `#1E2B2F`) sur fond clair chaud (`AppColors.background` : `#F7F5F0`) respectent un ratio de contraste supérieur à 4.5:1, conforme aux normes WCAG AA.
