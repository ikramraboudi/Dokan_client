# 09 — Flux de Commande Complet et Intégration Firebase (Dokan Client)

> **Document de référence pour la soutenance orale**  
> Ce document détaille l'intégralité du cycle de vie d'une commande dans l'application Dokan : depuis le clic sur « Continuer » dans le panier jusqu'au suivi en temps réel sur la carte et la timeline.

---

## 1. Schéma Général de Séquence (Flux de Commande)

Le schéma ci-dessous illustre le cheminement complet d'une commande à travers les couches de l'application :

```text
┌─────────────┐       ┌──────────────┐       ┌─────────────────┐       ┌────────────────────────┐       ┌──────────────────┐
│ Utilisateur │       │    Écran     │       │    Riverpod     │       │       Repository       │       │  Cloud Firestore │
│   (Client)  │       │ (UI Flutter) │       │ (StateNotifier) │       │ (Couche Données Métier)│       │    (Firebase)    │
└──────┬──────┘       └──────┬───────┘       └────────┬────────┘       └───────────┬────────────┘       └─────────┬────────┘
       │                     │                        │                            │                              │
       │ 1. Clic "Commander" │                        │                            │                              │
       │────────────────────>│                        │                            │                              │
       │                     │ 2. Vérifie session     │                            │                              │
       │                     │───────────────────────>│                            │                              │
       │                     │<───────────────────────│ (Client authentifié)       │                              │
       │                     │                        │                            │                              │
       │ 3. Navigation       │                        │                            │                              │
       │   vers Checkout     │                        │                            │                              │
       │────────────────────>│ 4. Écoute adresses     │                            │                              │
       │                     │────────────────────────────────────────────────────>│ 5. Stream users/{uid}/addr   │
       │                     │                        │                            │─────────────────────────────>│
       │                     │<────────────────────────────────────────────────────│<─────────────────────────────│
       │                     │                                                     │    (Liste adresses reçue)    │
       │ 6. Clic "Confirmer" │                                                     │                              │
       │────────────────────>│ 7. createOrder(...)                                 │                              │
       │                     │────────────────────────────────────────────────────>│                              │
       │                     │   (anti-double clic)   │                            │ 8. get() sur chaque produit  │
       │                     │                        │                            │─────────────────────────────>│
       │                     │                        │                            │<─────────────────────────────│
       │                     │                        │                            │    (Prix & stock vérifiés)   │
       │                     │                        │                            │                              │
       │                     │                        │                            │ 9. WriteBatch (atomique)     │
       │                     │                        │                            │    set(orders/{id}, data)    │
       │                     │                        │                            │─────────────────────────────>│
       │                     │                        │                            │<─────────────────────────────│
       │                     │                        │                            │       (Succès batch)         │
       │                     │ 10. clearCart()        │                            │                              │
       │                     │───────────────────────>│                            │                              │
       │                     │                        │ (Panier vidé en mémoire)   │                              │
       │                     │<───────────────────────│                            │                              │
       │                     │                        │                            │                              │
       │ 11. Redirection     │                        │                            │                              │
       │   OrderConfirmation │                        │                            │                              │
       │<────────────────────│                        │                            │                              │
       │                     │                        │                            │                              │
       │ 12. Écran           │ 13. watchMyOrders(uid) │                            │                              │
       │   "Mes commandes"   │────────────────────────────────────────────────────>│ 14. snapshots() temps réel    │
       │<────────────────────│                        │                            │─────────────────────────────>│
       │                     │<────────────────────────────────────────────────────│<─────────────────────────────│
       │                     │                                                     │ (Notification de statut)     │
```

---

## 2. Les 13 Étapes Détaillées du Flux de Commande

---

### Étape 1 : Clic sur « Continuer la commande » et vérification Visiteur vs Client

* **Ce que voit l'utilisateur** : Dans l'écran Panier (`/cart`), l'utilisateur consulte ses articles et appuie sur le bouton vert « Continuer la commande ».
* **Ce qui se passe dans le code** : Le widget vérifie l'état de la session utilisateur via `ref.read(sessionProvider)`. Si l'utilisateur est un visiteur (`session.isGuest == true`), une feuille modale `AuthRequiredDialog` s'ouvre pour lui demander de se connecter. Si l'utilisateur est déjà connecté, il est directement redirigé vers `/checkout`.
* **Où c'est dans le code** : `lib/feature/cart/cart_screen.dart` → méthode `_handleCheckout()` (≈ lignes 36-52).
* **Extrait de code réel** :
```dart
void _handleCheckout() {
  final session = ref.read(sessionProvider);
  if (session.isGuest) {
    // Visiteur : invite de connexion avec reprise automatique vers le passage de commande
    AuthRequiredDialog.show(
      context,
      ref,
      message: 'Connectez-vous pour continuer votre commande.',
      pendingAction: () {
        context.push(AppRoutes.checkout);
      },
    );
  } else {
    // Client connecté : transition vers le passage de commande
    context.push(AppRoutes.checkout);
  }
}
```
* **Explication ligne par ligne** :
  - Ligne 2 : `ref.read(sessionProvider)` lit l'état instantané de la session sans reconstruire le widget inutilement.
  - Ligne 3 : `if (session.isGuest)` vérifie si aucun compte n'est actuellement authentifié.
  - Lignes 4-12 : `AuthRequiredDialog.show` affiche la modale en passant un callback `pendingAction` qui contient la navigation vers `/checkout`.
  - Ligne 14 : Si l'utilisateur est authentifié, `context.push(AppRoutes.checkout)` ouvre directement l'écran de commande.
* **Pourquoi ce choix technique** : Permettre à un visiteur de constituer librement son panier sans barrière d'entrée, tout en exigeant une authentification stricte au moment de l'engagement contractuel.

---

### Étape 2 : Reprise automatique après connexion (Action protégée en attente)

* **Ce que voit l'utilisateur** : Le visiteur est redirigé vers l'écran de connexion (`/login`). Il saisit ses identifiants et appuie sur « Se connecter ». Dès la connexion réussie, la modale se ferme et il se retrouve automatiquement sur l'écran `/checkout` avec son panier intact.
* **Ce qui se passe dans le code** : Lors du succès de `AuthService.signIn()`, `SessionNotifier.loginSuccess()` récupère l'action mémorisée dans `state.pendingProtectedAction`, met à jour l'utilisateur connecté, réinitialise le pointeur d'action à `null` (pour éviter tout double déclenchement), puis exécute le callback sauvegardé.
* **Où c'est dans le code** :
  - `lib/core/session/session_provider.dart` → méthode `loginSuccess()` (≈ lignes 98-111).
  - `lib/feature/auth/login_screen.dart` → méthode `_handleLogin()` (≈ lignes 50-79).
* **Extrait de code réel** :
```dart
void loginSuccess(UserSummary user) {
  final pending = state.pendingProtectedAction;
  state = state.copyWith(
    user: () => user,
    isLoading: false,
    authError: () => null,
    pendingProtectedAction: () => null,
  );

  // Reprise sécurisée de l'action protégée sans doublon
  if (pending != null) {
    pending();
  }
}
```
* **Explication ligne par ligne** :
  - Ligne 2 : Sauvegarde temporaire du callback en mémoire avant mutation de l'état.
  - Lignes 3-8 : Création d'une nouvelle instance immuable de `SessionState` avec le profil utilisateur et `pendingProtectedAction` remis à `null`.
  - Lignes 11-13 : Exécution du callback `pending()`, ce qui déclenche la navigation immédiate vers le checkout.
* **Pourquoi ce choix technique** : Ce modèle évite la frustration de l'utilisateur qui, après s'être connecté, devrait retrouver et recliquer manuellement sur le bouton de commande.

---

### Étape 3 : Écran de passage de commande (Checkout)

* **Ce que voit l'utilisateur** : L'écran `/checkout` présente 4 sections claires :
  1. *Articles commandés* : liste compacte des produits du panier avec miniatures, quantités et prix.
  2. *Adresse de livraison* : carte avec le nom du destinataire, la ville, le numéro de téléphone et un bouton « Modifier ».
  3. *Mode de livraison & Paiement* : Livraison standard (7.000 DT ou offerte) et Paiement en espèces à la livraison (« Cash on delivery »).
  4. *Récapitulatif financier* : sous-total, frais de livraison et total à payer.
* **Ce qui se passe dans le code** : Le widget `CheckoutScreen` (ConsumerStatefulWidget) observe `cartProvider` pour afficher les articles et les montants, et `addressesStreamProvider` pour récupérer les adresses enregistrées.
* **Où c'est dans le code** : `lib/feature/checkout/checkout_screen.dart` (lignes 35-250).
* **Extrait de code réel** :
```dart
final session = ref.watch(sessionProvider);
final cart = ref.watch(cartProvider);
final authService = AuthService();
final firebaseUser = authService.currentUser;

if (session.isGuest || firebaseUser == null) {
  return Scaffold(
    appBar: const AppTopBar(title: 'Finaliser la commande', showBackButton: true),
    body: Center(child: /* Bouton vers Login */),
  );
}
```
* **Explication ligne par ligne** :
  - Lignes 1-4 : Récupération réactive des providers Riverpod et de l'utilisateur Firebase Auth courant.
  - Lignes 6-11 : Garde-fou de sécurité : si la session est expirée ou si l'utilisateur est invité, l'accès au formulaire est bloqué avec une invitation claire à se reconnecter.
* **Pourquoi ce choix technique** : Centraliser l'ensemble des éléments contractuels sur un seul écran avant validation afin de garantir la transparence pour le consommateur.

---

### Étape 4 : Lecture des adresses depuis Firestore (`users/{uid}/addresses`)

* **Ce que voit l'utilisateur** : L'adresse par défaut du client est présélectionnée automatiquement. S'il clique sur « Modifier », une feuille inférieure (bottom sheet) s'ouvre avec la liste de toutes ses adresses enregistrées ou la possibilité d'en ajouter une nouvelle.
* **Ce qui se passe dans le code** : `FirestoreAddressesRepository.watchAddresses(userId)` écoute la sous-collection `users/{uid}/addresses` en temps réel avec `orderBy('createdAt', descending: true)`. L'adresse ayant `isDefault == true` est triée en tête de liste.
* **Où c'est dans le code** : `lib/data/repositories/firestore_addresses_repository.dart` → méthode `watchAddresses()` (≈ lignes 45-60).
* **Extrait de code réel** :
```dart
Stream<List<AddressUiModel>> watchAddresses(String userId) {
  return _userAddressesRef(userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    final list =
        snapshot.docs.map((doc) => AddressUiModel.fromFirestore(doc)).toList();
    list.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return 0;
    });
    return list;
  });
}
```
* **Explication ligne par ligne** :
  - Lignes 2-4 : Requête Firestore sur la sous-collection ordonnée par date de création avec écoute réactive (`snapshots()`).
  - Lignes 5-6 : Transformation de chaque document Firestore en modèle Dart typé `AddressUiModel`.
  - Lignes 7-11 : Tri mémoire garantissant que l'adresse configurée par défaut apparaisse en premier.
* **Pourquoi ce choix technique** : Les sous-collections Firestore compartimentent naturellement les données personnelles par utilisateur, assurant une sécurité native et évitant le risque de fuite de données entre clients.

---

### Étape 5 : Validation avant envoi et protection anti-double clic

* **Ce que voit l'utilisateur** : L'utilisateur clique sur « Confirmer la commande ». Immédiatement, le bouton passe en état de chargement avec un indicateur circulaire, et tous les clics ultérieurs sont ignorés.
* **Ce qui se passe dans le code** : La méthode `_confirmAndSubmitOrder()` vérifie que `_isSubmitting == false` et que `_selectedAddress != null`. Elle bascule `_isSubmitting = true` dans `setState`, déclenche un retour haptique léger (`HapticFeedback.lightImpact()`), puis lance la création de la commande.
* **Où c'est dans le code** : `lib/feature/checkout/checkout_screen.dart` → méthode `_confirmAndSubmitOrder()` (≈ lignes 666-685).
* **Extrait de code réel** :
```dart
Future<void> _confirmAndSubmitOrder(BuildContext context) async {
  if (_isSubmitting || _selectedAddress == null) return;

  final cart = ref.read(cartProvider);
  final firebaseUser = AuthService().currentUser;

  if (firebaseUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session expirée, veuillez vous reconnecter.')),
    );
    return;
  }

  setState(() => _isSubmitting = true);
  // ... appel createOrder
}
```
* **Explication ligne par ligne** :
  - Ligne 2 : Garde-fou immédiat contre le multi-clic et vérification qu'une adresse physique de livraison est bien sélectionnée.
  - Lignes 6-12 : Vérification de la validité du jeton d'authentification Firebase Auth.
  - Ligne 14 : Verrouillage graphique de l'interface (`_isSubmitting = true`).
* **Pourquoi ce choix technique** : Empêcher la création de commandes dupliquées accidentelles si l'utilisateur appuie plusieurs fois rapidement lors d'une connexion réseau lente.

---

### Étape 6 : Création de la commande : Relecture des prix et écriture atomique (`WriteBatch`)

* **Ce que voit l'utilisateur** : Le sablier tourne brièvement (quelques centaines de millisecondes) pendant que l'application dialogue de manière sécurisée avec Firestore.
* **Ce qui se passe dans le code** :
  1. *Relecture impérative des produits* : Pour chaque produit du panier, l'application exécute un `_productsRef.doc(productId).get()`. Si un produit a été supprimé ou marqué `outOfStock` par l'Admin, l'opération s'interrompt avec une `ProductUnavailableException`.
  2. *Recalcul des prix* : Le sous-total est calculé à partir du `price` officiel stocké dans Firestore (et non du panier local) + frais de livraison. Les promotions sont gérées par l'app Admin ; le Client n'écrit jamais de code promo (écrit `0` en remise et `null` en code promo).
  3. *Génération du numéro lisible* : `OrderUiModel.generateDisplayNumber()` produit un identifiant convivial du type `DK-261101-7F3K`.
  4. *Écriture par lot atomique* : Un `WriteBatch` Firestore écrit le document complet dans `orders/{orderId}` avec `FieldValue.serverTimestamp()` pour `createdAt` et `updatedAt`.
* **Où c'est dans le code** : `lib/data/repositories/firestore_orders_repository.dart` → méthode `createOrder()` (≈ lignes 58-177).
* **Extrait de code réel** :
```dart
for (final item in cartItems) {
  final doc = await _productsRef.doc(item.productId).get();
  if (!doc.exists) {
    throw ProductUnavailableException(item.name, 'Cet article n\'existe plus.');
  }
  final data = doc.data() ?? {};
  final firestorePrice = (data['price'] as num?)?.toDouble() ?? item.unitPrice;
  final lineTotal = firestorePrice * item.quantity;
  calculatedSubtotal += lineTotal;
  // ... ajout dans verifiedItems
}

final batch = _firestore.batch();
batch.set(newDoc, orderData);
await batch.commit();
```
* **Explication ligne par ligne** :
  - Lignes 1-4 : Requête directe sur la collection `products` pour valider l'existence du produit.
  - Lignes 6-8 : Extraction du prix officiel dans la base et calcul de la ligne pour neutraliser toute falsification locale des prix.
  - Lignes 12-14 : Création du lot `WriteBatch`, insertion du document et commit atomique sur les serveurs Google Firebase.
* **Pourquoi ce choix technique** : Garantir l'intégrité financière absolue de la commande : le client ne peut jamais commander au prix mis en cache si l'administrateur a actualisé les tarifs entre-temps.

---

### Étape 7 : Vidage du panier après succès uniquement

* **Ce que voit l'utilisateur** : Le panier se vide de manière transparente en arrière-plan.
* **Ce qui se passe dans le code** : L'appel `ref.read(cartProvider.notifier).clearCart()` n'est exécuté **qu'après** la résolution favorable du `await batch.commit()`. En cas d'exception réseau ou d'article indisponible, le bloc `catch` intercepte l'erreur, le panier reste intact et l'utilisateur ne perd pas sa sélection.
* **Où c'est dans le code** : `lib/feature/checkout/checkout_screen.dart` (lignes 711-713).
* **Extrait de code réel** :
```dart
// Le panier n'est vidé QU'APRÈS confirmation de Firestore
await ref.read(cartProvider.notifier).clearCart();

if (mounted) {
  router.go('${AppRoutes.orderConfirmation}/${createdOrder.id}');
}
```
* **Explication ligne par ligne** :
  - Ligne 2 : Appel au notifier du panier pour réinitialiser les articles (`clearCart()`).
  - Lignes 4-6 : Vérification que le widget est toujours monté dans l'arborescence Flutter avant de rediriger vers l'écran de confirmation avec l'identifiant Firestore `createdOrder.id`.
* **Pourquoi ce choix technique** : Si la commande échoue (ex: perte subite de 4G), l'utilisateur n'a pas à recomposer son panier de zéro.

---

### Étape 8 : Écran de confirmation de commande

* **Ce que voit l'utilisateur** : Un grand cercle vert avec une coche animée apparaît avec un effet d'échelle rebondissant (`Curves.easeOutBack`). L'écran affiche : « Commande enregistrée ! », le numéro `DK-261101-7F3K`, le montant total payé, ainsi que deux boutons : « Suivre ma commande » et « Retour à l'accueil ». Le bouton physique Retour d'Android est intercepté pour renvoyer à l'accueil au lieu de réafficher le formulaire de checkout.
* **Ce qui se passe dans le code** : Le widget `OrderConfirmationScreen` utilise `PopScope(canPop: false)` pour bloquer le retour arrière standard et observe `singleOrderStreamProvider(orderId)` pour afficher les détails du document créé.
* **Où c'est dans le code** : `lib/feature/checkout/order_confirmation_screen.dart` (lignes 33-108).
* **Extrait de code réel** :
```dart
return PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, _) {
    if (!didPop) {
      context.go(AppRoutes.home);
    }
  },
  child: Scaffold(
    body: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: /* Coche verte */);
      },
    ),
  ),
);
```
* **Explication ligne par ligne** :
  - Lignes 1-7 : `PopScope` intercepte la touche physique "Retour" d'Android pour rediriger vers `/home` et éviter tout retour sur le panier vidé.
  - Lignes 9-15 : `TweenAnimationBuilder` anime l'icône de succès de l'échelle 0.0 à 1.0 en 600 ms avec une courbe d'amorti rebondissante.
* **Pourquoi ce choix technique** : Rassure visuellement le client sur la prise en compte immédiate de son achat tout en verrouillant la navigation contre les boucles d'écrans de paiement.

---

### Étape 9 : Écran « Mes commandes » en temps réel (`Stream` et `snapshots()`)

* **Ce que voit l'utilisateur** : L'écran « Mes commandes » affiche la liste des commandes avec :
  - Une barre de recherche filtrant instantanément par numéro ou par nom d'article (avec temporisation debounce de 250 ms).
  - Des pastilles de filtre horizontales (Toutes, En attente, En préparation, En livraison, Livrées, Annulées) affichant un badge avec le nombre exact de commandes.
  - Chaque carte présente un **ruban diagonal de statut** en haut à droite et une **barre de progression en 4 étapes** avec une icône de camionnette animée.
* **Ce qui se passe dans le code** : `FirestoreOrdersRepository.watchMyOrders(userId)` interroge Firestore avec `where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots()`. Le Stream émet automatiquement une nouvelle liste à chaque mise à jour sur le serveur.
* **Où c'est dans le code** :
  - Repository : `lib/data/repositories/firestore_orders_repository.dart` → méthode `watchMyOrders()` (lignes 204-213).
  - Écran : `lib/feature/orders/my_orders_screen.dart` (lignes 75-160).
* **Extrait de code réel** :
```dart
Stream<List<OrderUiModel>> watchMyOrders(String userId) {
  return _ordersRef
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => OrderUiModel.fromFirestore(doc)).toList();
  });
}
```
* **Explication ligne par ligne** :
  - Lignes 2-4 : Construction de la requête Firestore filtrée par `userId` et triée par date décroissante, convertie en flux réactif continu via `.snapshots()`.
  - Lignes 5-7 : Transformation de chaque document Firestore en objet modèle `OrderUiModel` transmis directement à Riverpod.
* **Pourquoi ce choix technique** : Grâce au Stream Firestore, dès que l'Admin valide ou expédie le colis, l'écran de l'utilisateur se met à jour instantanément sans nécessiter de rafraîchissement manuel de la page.

---

### Étape 10 : Détail et suivi avec chronologie verticale (`statusHistory`)

* **Ce que voit l'utilisateur** : En cliquant sur une carte de commande, l'écran de détail `/orders/:id` affiche :
  - La carte du destinataire et le mode de règlement.
  - La **chronologie verticale (timeline)** : chaque jalon (Reçue, Confirmée, En préparation, En livraison, Livrée) est affiché avec son icône, sa date et son heure précise formatée en français.
  - Si un livreur est assigné : la **carte Livreur** avec son nom, son numéro de téléphone et un bouton pour copier son numéro dans le presse-papiers (`Clipboard`).
* **Ce qui se passe dans le code** : Le tableau Firestore `statusHistory: [{status: 'pending', at: Timestamp}, ...]` est parcouru pour construire une série de widgets imbriqués reliés par une ligne verticale continue.
* **Où c'est dans le code** : `lib/feature/orders/order_detail_screen.dart` → méthode `_buildTimelineCard()` (≈ lignes 392-498).
* **Extrait de code réel** :
```dart
Widget _buildTimelineCard(OrderUiModel order) {
  final history = order.statusHistory;
  return Container(
    padding: const EdgeInsets.all(AppDimens.space16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
    ),
    child: Column(
      children: history.map((entry) => _buildTimelineStep(entry)).toList(),
    ),
  );
}
```
* **Explication ligne par ligne** :
  - Ligne 2 : Récupération du tableau chronologique `statusHistory` alimenté conjointement par le Client, l'Admin et le Livreur.
  - Lignes 4-8 : Décoration blanche aux coins arrondis respectant la charte graphique de l'application.
  - Ligne 10 : Itération sur chaque entrée pour afficher le statut et l'horodatage exact de l'étape.
* **Pourquoi ce choix technique** : Stocker l'historique complet dans le document permet d'offrir une traçabilité totale sans avoir besoin d'interroger une collection secondaire d'événements.

---

### Étape 11 : Annulation de la commande (`pending` → `cancelled`)

* **Ce que voit l'utilisateur** : Si la commande est encore au statut « En attente », un bouton rouge « Annuler cette commande » est disponible en bas de page. S'il clique dessus, une boîte de dialogue de confirmation apparaît. Après confirmation, le statut bascule immédiatement sur « Annulée » avec un ruban gris/rouge, et le bouton d'annulation disparaît.
* **Ce qui se passe dans le code** : `FirestoreOrdersRepository.cancelOrder()` exécute une **transaction Firestore** (`runTransaction`). La transaction relit l'état courant de la commande ; si et seulement si `status == 'pending'`, elle ajoute l'événement dans `statusHistory` et met à jour `status: 'cancelled'`.
* **Où c'est dans le code** : `lib/data/repositories/firestore_orders_repository.dart` → méthode `cancelOrder()` (≈ lignes 224-256).
* **Extrait de code réel** :
```dart
await _firestore.runTransaction((transaction) async {
  final snapshot = await transaction.get(docRef);
  final currentStatus = snapshot.data()?['status'] as String? ?? '';

  if (currentStatus != OrderStatus.pending.value) {
    throw Exception('Seule une commande encore "En attente" peut être annulée.');
  }

  final history = List.from(snapshot.data()?['statusHistory'] ?? []);
  history.add({'status': OrderStatus.cancelled.value, 'at': Timestamp.now()});

  transaction.update(docRef, {
    'status': OrderStatus.cancelled.value,
    'statusHistory': history,
    'updatedAt': FieldValue.serverTimestamp(),
  });
});
```
* **Explication ligne par ligne** :
  - Ligne 1 : Début de la transaction atomique Firestore.
  - Lignes 2-5 : Relecture isolée du document et vérification que la commande n'a pas déjà été acceptée ou expédiée entre-temps par l'administrateur.
  - Lignes 8-9 : Ajout du jalon d'annulation dans l'historique chronologique.
  - Lignes 11-15 : Mise à jour sécurisée des champs autorisés par les règles de sécurité.
* **Pourquoi ce choix technique** : L'utilisation d'une transaction évite une condition de concurrence (« race condition ») si le client annule au moment précis où l'administrateur confirme la commande.

---

### Étape 12 : Mise à jour en direct lors des actions Admin et Livreur

* **Ce que voit l'utilisateur** : Sans recharger l'écran, le client voit le ruban passer de « En attente » (ambre) à « En préparation » (bleu), puis « En livraison » (indigo avec nom du chauffeur) et enfin « Livrée » (vert).
* **Ce qui se passe dans le code** : Le widget écoute `singleOrderStreamProvider(orderId)`. Quand l'application Admin ou Livreur modifie le document Firestore `orders/{orderId}`, Firestore pousse le delta via WebSocket/gRPC. Riverpod reçoit le nouvel `OrderUiModel` et demande à Flutter de redessiner uniquement les widgets dépendants.
* **Où c'est dans le code** : `lib/feature/orders/order_detail_screen.dart` (lignes 25-45).
* **Pourquoi ce choix technique** : Offre une expérience utilisateur moderne type Uber Eats ou Amazon, sans requêtes HTTP périodiques énergivores (polling).

---

### Étape 13 : Gestion complète des pannes et erreurs

* **Ce que voit l'utilisateur** :
  - *Article indisponible* : SnackBar rouge explicite : « L'article [Nom] n'existe plus ou est en rupture de stock. »
  - *Coupure réseau* : SnackBar d'erreur réseau invitant à réessayer sans perte du panier.
  - *Session expirée* : Redirection avec message demandant de se reconnecter.
* **Ce qui se passe dans le code** : Le bloc `try / on ProductUnavailableException / catch (e) / finally` englobe l'appel de création et garantit la réactivation de l'interface (`_isSubmitting = false`).
* **Où c'est dans le code** : `lib/feature/checkout/checkout_screen.dart` (lignes 717-735).
* **Extrait de code réel** :
```dart
} on ProductUnavailableException catch (e) {
  messenger.showSnackBar(
    SnackBar(
      content: Text(e.toString()),
      backgroundColor: AppColors.error,
      duration: const Duration(seconds: 4),
    ),
  );
} catch (e) {
  messenger.showSnackBar(
    SnackBar(
      content: Text('Erreur réseau lors de la commande : $e'),
      backgroundColor: AppColors.error,
      duration: const Duration(seconds: 4),
    ),
  );
} finally {
  if (mounted) setState(() => _isSubmitting = false);
}
```
* **Explication ligne par ligne** :
  - Lignes 1-7 : Capture typée des anomalies catalogue (rupture de stock, produit dépublié) avec affichage d'un message métier compréhensible.
  - Lignes 8-15 : Capture générique des déconnexions Internet ou rejets de sécurité Firestore.
  - Lignes 16-18 : Bloc `finally` exécuté dans tous les cas pour déverrouiller le bouton de commande.
* **Pourquoi ce choix technique** : Assure la robustesse de l'application (« fail-safe ») : aucun crash inopiné et aucune interface bloquée indéfiniment en chargement.

---

## 3. Schéma Officiel du Document Firestore `orders/{orderId}`

### Tableau exhaustif des champs et types

| Champ | Type Firestore | Rempli / Modifié par | Description |
|---|---|---|---|
| `displayNumber` | `string` | Client | Numéro formaté lisible : `DK-AAMMJJ-XXXX` (ex: `DK-261101-7F3K`) |
| `userId` | `string` | Client | UID Firebase Auth du client |
| `customerName` | `string` | Client | Nom du destinataire de la commande |
| `customerPhone` | `string` | Client | Téléphone joignable pour le coursier |
| `status` | `string` | Client / Admin / Livreur | Statut textuel : `pending`, `confirmed`, `preparing`, `out_for_delivery`, `delivered`, `cancelled` |
| `statusHistory` | `array<map>` | Client / Admin / Livreur | Chronologie : `[{ status: "pending", at: Timestamp }]` |
| `items` | `array<map>` | Client | Copie figée (snapshot) des articles achetés |
| `itemCount` | `number` | Client | Somme cumulée des quantités physiques d'articles |
| `subtotal` | `number` | Client | Montant brut recalculé depuis les prix de Firestore |
| `discount` | `number` | Admin (Client écrit 0) | Montant déduit via une promotion gérée par l'Admin (le Client écrit toujours 0) |
| `promoCode` | `string` \| `null` | Admin (Client écrit null) | Code promo éventuel renseigné par l'Admin (le Client écrit toujours `null`) |
| `deliveryFee` | `number` | Client | Frais d'expédition (ex: 7.000 ou 0.000) |
| `total` | `number` | Client | Total TTC final payable à la livraison |
| `currency` | `string` | Client | Devise (`"TND"` pour Dinar Tunisien) |
| `deliveryAddress` | `map` | Client | Copie intégrale de l'adresse de destination |
| `deliveryMode` | `string` | Client | Mode de transport (`"standard"`) |
| `paymentMethod` | `string` | Client | Mode de règlement (`"cash_on_delivery"`) |
| `paymentStatus` | `string` | Client / Livreur | État du règlement (`"unpaid"` puis `"paid"`) |
| `estimatedDelivery` | `Timestamp` \| `null` | Admin | Date estimée de réception fixée par l'Admin |
| `driver` | `map` \| `null` | Admin / Livreur | Informations chauffeur : `{driverId, name, phone}` |
| `createdAt` | `Timestamp` | Client | Date de création côté serveur (`FieldValue.serverTimestamp()`) |
| `updatedAt` | `Timestamp` | Tous | Date de dernière mise à jour (`FieldValue.serverTimestamp()`) |

### Exemple JSON réel d'une commande dans Firestore

```json
{
  "displayNumber": "DK-261101-7F3K",
  "userId": "u7X92kLwNqZ1m4V8pT0y",
  "customerName": "Mohamed Ben Salah",
  "customerPhone": "21000000",
  "status": "out_for_delivery",
  "statusHistory": [
    {
      "status": "pending",
      "at": "2026-11-01T14:30:00.000Z"
    },
    {
      "status": "confirmed",
      "at": "2026-11-01T14:45:00.000Z"
    },
    {
      "status": "out_for_delivery",
      "at": "2026-11-01T15:10:00.000Z"
    }
  ],
  "items": [
    {
      "productId": "prod_ecouteurs_bt",
      "name": "Écouteurs Sans Fil Pro ANC",
      "imageUrl": "https://firebasestorage.googleapis.com/.../ecouteurs.jpg",
      "unitPrice": 89.900,
      "quantity": 1,
      "variantLabel": "Noir Mat",
      "lineTotal": 89.900
    }
  ],
  "itemCount": 1,
  "subtotal": 89.900,
  "discount": 0,
  "promoCode": null,
  "deliveryFee": 7.000,
  "total": 96.900,
  "currency": "TND",
  "deliveryAddress": {
    "recipientName": "Mohamed Ben Salah",
    "phone": "21000000",
    "addressLine": "15 Rue de la Liberté, Apt 4B",
    "city": "Tunis",
    "zone": "Centre Ville",
    "additionalInfo": "Étage 4",
    "deliveryInstructions": "Sonner à l'interphone Ben Salah"
  },
  "deliveryMode": "standard",
  "paymentMethod": "cash_on_delivery",
  "paymentStatus": "unpaid",
  "estimatedDelivery": "2026-11-02T12:00:00.000Z",
  "driver": {
    "driverId": "drv_karim_trad",
    "name": "Karim Trad",
    "phone": "98123456"
  },
  "createdAt": "2026-11-01T14:30:00.000Z",
  "updatedAt": "2026-11-01T15:10:00.000Z"
}
```

---

## 4. Règles de Sécurité Firestore (`firestore.rules`) Expliquées

Les règles de sécurité protègent la base contre toute malveillance :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 1. Catalogue Produits : consultation publique pour tous
    match /products/{productId} {
      allow read: if true;
    }

    // 2. Adresses personnelles : strict cloisonnement par utilisateur
    match /users/{userId}/addresses/{addressId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // 3. Commandes
    match /orders/{orderId} {
      // Lecture : seul l'auteur de la commande peut la lire
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;

      // Création : l'auteur crée avec statut initial 'pending' et données valides
      allow create: if request.auth != null 
                    && request.resource.data.userId == request.auth.uid
                    && request.resource.data.status == 'pending'
                    && request.resource.data.total is number
                    && request.resource.data.items is list
                    && request.resource.data.items.size() > 0;

      // Modification : le client ne peut QUE passer de 'pending' à 'cancelled'
      // interdiction formelle de modifier le total, le userId ou les articles
      allow update: if request.auth != null 
                    && resource.data.userId == request.auth.uid
                    && resource.data.status == 'pending'
                    && request.resource.data.status == 'cancelled'
                    && request.resource.data.userId == resource.data.userId
                    && request.resource.data.total == resource.data.total
                    && request.resource.data.items == resource.data.items
                    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'statusHistory', 'updatedAt']);

      // Suppression : strictement interdite (conservation historique légal)
      allow delete: if false;
    }
  }
}
```

### Explications simples pour l'oral :
1. **Cloisonnement des données** : Un utilisateur $A$ ne peut en aucun cas lire ou modifier les commandes de l'utilisateur $B$ (`resource.data.userId == request.auth.uid`).
2. **Statut initial forcé** : Le client ne peut pas s'auto-attribuer le statut `delivered` ou `confirmed` à la création ; le statut `pending` est obligatoire.
3. **Immutabilité financière** : Lors d'une annulation, la règle `affectedKeys().hasOnly(['status', 'statusHistory', 'updatedAt'])` interdit de modifier le prix payé ou la liste des articles.
4. **Pas de suppression** : `allow delete: if false` garantit que l'historique comptable ne peut jamais être effacé par une action client.

---

## 5. Rôle de l'Index Composite (`userId` + `createdAt`)

Dans `firestore.indexes.json` :
```json
{
  "collectionGroup": "orders",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

* **À quoi il sert** : Dans l'écran « Mes commandes », l'application effectue la requête :
  `.where('userId', isEqualTo: userId).orderBy('createdAt', descending: true)`
  Firestore indexe automatiquement chaque champ de manière unitaire, mais lorsqu'on combine un **filtre d'égalité** (`where ==`) avec un **tri sur un autre champ** (`orderBy DESC`), Firestore exige la création d'un index composite combiné.
* **Que se passe-t-il sans cet index ?** :
  La requête est rejetée par Firebase avec une erreur `FirebaseException: The query requires an index`. L'écran « Mes commandes » affiche alors un état d'erreur rouge et la console de débogage fournit une URL directe permettant de générer automatiquement l'index dans la console Firebase en un seul clic.

---

## 6. L'Énumération des Statuts (`OrderStatus`)

Dans `lib/data/models/order_status.dart` :

```dart
enum OrderStatus {
  pending('pending', 'En attente'),
  confirmed('confirmed', 'Confirmée'),
  preparing('preparing', 'En préparation'),
  outForDelivery('out_for_delivery', 'En livraison'),
  delivered('delivered', 'Livrée'),
  cancelled('cancelled', 'Annulée');
```

Chaque statut fournit :
1. **`label`** : Le texte traduit en français (ex: « En livraison »).
2. **`color` / `softColor`** : Les couleurs du thème Dokan (Ambre pour pending, Bleu/Cyan pour préparation, Indigo pour livraison, Vert pour livrée, Rouge pour annulée).
3. **`icon`** : L'icône Material associée (ex: `Icons.local_shipping_outlined`).
4. **`progressStep`** : L'étape de 0 à 3 sur la barre de progression (ou -1 pour annulée).
5. **`canBeCancelledByCustomer`** : Vrai uniquement si `this == OrderStatus.pending`.

---

## 7. Rôles et Responsabilités des Applications Admin et Livreur

Pour que le professeur comprenne l'écosystème complet :

1. **Ce que fait l'Application Client (Dokan)** :
   - Crée la commande avec `status: "pending"`.
   - Permet au client d'annuler sa commande tant qu'elle est en attente (`status: "cancelled"`).
   - Affiche en direct le suivi, les étapes et les informations du livreur assigné.
2. **Ce que fait l'Application Admin (Web ou Mobile)** :
   - Consulte toutes les commandes entrantes.
   - Valide la disponibilité des stocks et passe le statut à `confirmed` puis `preparing`.
   - Attribue la commande à un livreur en renseignant la map `driver: {driverId, name, phone}`.
   - Peut renseigner la date estimée de livraison (`estimatedDelivery`).
3. **Ce que fait l'Application Livreur (Mobile)** :
   - Voit la liste des colis qui lui sont attribués.
   - Déclare le début de sa tournée : statut `out_for_delivery`.
   - À la remise du colis et encaissement des espèces : statut `delivered` et `paymentStatus: "paid"`.
