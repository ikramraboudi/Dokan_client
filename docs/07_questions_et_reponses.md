# 07 — Foire Aux Questions Techniques (FAQ Étudiante)

Ce document rassemble les questions fondamentales qu'une étudiante ou un développeur junior se pose légitimement en découvrant ce projet, avec des explications simples, concrètes et ancrées dans notre code.

---

### Q1 : Pourquoi utiliser Riverpod plutôt que le simple `setState` ou le package `Provider` ?
* **Réponse** :
  * `setState` est confiné à un seul widget. Si l'on ajoute un produit au panier depuis `ProductDetailScreen`, `setState` ne peut pas prévenir le badge du panier situé dans `MainShell` sans faire passer des fonctions de rappel dans tout l'arbre de widgets (*prop drilling*), ce qui devient vite ingérable.
  * L'ancien package `Provider` dépendait du `BuildContext` de l'arbre visuel, ce qui provoquait de fréquentes erreurs au démarrage (`ProviderNotFoundException`).
  * **Riverpod** résout ces deux problèmes : il est totalement indépendant de l'arbre de widgets, vérifie la cohérence des types dès la compilation et permet de tester facilement chaque état en isolation.

---

### Q2 : Pourquoi avoir choisi `GoRouter` et `StatefulShellRoute` plutôt que le `Navigator.push` natif ?
* **Réponse** :
  Le `Navigator` classique traite la navigation comme une simple pile de cartes sans état persistant.
  Dans une application à 5 onglets, si l'on navigue de l'Accueil vers le Panier avec un `Navigator.push` classique, l'écran d'accueil est soit détruit, soit empilé de manière confuse.
  Avec `StatefulShellRoute`, chaque onglet conserve sa propre pile et sa position de défilement : l'utilisateur peut explorer les catégories, aller vérifier son panier et revenir exactement là où il s'était arrêté dans la liste des catégories sans aucun rechargement.

---

### Q3 : Pourquoi créer des interfaces abstraites (`Repositories`) au lieu d'appeler directement les données fictives ?
* **Réponse** :
  C'est le principe d'**inversion de dépendance** (le "D" des principes SOLID).
  Si nos écrans importaient directement `MockCatalogRepository`, le jour où l'équipe backend nous fournira les vraies URLs d'API, il faudrait modifier chaque écran, chaque bouton et chaque test.
  Grâce à l'interface abstraite `CatalogRepository`, les écrans ignorent totalement d'où viennent les données. Le jour de la mise en production, nous n'aurons qu'une seule ligne de code à changer dans notre provider pour basculer vers le serveur réel.

---

### Q4 : Pourquoi séparer l'état d'interface (UI State) et les données métier ?
* **Réponse** :
  Les données métier représentent la réalité brute (ex: un produit a un prix de 49.9 DT).
  L'état d'interface représente la façon dont l'écran vit l'instant présent (ex: le bouton est-il en train de charger ? la case à cocher des CGU est-elle cochée ? le dialogue de confirmation est-il ouvert ?).
  Mélanger les deux rend le code instable. En séparant l'état éphémère de l'écran dans un `StatefulWidget` et les données partagées dans un `StateNotifier`, l'application reste modulaire et simple à déboguer.

---

### Q5 : Pourquoi une seule fonction `formatPrice` et un seul fichier `app_colors.dart` ?
* **Réponse** :
  C'est le principe du **Single Source of Truth** (Source unique de vérité) :
  * Si la Tunisie décide d'afficher les prix avec deux décimales au lieu de trois, ou si l'application s'exporte en Europe (devise en `€`), il suffit de modifier 2 lignes dans `app_config.dart` au lieu de rechercher et remplacer manuellement des centaines d'occurrences dans 48 fichiers avec le risque d'en oublier.
  * Même logique pour les couleurs : le designer peut changer toute la palette en modifiant uniquement `app_colors.dart`.

---

### Q6 : Pourquoi le panier d'un visiteur est-il conservé après sa connexion ?
* **Réponse** :
  C'est une règle d'expérience utilisateur (UX) majeure en e-commerce.
  Si un visiteur passe 15 minutes à ajouter 4 articles dans son panier, clique sur « Commander » et que l'écran de connexion vide son panier, l'utilisateur sera frustré et abandonnera son achat.
  Dans notre code, `cartProvider` conserve sa liste d'articles en mémoire : l'authentification met à jour la session client sans réinitialiser le panier d'achat.

---

### Q7 : Comment fonctionne concrètement l'action protégée en attente (`pendingProtectedAction`) ?
* **Scénario pas à pas** :
  1. Le visiteur anonyme touche l'icône cœur sur une carte produit.
  2. L'application vérifie `session.isGuest` : c'est vrai, l'ajout est bloqué.
  3. L'action `() => toggleFavorite(product)` est stockée dans la variable `pendingProtectedAction` du `SessionNotifier`.
  4. La boîte de dialogue `AuthRequiredDialog` s'ouvre : l'utilisateur choisit « Se connecter ».
  5. Sur l'écran de connexion, le visiteur s'authentifie avec succès.
  6. La méthode `SessionNotifier.loginSuccess()` s'exécute : elle valide la session, détecte qu'une action était en attente, **exécute l'ajout aux favoris automatiquement**, puis efface l'action en attente pour éviter tout doublon.
  7. L'utilisateur revient sur l'accueil : son favori a bien été pris en compte en toute transparence !

---

### Q8 : Pourquoi un `debounce` dans la recherche et comment fonctionne-t-il ?
* **Réponse** :
  Sans debounce, si vous tapez le mot « Casque » (6 lettres), l'application enverrait 6 requêtes réseau successives (`C`, `Ca`, `Cas`, `Casq`, `Casqu`, `Casque`).
  Le debounce utilise un `Timer` de 400 millisecondes :
  * L'utilisateur tape « C » -> un compte à rebours de 400 ms commence.
  * Avant la fin des 400 ms, il tape « a » -> l'ancien minuteur est **annulé** et un nouveau compte à rebours de 400 ms redémarre.
  * Quand l'utilisateur s'arrête d'écrire pendant plus de 400 ms, le minuteur arrive à son terme et la recherche est enfin exécutée. Cela divise par 5 la charge serveur et fluidifie l'application.

---

### Q9 : Pourquoi désactiver les boutons pendant l'envoi d'un formulaire ?
* **Réponse** :
  Dans un formulaire de connexion ou de paiement, si la requête met 800 ms à répondre et que le bouton reste actif, un utilisateur impatient peut cliquer 3 ou 4 fois de suite.
  Cela risque d'envoyer plusieurs requêtes simultanées, de créer des doublons de commandes ou de provoquer des bugs de concurrence.
  En passant `onPressed: _isLoading ? null : _submit`, Flutter grise instantanément le bouton et ignore tout nouvel appui tactile jusqu'à la réponse.

---

### Q10 : Pourquoi `SingleChildScrollView + Column` sur l'accueil et quel était le problème de défilement initial ?
* **Réponse** :
  Initialement, l'écran d'accueil utilisait un `ListView` classique. Or, l'accueil contient des carrousels horizontaux (les bannières en `PageView` et les listes de produits en `ListView.horizontal`).
  Imbriquer un défilement horizontal dans un `ListView` vertical sans structure explicite créait des conflits de détection de gestes sur certains téléphones, bloquant le défilement vertical vers le bas.
  En remplaçant le corps par un `SingleChildScrollView(physics: AlwaysScrollableScrollPhysics())` contenant une `Column` et en ajoutant un padding inférieur calculé avec `MediaQuery.of(context).padding.bottom`, Flutter dispose d'un **contexte de défilement vertical unique et sans ambiguïté**, et le dernier produit n'est jamais masqué par la barre de navigation.

---

### Q11 : Que faudra-t-il modifier pour brancher une vraie API ?
* **Réponse** :
  Seulement 3 choses :
  1. Ajouter le package `dio` ou `http` dans `pubspec.yaml`.
  2. Écrire les classes réelles (ex: `ApiCatalogRepository`) qui effectuent les appels réseau `http.get('https://api.Dokan.com/products')` et convertissent le JSON en objets `ProductUiModel`.
  3. Dans les providers Riverpod, remplacer `return MockCatalogRepository()` par `return ApiCatalogRepository()`.
  L'interface visuelle (les 48 fichiers de widgets) n'aura pas besoin de la moindre modification.

---

### Q12 : Comment ajouter un nouvel écran dans l'application ?
* **Réponse** :
  1. Créer le widget dans `lib/feature/mon_dossier/mon_ecran.dart`.
  2. Déclarer la route dans `lib/core/navigation/routes.dart` (ex: `static const String aide = '/aide';`).
  3. Ajouter la route dans `lib/core/navigation/app_router.dart` :
     ```dart
     GoRoute(
       path: AppRoutes.aide,
       builder: (context, state) => const MonEcran(),
     ),
     ```
  4. Naviguer vers l'écran depuis un bouton avec `context.push(AppRoutes.aide)`.

---

### Q13 : Comment ajouter une 8ème catégorie de produits ?
* **Réponse** :
  Dans [`mock_catalog_repository.dart`](file:///c:/3%20eme/proj_flutter/e-commerce/client/Dokan_client/lib/data/mock/mock_catalog_repository.dart), ajouter simplement un élément dans la liste `_categories` :
  ```dart
  CategoryUiModel(
    id: 'cat_8',
    name: 'Bricolage & Jardin',
    icon: Icons.hardware_rounded,
    productCount: 12,
  ),
  ```
  L'écran d'accueil et la liste des catégories mettront immédiatement à jour leur affichage sans aucune autre manipulation.

---

### Q14 : Que signifie le mot-clé `mounted` utilisé après les `await` ?
* **Réponse** :
  Dans un `StatefulWidget`, lorsqu'une opération asynchrone prend du temps (`await Future.delayed(...)`), l'utilisateur a pu quitter l'écran entre-temps.
  Si le code tente d'appeler `setState()` ou `Navigator.of(context)` sur un écran qui a déjà été détruit, Flutter lève une exception critique (*setState called after dispose*).
  La vérification `if (mounted)` s'assure que le widget est toujours présent et actif à l'écran avant de mettre à jour son interface.

---

### Q15 : Pourquoi utiliser des constructeurs privés `NomClasse._()` sur `AppColors` et `AppConfig` ?
* **Réponse** :
  Ces classes ne contiennent que des méthodes et des constantes statiques. Elles ne doivent jamais être instanciées sous forme d'objets (écrire `var c = AppColors();` n'a aucun sens).
  Le constructeur privé `AppColors._()` empêche tout développeur d'instancier la classe par inadvertance.

---

### Q16 : À quoi sert le widget `SafeArea` ?
* **Réponse** :
  Les smartphones modernes possèdent des particularités physiques : encoche pour la caméra en haut (*notch*), coins d'écrans très arrondis ou barre de geste tactile Android en bas.
  `SafeArea` calcule automatiquement ces marges d'exclusion matérielles et décale le contenu visuel pour qu'aucun bouton ou texte ne soit rogné par l'écran physique.

---

### Q17 : Qu'est-ce qu'un `TextEditingController` et pourquoi faut-il obligatoirement appeler `dispose()` ?
* **Réponse** :
  Un `TextEditingController` est un objet qui écoute et modifie le texte saisi dans un champ `TextField`.
  Comme il enregistre des écouteurs au niveau du moteur natif, s'il n'est pas détruit lorsque l'écran se ferme, il continue de consommer de la mémoire vive inutilement (*fuite de mémoire* ou *memory leak*). La méthode `dispose()` libère proprement cette ressource.

---

### Q18 : Pourquoi avoir utilisé `ref.invalidate()` dans le geste "Pull-to-refresh" ?
* **Réponse** :
  Dans l'accueil, quand l'utilisateur tire l'écran vers le bas pour rafraîchir, nous appelons `ref.invalidate(homeCategoriesProvider)`.
  Cette méthode indique à Riverpod que les données en cache sont considérées comme périmées : Riverpod détruit l'ancien résultat et relance automatiquement le chargement asynchrone, rechargeant ainsi les données fraîches depuis le repository.
