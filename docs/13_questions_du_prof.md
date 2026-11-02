# 13 — Fiche de Révision pour la Soutenance Orale (40+ Questions du Professeur)

> **Guide de préparation intensive pour l'étudiante**  
> Ce document contient l'introduction chronométrée de 2 minutes du projet, le lexique des 15 termes techniques indispensables, ainsi que plus de 40 questions d'examen avec des réponses percutantes de 30 secondes citant systématiquement les fichiers et fonctions du code source.

---

## 1. Le Pitch de Présentation en 2 Minutes Chrono

> *« Bonjour Monsieur le Professeur. Je vous présente **Dokan**, une application mobile e-commerce moderne développée en **Flutter** et connectée à **Google Firebase**.*  
>  
> *L'application a été conçue selon une architecture modulaire **Feature-First** en couches : nous séparons strictement les écrans visuels dans `lib/feature/`, les composants partagés dans `lib/core/`, et la logique métier et d'accès aux données dans `lib/data/` via le patron de conception **Repository**.*  
>  
> *Pour la gestion d'état, nous avons choisi **Riverpod**, qui nous offre une immutabilité stricte et une réactivité sans faille sans avoir recours à des BuildContext complexes. La navigation est gérée par **GoRouter**, avec un `StatefulShellRoute` qui conserve l'état et la position de défilement de nos 5 onglets principaux.*  
>  
> *Côté backend, nous exploitons la puissance de **Firebase Authentication** pour sécuriser les comptes et de **Cloud Firestore** pour les données en temps réel :*  
> *1. Notre catalogue de produits est synchronisé en direct grâce aux `Stream` et `snapshots()` de Firestore.*  
> *2. Le flux de commande est entièrement sécurisé : au moment de valider le panier, l'application relit obligatoirement les prix et la disponibilité en stock directement dans la collection `products` avant d'exécuter une écriture atomique par lot (`WriteBatch`) dans la collection `orders` avec un horodatage certifié serveur (`serverTimestamp`).*  
> *3. Le client peut ensuite suivre son colis en temps réel grâce à une chronologie verticale alimentée par les mises à jour des applications Administrateur et Livreur, ou annuler sa commande tant qu'elle est en attente via une transaction atomique.*  
>  
> *Enfin, l'interface respecte scrupuleusement les standards **Material 3** avec une palette de couleurs centralisée et isolée dans `app_colors.dart`, sans aucune couleur écrite en dur. Je suis à votre disposition pour détailler n'importe quelle partie du code. »*

---

## 2. Les 15 Mots Techniques Indispensables

1. **Feature-First** : Organisation des dossiers par fonctionnalité métier (`lib/feature/cart`, `lib/feature/checkout`) plutôt que par type de fichier technique (`views/`, `controllers/`). Facilite la maintenance et l'évolutivité.
2. **StateNotifier / Notifier** : Classe Riverpod propriétaire d'un état immuable qui expose des méthodes de modification contrôlées (`CartNotifier` dans `lib/data/mock/mock_cart_repository.dart`).
3. **StatefulShellRoute** : Routeur avancé de GoRouter maintenant en mémoire l'arbre de widgets de chaque onglet actif dans un `IndexedStack` (`lib/core/navigation/app_router.dart`).
4. **Repository Pattern** : Couche d'abstraction séparant la source de données (Firestore, API REST ou Mock) de l'interface graphique (`FirestoreOrdersRepository` dans `lib/data/repositories/`).
5. **Snapshots (Stream Firestore)** : Flux d'événements continus émis par Firestore via WebSocket, avertissant l'app à chaque modification d'un document (`watchMyOrders()` dans `firestore_orders_repository.dart`).
6. **WriteBatch** : Opération Firestore permettant d'écrire ou modifier plusieurs documents de manière atomique (« tout réussit ou tout échoue ») (`createOrder()` dans `firestore_orders_repository.dart`).
7. **runTransaction** : Opération isolée garantissant qu'une relecture et une écriture s'exécutent sans conflit de concurrence (`cancelOrder()` dans `firestore_orders_repository.dart`).
8. **serverTimestamp** : Horodatage généré par les serveurs Google (`FieldValue.serverTimestamp()`), empêchant la triche sur l'heure locale du téléphone du client.
9. **Index Composite** : Structure de données Firestore combinant plusieurs champs (`userId` + `createdAt`) pour autoriser des requêtes avec filtre d'égalité et tri descendant (`firestore.indexes.json`).
10. **PopScope** : Widget Flutter contrôlant ou annulant le geste de retour arrière système d'Android (`OrderConfirmationScreen` dans `order_confirmation_screen.dart`).
11. **TweenAnimationBuilder** : Widget d'animation implicite interpolant une valeur entre un début et une fin sans nécessiter d'AnimationController lourd (`order_confirmation_screen.dart`).
12. **Debounce (Temporisation)** : Mécanisme retardant l'exécution d'une fonction avec un `Timer` pour attendre la fin de la saisie utilisateur (`MyOrdersScreen` et `SearchScreen`).
13. **Immutabilité** : Principe selon lequel un objet ne peut plus être altéré après sa création. Toute modification crée une nouvelle copie via `copyWith()` (`SessionState`).
14. **Snapshot de données (Copie figée)** : Enregistrement d'une copie intégrale des produits et de l'adresse au sein du document de commande pour figer les prix historiques payés.
15. **Unfocus** : Fermeture programmée du clavier virtuel pour libérer la vue (`FocusScope.of(context).unfocus()` dans `cart_screen.dart`).

---

## 3. Série 1 : Architecture & Bonnes Pratiques

#### Q1 : Pourquoi avoir choisi Riverpod plutôt que setState ou Provider classique ?
* **Réponse (30s)** : *« Riverpod élimine les défauts historiques de Provider : il ne dépend pas du BuildContext, ce qui permet de lire les états en dehors des widgets, notamment dans nos repositories. Il détecte les erreurs à la compilation plutôt qu'à l'exécution et prend en charge nativement le cycle de vie des requêtes asynchrones avec `AsyncValue` (loading, error, data). »*
* **Emplacement** : `lib/core/session/session_provider.dart` et `lib/data/mock/mock_cart_repository.dart`.

#### Q2 : Comment fonctionne votre navigation avec GoRouter et pourquoi un StatefulShellRoute ?
* **Réponse (30s)** : *« Un `ShellRoute` classique recharge l'écran à chaque clic d'onglet. Le `StatefulShellRoute` utilise un `IndexedStack` sous-jacent qui préserve l'état de chaque onglet en mémoire : si le client fait défiler le catalogue, va voir son panier puis revient sur le catalogue, il retrouve exactement sa position de défilement sans rechargement. »*
* **Emplacement** : `lib/core/navigation/app_router.dart` (lignes 70-110).

#### Q3 : Qu'apporte le patron de conception Repository dans votre projet ?
* **Réponse (30s)** : *« Le Repository isole totalement les widgets de la source physique des données. Nos écrans appellent l'interface abstraite `OrdersRepository`. Demain, si nous devons remplacer Firestore par une API Node.js ou Supabase, nous n'aurons qu'à changer l'implémentation du repository sans toucher à une seule ligne de nos fichiers d'interface. »*
* **Emplacement** : `lib/data/repositories/orders_repository.dart` et `firestore_orders_repository.dart`.

#### Q4 : Qu'est-ce que l'organisation Feature-First ?
* **Réponse (30s)** : *« Au lieu de regrouper tous les écrans ensemble et tous les modèles ensemble, nous regroupons par domaine métier : `feature/cart/`, `feature/checkout/`, `feature/orders/`. Cela permet à une équipe de travailler sur les commandes sans impacter le panier et facilite la suppression ou l'ajout d'une fonctionnalité complète. »*
* **Emplacement** : Structure du dossier `lib/feature/`.

#### Q5 : Pourquoi aucune couleur n'est écrite en dur dans vos écrans ?
* **Réponse (30s)** : *« Toutes nos couleurs proviennent exclusivement de constantes typées dans `lib/core/theme/app_colors.dart`. Cela garantit le respect rigoureux de notre charte graphique Material 3 et permettrait d'ajouter un mode sombre complet en modifiant un seul fichier de thème. »*
* **Emplacement** : `lib/core/theme/app_colors.dart`.

---

## 4. Série 2 : Firebase & Flux de Commande

#### Q6 : Comment est créée techniquement une commande dans Firestore ?
* **Réponse (30s)** : *« Dans `FirestoreOrdersRepository.createOrder()`, nous relisons d'abord chaque article dans la collection `products` pour valider le stock et le prix officiel. Nous calculons la remise, générons un numéro lisible `DK-AAMMJJ-XXXX`, puis nous enregistrons le document complet dans `orders/{orderId}` via un `WriteBatch` atomique avec `FieldValue.serverTimestamp()`. »*
* **Emplacement** : `lib/data/repositories/firestore_orders_repository.dart` (lignes 58-177).

#### Q7 : Pourquoi utiliser un WriteBatch pour créer la commande ?
* **Réponse (30s)** : *« Le `WriteBatch` garantit l'atomicité. Même si nous devions insérer la commande et mettre à jour un journal d'audit simultanément, le lot garantit que soit toutes les écritures réussissent ensemble sur les serveurs Google, soit aucune n'est appliquée, évitant ainsi des états corrompus en base. »*
* **Emplacement** : `lib/data/repositories/firestore_orders_repository.dart` (lignes 174-177).

#### Q8 : Pourquoi copiez-vous les articles et l'adresse dans la commande plutôt que de stocker seulement des identifiants (IDs) ?
* **Réponse (30s)** : *« C'est le principe fondamental du snapshot (copie figée) en e-commerce. Si un vendeur change le prix d'un produit le lendemain ou si le client modifie son adresse par la suite, la facture et la commande passée doivent impérativement conserver le prix exact payé et l'adresse physique de livraison du jour de la commande. »*
* **Emplacement** : `lib/data/repositories/firestore_orders_repository.dart` (lignes 105-120 et 160).

#### Q9 : Pourquoi relire les prix dans Firestore au moment de commander au lieu d'utiliser ceux du panier ?
* **Réponse (30s)** : *« Pour une raison de sécurité financière : on ne doit jamais faire confiance aveuglément aux données locales du téléphone client. L'utilisateur aurait pu garder un produit dans son panier pendant 3 semaines alors que le prix a augmenté, ou tenter de modifier le code client en mémoire. La relecture garantit que le montant facturé correspond à la base de données. »*
* **Emplacement** : `lib/data/repositories/firestore_orders_repository.dart` (lignes 80-104).

#### Q10 : Comment l'écran « Mes commandes » se met-il à jour tout seul quand l'Admin change le statut ?
* **Réponse (30s)** : *« L'écran écoute un `StreamProvider` qui appelle `.snapshots()` sur Firestore. Dès que l'application Admin écrit `status: "confirmed"` dans le document, Firestore envoie automatiquement un événement via WebSocket. Riverpod met à jour son état et Flutter reconstruit uniquement la carte de la commande concernée. »*
* **Emplacement** : `lib/data/repositories/firestore_orders_repository.dart` → `watchMyOrders()` (lignes 204-213).

#### Q11 : À quoi sert l'index composite et que se passe-t-il si vous ne le créez pas ?
* **Réponse (30s)** : *« Notre requête filtre par utilisateur avec `where('userId', isEqualTo: userId)` et trie par date avec `orderBy('createdAt', descending: true)`. Combiner une clause d'égalité et un tri distinct impose un index composite. Sans lui, Firebase rejette la requête avec une exception et l'écran affiche une erreur. »*
* **Emplacement** : `firestore.indexes.json`.

#### Q12 : Pourquoi utiliser `FieldValue.serverTimestamp()` plutôt que `DateTime.now()` côté téléphone ?
* **Réponse (30s)** : *« Parce que l'horloge du téléphone client peut être déréglée ou intentionnellement modifiée par l'utilisateur (par exemple pour contourner une promotion expirée). `FieldValue.serverTimestamp()` garantit une heure certifiée et infalsifiable fournie par les serveurs Google Cloud. »*
* **Emplacement** : `lib/data/repositories/firestore_orders_repository.dart` (lignes 166-167).

#### Q13 : Comment fonctionne l'annulation de commande et comment évitez-vous les conflits ?
* **Réponse (30s)** : *« Nous utilisons `_firestore.runTransaction`. La transaction relit le document avec un verrou : si le statut est encore `pending`, elle écrit `cancelled` et enregistre l'événement dans `statusHistory`. Si l'Admin a validé la commande une milliseconde plus tôt, le statut n'est plus `pending` et l'annulation est proprement rejetée. »*
* **Emplacement** : `lib/data/repositories/firestore_orders_repository.dart` → `cancelOrder()` (lignes 224-256).

#### Q14 : Que se passe-t-il si un produit n'existe plus ou est épuisé lors de la validation ?
* **Réponse (30s)** : *« Le repository lève une `ProductUnavailableException`. Le bloc `catch` du checkout l'intercepte, affiche un SnackBar d'erreur rouge explicite au client, déverrouille le bouton de commande et SURTOUT ne vide pas son panier pour qu'il puisse adapter son choix. »*
* **Emplacement** : `lib/feature/checkout/checkout_screen.dart` (lignes 717-724).

#### Q15 : Quand videz-vous exactement le panier d'achat ?
* **Réponse (30s)** : *« Exclusivement après le succès du `await batch.commit()`. Si la requête échoue à cause d'une panne réseau ou d'une erreur de carte, le panier reste plein pour ne pas infliger à l'utilisateur la corvée de recomposer ses achats. »*
* **Emplacement** : `lib/feature/checkout/checkout_screen.dart` (lignes 711-716).

---

## 5. Série 3 : Sécurité & Règles Firestore

#### Q16 : Comment les règles Firestore empêchent-elles un client de lire les commandes d'un autre ?
* **Réponse (30s)** : *« Dans `firestore.rules`, la règle sur `orders/{orderId}` impose : `allow read: if request.auth != null && resource.data.userId == request.auth.uid;`. Si le jeton d'authentification de la requête ne correspond pas exactement au champ `userId` stocké dans la commande, Firebase bloque l'accès à la racine. »*
* **Emplacement** : `firestore.rules` (lignes 30-34).

#### Q17 : Qu'est-ce qui empêche un utilisateur malveillant de créer une commande avec statut « delivered » ?
* **Réponse (30s)** : *« La règle de création `allow create` exige explicitement : `request.resource.data.status == 'pending'`. Toute tentative d'écrire directement un statut plus avancé est immédiatement rejetée avec une erreur de permission refusée. »*
* **Emplacement** : `firestore.rules` (lignes 36-41).

#### Q18 : Pourquoi la suppression d'une commande est-elle interdite ?
* **Réponse (30s)** : *« Nous avons fixé `allow delete: if false;`. Une commande constitue une pièce comptable légale qui ne doit jamais disparaître de la base. Si une commande doit être abandonnée, elle passe au statut `cancelled`, mais l'historique reste conservé pour la comptabilité. »*
* **Emplacement** : `firestore.rules` (lignes 56-58).

#### Q19 : Comment protégez-vous les adresses personnelles des clients ?
* **Réponse (30s)** : *« Chaque adresse est rangée dans une sous-collection propre à l'utilisateur : `users/{userId}/addresses/{addressId}`. La règle de sécurité exige `request.auth.uid == userId`, ce qui rend les adresses totalement invisibles pour les autres clients de la plateforme. »*
* **Emplacement** : `firestore.rules` (lignes 19-22).

#### Q20 : Quelle est la limite de sécurité actuelle sur le stock et comment la résoudre ?
* **Réponse (30s)** : *« Actuellement, l'app cliente vérifie le stock en lecture mais ne le décrémente pas, car donner le droit d'écriture sur `products` aux clients créerait une faille. La solution standard en production est d'utiliser une **Firebase Cloud Function** qui écoute la création d'une commande et décrémente le stock de manière sécurisée côté serveur. »*
* **Emplacement** : `lib/data/repositories/firestore_orders_repository.dart` (commentaire ligne 172).

---

## 6. Série 4 : Composants Visuels & Interface Flutter

#### Q21 : Comment avez-vous réalisé le ruban diagonal de statut sur les cartes de commande ?
* **Réponse (30s)** : *« C'est une composition astucieuse : nous utilisons un `Transform.rotate(angle: 0.785398)` (qui correspond à 45 degrés en radians) placé dans un widget `Positioned(top: 14, right: -28)`. La carte parente est entourée d'un `ClipRRect` qui rogne proprement les bords du ruban qui dépassent. »*
* **Emplacement** : `lib/feature/orders/my_orders_screen.dart` (lignes 707-730).

#### Q22 : Avec quoi est faite la barre de progression en 4 étapes avec le camion ?
* **Réponse (30s)** : *« C'est notre widget `_OrderProgressBar`. Il calcule l'étape courante via `status.progressStep` (0 à 3). Pour l'étape en cours, il affiche l'icône Material `Icons.local_shipping_rounded` dans un cercle coloré, relié aux autres jalons par des conteneurs simulant une ligne d'acheminement continue. »*
* **Emplacement** : `lib/feature/orders/my_orders_screen.dart` (lignes 737-830).

#### Q23 : Comment est construite la chronologie verticale (timeline) sur l'écran de détail ?
* **Réponse (30s)** : *« Nous itérons sur la liste `statusHistory` stockée dans la commande Firestore. Pour chaque événement, nous affichons un point d'étape avec date et heure formatées, et nous intercalons des conteneurs verticaux d'une largeur de 2 dp qui tracent la ligne continue reliant les étapes. »*
* **Emplacement** : `lib/feature/orders/order_detail_screen.dart` → `_buildTimelineCard()` (lignes 392-498).

#### Q24 : Comment est réalisée l'animation de la coche de confirmation de commande ?
* **Réponse (30s)** : *« Elle utilise un `TweenAnimationBuilder<double>` qui fait évoluer une valeur d'échelle de 0.0 à 1.0 en 600 millisecondes. Nous lui appliquons une courbe d'interpolation `Curves.easeOutBack`, ce qui donne un léger effet d'amorti et de rebond au cercle vert. »*
* **Emplacement** : `lib/feature/checkout/order_confirmation_screen.dart` (lignes 75-108).

#### Q25 : Pourquoi utilisez-vous un Wrap au lieu d'une Row pour les prix sur les cartes produits ?
* **Réponse (30s)** : *« Sur des petits écrans de téléphone (largeur de carte inférieure à 160 dp), deux prix côte à côte (prix promo + ancien prix barré) provoquaient un léger dépassement de 2 pixels ("A RenderFlex overflowed by 2 pixels"). Le widget `Wrap` renvoie automatiquement l'ancien prix à la ligne suivante en toute élégance sans lever d'erreur. »*
* **Emplacement** : `lib/core/ui/product_card.dart` (lignes 8-11 et 100-120).

#### Q26 : Comment rendez-vous la grille de produits responsive ?
* **Réponse (30s)** : *« Notre `ProductGrid` utilise un `LayoutBuilder`. Si la largeur de l'écran est supérieure à 700 pixels (cas d'une tablette), il configure le `crossAxisCount` du `SliverGrid` à 3 colonnes. Sur un smartphone standard, il reste automatiquement à 2 colonnes. »*
* **Emplacement** : `lib/core/ui/product_grid.dart` (lignes 75-95).

#### Q27 : Comment fermez-vous le clavier virtuel lors d'une action utilisateur ?
* **Réponse (30s)** : *« Nous appelons `FocusScope.of(context).unfocus()`. Cela retire le focus actif de l'élément de saisie et replie immédiatement le clavier virtuel Android pour dégager la vue sur l'interface. »*
* **Emplacement** : Dans les formulaires et dialogues de saisie.

---

## 7. Série 5 : État, Session & Panier

#### Q28 : Comment gérez-vous la différence entre un Visiteur et un Client connecté ?
* **Réponse (30s)** : *« Notre `SessionState` contient une propriété `user`. Si `user == null`, le getter calculé `isGuest` vaut vrai. Dès qu'un visiteur clique sur une action protégée comme le passage de commande ou les favoris, l'app intercepte l'action et ouvre le dialogue modal `AuthRequiredDialog`. »*
* **Emplacement** : `lib/core/session/session_provider.dart` (lignes 34-60).

#### Q29 : Comment fonctionne le mécanisme d'action protégée en attente (`pendingProtectedAction`) ?
* **Réponse (30s)** : *« Quand le visiteur clique sur commander, nous stockons le callback de navigation dans `sessionProvider.notifier.setPendingAction()`. Dès que sa connexion réussit, `loginSuccess()` exécute cette fonction sauvegardée et remet le pointeur à `null`. L'utilisateur se retrouve ainsi au checkout sans avoir à recliquer. »*
* **Emplacement** : `lib/core/session/session_provider.dart` (lignes 98-111).

#### Q30 : Comment le badge du panier dans la barre du bas se met-il à jour ?
* **Réponse (30s)** : *« Chaque fois que `CartNotifier` ajoute, retire ou modifie un article, il recalcule le nombre total d'unités physiques et met à jour le `cartCountProvider`. Le widget `MainShell` écoute ce provider et reconstruit instantanément le `Badge` Material 3 au-dessus de l'icône du panier. »*
* **Emplacement** : `lib/core/navigation/main_shell.dart` (lignes 25-30 et 106-134).

#### Q31 : Pourquoi le panier d'achat est-il stocké en mémoire locale plutôt que dans Firestore ?
* **Réponse (30s)** : *« Pour offrir une réactivité parfaite à 60 images par seconde : incrémenter ou décrémenter une quantité ne subit aucune latence réseau. Cela permet également aux simples visiteurs non connectés d'ajouter des articles avant même d'avoir créé un compte. »*
* **Emplacement** : `lib/data/mock/mock_cart_repository.dart`.

#### Q32 : Pourquoi les promotions ne sont-elles pas saisies dans l'application Client ?
* **Réponse (30s)** : *« Les promotions sont gérées exclusivement par l'application Admin pour des raisons de sécurité métier : le Client n'écrit jamais de code promo (il écrit `promoCode: null` et `discount: 0`). Si l'Admin applique une remise sur une commande, le Client l'affiche fidèlement en lecture seule dans l'écran de suivi de commande. »*
* **Emplacement** : `lib/data/repositories/firestore_orders_repository.dart` (lignes 130-170) et `lib/feature/orders/order_detail_screen.dart` (lignes 770-785).

#### Q33 : Comment le calcul des montants du panier fonctionne-t-il ?
* **Réponse (30s)** : *« Le panier calcule le sous-total en faisant la somme de `unitPrice * quantity` pour chaque article. Les frais de livraison sont forfaitaires à 7 DT et deviennent automatiquement gratuits (0 DT) dès que le panier atteint 150 DT. Le total TTC est simplement la somme du sous-total et de la livraison. »*
* **Emplacement** : `lib/data/mock/mock_cart_repository.dart` (`CartState.total` et `CartState.deliveryFee`).

---

## 8. Série 6 : Limites Actuelles & Perspectives d'Évolution

#### Q34 : Si l'utilisateur perd sa connexion Internet en pleine commande, que se passe-t-il ?
* **Réponse (30s)** : *« L'appel `batch.commit()` lève une exception de connectivité. L'erreur est capturée par notre bloc `catch`, qui affiche un SnackBar rouge explicatif. Le bouton de validation se réactive grâce au bloc `finally` et le panier d'achat reste entièrement préservé en mémoire. »*
* **Emplacement** : `lib/feature/checkout/checkout_screen.dart` (lignes 725-735).

#### Q35 : Quelles sont les améliorations possibles pour le passage à l'échelle (production) ?
* **Réponse (30s)** : *« Quatre axes majeurs : premièrement, déporter la gestion du stock et des codes promo sur des Cloud Functions Firebase sécurisées ; deuxièmement, synchroniser le panier en base pour le retrouver sur plusieurs appareils ; troisièmement, intégrer un module de paiement en ligne par carte bancaire (Stripe/Flouci) ; quatrièmement, envoyer des notifications push via Firebase Cloud Messaging pour avertir le client quand son colis passe en livraison. »*

#### Q36 : Pourquoi ne pas avoir implémenté de Cloud Functions dans ce projet étudiant ?
* **Réponse (30s)** : *« Parce que les Cloud Functions Firebase imposent la formule payante "Blaze" de Google Cloud avec une carte bancaire. Pour ce projet académique, nous avons privilégié la formule gratuite "Spark", tout en concevant nos repositories de façon modulaire pour brancher des Cloud Functions sans restructuration. »*

#### Q37 : Comment garantissez-vous que le numéro de commande `displayNumber` est unique ?
* **Réponse (30s)** : *« Notre générateur combine la date du jour `DK-AAMMJJ` avec 4 caractères aléatoires majuscules alphanumériques, offrant plus d'un million et demi de combinaisons par jour. En environnement de production à très fort volume, ce numéro serait attribué de manière séquentielle par un compteur transactionnel Firestore ou une Cloud Function. »*
* **Emplacement** : `lib/data/models/order_model.dart` → `generateDisplayNumber()`.

#### Q38 : Pourquoi l'écran de profil contient-il un bouton « Simuler session expirée » ?
* **Réponse (30s)** : *« C'est un scénario de test pédagogique intégré pour démontrer le comportement de notre `sessionProvider` : il force le passage en mode visiteur avec message d'avertissement tout en démontrant que le contenu du panier reste conservé en mémoire. »*
* **Emplacement** : `lib/feature/profile/profile_screen.dart` et `session_provider.dart`.

#### Q39 : Quel est le rôle de `WidgetsFlutterBinding.ensureInitialized()` dans le `main.dart` ?
* **Réponse (30s)** : *« `Firebase.initializeApp()` est une opération asynchrone qui communique avec les bibliothèques natives Android/iOS via des Platform Channels. Cette méthode garantit que le moteur graphique et le canal de communication natif de Flutter sont initialisés avant de lancer Firebase. »*
* **Emplacement** : `lib/main.dart` (ligne 35).

#### Q40 : Quel a été votre plus grand défi technique sur ce projet ?
* **Réponse (30s)** : *« Le plus grand défi a été de synchroniser le cycle de vie du flux de commande entre la gestion d'état locale Riverpod et le temps réel asynchrone de Firestore, tout en veillant à l'intégrité financière (relecture des prix, calcul exact de la livraison et écriture atomique WriteBatch) et à une ergonomie fluide sans blocage d'interface. »*
