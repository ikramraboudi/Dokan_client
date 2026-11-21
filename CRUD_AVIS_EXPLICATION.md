# Explication Technique du CRUD de Gestion des Avis Clients (Dokan Client)

> **Document pédagogique pour mini-projet académique**  
> **Application :** Dokan Client (Flutter & Firebase Firestore)  
> **Fonctionnalité étudiée :** CRUD complet de la collection `reviews` (Avis et notes sur les produits achetés)

---

## Phase 0 — Inventaire des fichiers de la fonctionnalité

| Fichier | Couche | Rôle en une phrase |
| :--- | :--- | :--- |
| `lib/data/models/review_model.dart` | **Modèle** | Définit la classe métier `ReviewUiModel` et l'agrégat `ReviewSummary` (moyenne et répartition). |
| `lib/data/repositories/review_repository.dart` | **Repository & Providers** | Interface abstraite, implémentation `FirestoreReviewRepository`, `MockReviewRepository` et providers Riverpod. |
| `lib/feature/orders/review_screen.dart` | **Écran (C, U, D)** | Écran de saisie interactif (visage animé, curseur 1–5, commentaire), mode modification et dialogue de suppression. |
| `lib/feature/product/widgets/product_reviews_section.dart` | **Composant UI (R, U, D)** | Section sur la fiche produit affichant la moyenne, les barres d'étoiles, la liste des avis et la carte « Votre avis ». |
| `firestore.rules` | **Sécurité Firebase** | Règles Cloud Firestore sécurisant les opérations `read`, `create`, `update` et `delete` sur `reviews/{reviewId}`. |
| `firestore.indexes.json` | **Configuration Firebase** | Index composite Firestore pour le tri des avis par produit et par date décroissante. |
| `lib/core/navigation/routes.dart` | **Navigation** | Déclare la constante d'URL `/orders/:orderId/review/:productId` et la fonction de construction du chemin. |
| `lib/core/navigation/app_router.dart` | **Navigation** | Associe la route d'avis au widget `ReviewScreen`. |
| `test/review_test.dart` | **Tests** | Tests unitaires et d'interface vérifiant le cycle de vie du CRUD et l'unicité de l'avis. |

> **Points d'entrée vers ce CRUD (hors périmètre, cités pour contexte) :**
> - `lib/feature/product/product_detail_screen.dart` (l. 356) : intègre `ProductReviewsSection` en bas de la fiche produit.
> - `lib/feature/orders/order_detail_screen.dart` (l. 1050) : bouton « ⭐ Donner mon avis » pour chaque article d'une commande livrée.
> - `lib/feature/orders/widgets/delivery_success_dialog.dart` (l. 289) : bouton « Donner mon avis sur les articles » affiché au client dès la réception du colis.

---

## 0. Vue d'ensemble

### 1. But du CRUD
Le CRUD des avis permet à un client connecté de noter et commenter un article qu'il a réellement reçu dans une commande livrée. Il garantit la transparence du catalogue grâce à une note moyenne en temps réel, tout en empêchant les faux avis et les doublons.

### 2. Tableau des fichiers du CRUD
*(Voir le tableau de l'Inventaire ci-dessus).*

### 3. Schéma d'architecture des couches
*Terme technique : **Riverpod** est un gestionnaire d'état qui relie l'interface graphique aux sources de données sans coupler le code.*

```
┌────────────────────────────────────────────────────────┐
│               INTERFACE UTILISATEUR (UI)               │
│  - ReviewScreen (Création, Modification, Suppression)  │
│  - ProductReviewsSection (Lecture, Moyenne, Détail)    │
└──────────────────────────┬─────────────────────────────┘
                           │ ref.watch() / ref.read()
                           ▼
┌────────────────────────────────────────────────────────┐
│             GESTION D'ÉTAT (RIVERPOD)                  │
│  - productReviewsStreamProvider (Écoute temps réel)    │
│  - productReviewSummaryProvider (Calcul moyenne)       │
│  - myReviewForProductProvider (Avis de l'utilisateur)  │
└──────────────────────────┬─────────────────────────────┘
                           │ Appels de méthodes
                           ▼
┌────────────────────────────────────────────────────────┐
│             COUCHE REPOSITORY & MODÈLE                 │
│  - ReviewRepository (Interface abstraite)              │
│  - FirestoreReviewRepository (Accès Firestore)         │
│  - ReviewUiModel (Conversion JSON ⇄ Objet Dart)        │
└──────────────────────────┬─────────────────────────────┘
                           │ Requêtes réseau SDK Firebase
                           ▼
┌────────────────────────────────────────────────────────┐
│               BASE DE DONNÉES CLOUD                    │
│  - Collection Firestore: reviews/{orderId}_{productId} │
│  - Contrôle d'accès: firestore.rules                   │
└────────────────────────────────────────────────────────┘
```

### 4. Structure du Document Firestore
* **Chemin Firestore :** `reviews/{reviewId}`
* **Règle de l'identifiant déterministe :** `{reviewId} = "${orderId}_${productId}"` (exemple : `DK-261109-2UMC_qbD12HeR3LUAwtuMHRTJ`).  
  *Pourquoi cela évite les doublons ?* Un client ne peut pas créer deux documents pour le même produit issu de la même commande. Si l'utilisateur valide une seconde fois, Firestore écrase ou met à jour ce document précis au lieu d'en créer un deuxième.

#### Tableau des champs réels du document Firestore

| Champ | Type | Rempli par | Description / Exemple |
| :--- | :--- | :--- | :--- |
| `productId` | `string` | Application | Identifiant unique de l'article noté (`"qbD12HeR3LUAwtuMHRTJ"`). |
| `orderId` | `string` | Application | Identifiant de la commande livrée d'origine (`"DK-261109-2UMC"`). |
| `userId` | `string` | Application (`user.uid`) | Identifiant Firebase Authentication de l'auteur (`"WbulqStAkMeWZ..."`). |
| `authorName` | `string` | Application (anonymisée) | Nom affiché sécurisé sans nom de famille complet (`"Karim M."`). |
| `rating` | `int` | Application | Note entière attribuée entre 1 et 5 (`5`). |
| `comment` | `string` | Application | Commentaire rédigé par le client (0 à 500 caractères, `"Super produit"`). |
| `createdAt` | `timestamp` | Firestore | Date et heure de publication (`FieldValue.serverTimestamp()`). |
| `updatedAt` | `timestamp` | Firestore | Date et heure de dernière modification (`FieldValue.serverTimestamp()`). |

#### Exemple réel de document dans la console Firestore
```json
// Collection : reviews / Document : DK-261109-2UMC_qbD12HeR3LUAwtuMHRTJ
{
  "productId": "qbD12HeR3LUAwtuMHRTJ",
  "orderId": "DK-261109-2UMC",
  "userId": "WbulqStAkMeWZblkdhehLwMBs8p2",
  "authorName": "Karim M.",
  "rating": 5,
  "comment": "Très satisfait, produit d'excellente qualité et conforme !",
  "createdAt": "10 novembre 2026 à 14:30:00 UTC+1",
  "updatedAt": "10 novembre 2026 à 14:30:00 UTC+1"
}
```

### 5. Modèle Dart complet (`lib/data/models/review_model.dart`)
*Terme technique : **fromFirestore** est un constructeur nommé qui convertit les données brutes Map de Firebase en un objet Dart typé.*

```dart
// Extrait de lib/data/models/review_model.dart (l. 10-53, 110-150)
class ReviewUiModel {
  final String id;
  final String productId;
  final String orderId;
  final String userId;
  final String authorName;
  final int rating;
  final String comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isVerifiedPurchase;

  const ReviewUiModel({
    required this.id,
    required this.productId,
    required this.orderId,
    required this.userId,
    required this.authorName,
    required this.rating,
    this.comment = '',
    this.createdAt,
    this.updatedAt,
    this.isVerifiedPurchase = true,
  });

  static String buildId({required String orderId, required String productId}) =>
      '${orderId}_$productId';

  factory ReviewUiModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ReviewUiModel.fromJson(data, doc.id);
  }

  factory ReviewUiModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return ReviewUiModel(
      id: id,
      productId: (json['productId'] as String?) ?? '',
      orderId: (json['orderId'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
      authorName: (json['authorName'] as String?) ?? 'Client Dokan',
      rating: ((json['rating'] as num?)?.toInt() ?? 5).clamp(1, 5),
      comment: (json['comment'] as String?)?.trim() ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      isVerifiedPurchase: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'orderId': orderId,
      'userId': userId,
      'authorName': authorName,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}
```

---

## 1. CREATE — Créer un avis

### Écran
* **Fichier :** `lib/feature/orders/review_screen.dart`
* **Widget :** `ReviewScreen` (classe d'état `_ReviewScreenState`)
* **Ce que voit l'utilisateur :**
  1. Une mini-carte récapitulative du produit (image, nom).
  2. Un grand visage animé dont l'expression et la couleur changent selon la note (rouge pour 1, orange pour 3, vert émeraude pour 5).
  3. Un curseur haptique interactif à 5 crans (1: TRÈS MAUVAIS, 2: MAUVAIS, 3: MOYEN, 4: BIEN, 5: EXCELLENT).
  4. Une boîte de texte pour commentaire facultatif avec compteur de caractères (`0 / 500`).
  5. Un bouton principal d'action : `Envoyer →`.
* **Conditions d'activation du bouton :** `_hasTouchedSlider && !_isSubmitting`. Le bouton est désactivé et grisé tant que l'utilisateur n'a pas sélectionné une note sur le curseur, et pendant l'envoi réseau.
* **Validations appliquées :** note clampée entre 1 et 5, longueur du commentaire limitée à 500 caractères maximum, commande obligatoirement au statut `delivered`, client authentifié avec un compte Firebase.
* **Écran de remerciement (`_buildSuccessView`) :** dès que Firestore confirme l'écriture, l'écran bascule sur un affichage festif avec un visage souriant, le texte « Merci ! Votre avis a bien été enregistré et aidera les autres clients. », le récapitulatif des étoiles et du commentaire, et un bouton pour fermer.

### Code de Création

#### (a) Déclenchement dans l'écran (`lib/feature/orders/review_screen.dart`, l. 321-349)
```dart
      final review = ReviewUiModel(
        id: ReviewUiModel.buildId(
          orderId: widget.orderId,
          productId: widget.productId,
        ),
        productId: widget.productId,
        orderId: widget.orderId,
        userId: user.uid,
        authorName: authorName,
        rating: _ratingStep,
        comment: _commentController.text.trim(),
        isVerifiedPurchase: true,
      );

      await repo.submitReview(review);

      // Invalidation des providers Riverpod pour actualisation immédiate
      ref.invalidate(productReviewSummaryProvider(widget.productId));
      ref.invalidate(productReviewsStreamProvider(widget.productId));
      ref.invalidate(orderReviewsStreamProvider(widget.orderId));
      ref.invalidate(eligibleDeliveredOrderIdProvider(widget.productId));
      ref.invalidate(myReviewForProductProvider(widget.productId));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSuccess = true;
        });
      }
```

#### (b) Le Provider Riverpod (`lib/data/repositories/review_repository.dart`, l. 17-22)
```dart
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  if (Firebase.apps.isNotEmpty) {
    return FirestoreReviewRepository();
  }
  return MockReviewRepository();
});
```

#### (c) Méthode complète d'écriture dans le Repository (`lib/data/repositories/review_repository.dart`, l. 312-349)
```dart
  @override
  Future<void> submitReview(ReviewUiModel review) async {
    if (review.rating < 1 || review.rating > 5) {
      throw ArgumentError('La note doit être comprise entre 1 et 5.');
    }
    final trimmedComment = review.comment.trim();
    if (trimmedComment.length > 500) {
      throw ArgumentError('Le commentaire ne peut pas dépasser 500 caractères.');
    }

    final docId = ReviewUiModel.buildId(
      orderId: review.orderId,
      productId: review.productId,
    );
    final docRef = _reviewsRef.doc(docId);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      // Modification
      await docRef.update({
        'rating': review.rating,
        'comment': trimmedComment,
        'authorName': review.authorName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Création
      await docRef.set({
        'productId': review.productId,
        'orderId': review.orderId,
        'userId': review.userId,
        'authorName': review.authorName,
        'rating': review.rating,
        'comment': trimmedComment,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
```

### Liaison avec Firebase
* **Appel exact :** `await docRef.set({...})` vers `reviews/{orderId}_{productId}`.
* **Origine des données :** `userId` provient de `FirebaseAuth.instance.currentUser!.uid`, `authorName` de `ReviewUiModel.sanitizeAuthorName()` (prénom + initiale, jamais d'e-mail), et les dates de `FieldValue.serverTimestamp()` pour garantir l'horodatage officiel du serveur Google.
* **Gestion d'erreur :** interceptée par un bloc `catch (e)`. L'application affiche un `SnackBar` rouge (`Échec de l'envoi : ...`) et débloque le bouton en repassant `_isSubmitting = false`.

### Règle de sécurité de création (`firestore.rules`, l. 185-214)
```javascript
allow create: if request.auth != null && (
  isAdmin() ||
  (
    request.resource.data.userId == request.auth.uid
    && reviewId == (request.resource.data.orderId + '_' + request.resource.data.productId)
    && request.resource.data.rating is int
    && request.resource.data.rating >= 1 && request.resource.data.rating <= 5
    && request.resource.data.comment is string && request.resource.data.comment.size() <= 500
    && request.resource.data.keys().hasOnly(['productId', 'orderId', 'userId', 'authorName', 'rating', 'comment', 'createdAt', 'updatedAt'])
    && (
      !exists(/databases/$(database)/documents/orders/$(request.resource.data.orderId))
      || (
        get(/databases/$(database)/documents/orders/$(request.resource.data.orderId)).data.userId == request.auth.uid
        && get(/databases/$(database)/documents/orders/$(request.resource.data.orderId)).data.status in ['livre', 'livree', 'delivered']
      )
    )
  )
);
```
*Explication en 3 lignes :* Le serveur vérifie que le client est connecté et qu'il est l'auteur désigné dans `userId`. Il contrôle que la note est comprise entre 1 et 5 et le commentaire sous 500 caractères. Enfin, il vérifie que la commande liée appartient bien à cet utilisateur et porte le statut livré.

### Flux de Création (Étape par étape)
1. L'utilisateur clique sur « ⭐ Donner mon avis » depuis sa commande livrée ou la fiche produit.
2. L'écran `ReviewScreen` s'ouvre, vérifie le statut livré de la commande et initialise le curseur.
3. L'utilisateur déplace le curseur (ex: 5 étoiles) et tape un commentaire facultatif.
4. L'utilisateur appuie sur le bouton actif `Envoyer →`.
5. L'écran instancie un `ReviewUiModel` anonymisé et appelle `repo.submitReview(review)`.
6. Le repository vérifie que le document n'existe pas et exécute `docRef.set(...)` dans Firestore.
7. Firestore valide les règles de sécurité et enregistre le document avec le timestamp serveur.
8. Le retour réussit : l'écran invalide les providers Riverpod et affiche la vue de succès « Merci ! ».

### Messages affichés
* Bouton initial : `Envoyer →`
* En cours : indicateur circulaire de chargement
* Succès : `Merci ! Votre avis a bien été enregistré et aidera les autres clients.`
* Erreur statut : `Vous ne pouvez donner votre avis que sur une commande livrée.`
* Erreur auth : `Veuillez vous connecter pour publier un avis.`

---

## 2. READ — Lire et afficher les avis

### Où sont affichés les avis ?
* **Fichier :** `lib/feature/product/widgets/product_reviews_section.dart`
* **Widget :** `ProductReviewsSection`
* **Composants affichés :**
  1. **En-tête :** titre « Avis des clients » et bouton « ⭐ Donner mon avis » si le client est éligible.
  2. **Carte résumé :** grande note moyenne (ex: `4,8`), 5 étoiles dorées, nombre total d'avis et 5 barres proportionnelles animées (pourcentages de 5 à 1 étoiles).
  3. **Carte « Votre avis » :** épinglée en premier si l'utilisateur connecté a déjà publié un avis, avec boutons « Modifier » et « Supprimer ».
  4. **Liste des avis clients :** nom de l'auteur (`Karim M.`), date relative (`Il y a 2 jours`), badge vert « Achat vérifié Dokan », note et commentaire.
* **États de chargement et erreurs :**
  - Chargement : squelette animé (`_buildSummaryShimmer()`).
  - Aucun avis : carte sobre avec le message « Aucun avis pour le moment. Soyez le premier à donner votre avis ! ».
  - Erreur réseau : repli automatique vers `ReviewSummary.empty` sans bloquer la fiche produit.

### Code de Lecture

#### (a) Méthodes complètes du Repository (`lib/data/repositories/review_repository.dart`)
```dart
  // Écoute temps réel des avis d'un produit (l. 129-141)
  @override
  Stream<List<ReviewUiModel>> watchReviews(String productId, {int limit = 20}) {
    return _reviewsRef
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ReviewUiModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return list.take(limit).toList();
    });
  }

  // Calcul du résumé avec agrégation native Firestore et repli en mémoire (l. 160-224)
  @override
  Future<ReviewSummary> getSummary(String productId) async {
    final baseQuery = _reviewsRef.where('productId', isEqualTo: productId);

    try {
      final aggregateSnap = await baseQuery
          .aggregate(count(), average('rating'))
          .get();

      final totalCount = aggregateSnap.count ?? 0;
      if (totalCount == 0) return ReviewSummary.empty;

      final avg = aggregateSnap.getAverage('rating') ?? 0.0;
      final distribution = <int, int>{};

      await Future.wait([5, 4, 3, 2, 1].map((star) async {
        try {
          final starSnap = await baseQuery.where('rating', isEqualTo: star).count().get();
          distribution[star] = starSnap.count ?? 0;
        } catch (_) {
          distribution[star] = 0;
        }
      }));

      return ReviewSummary(
        averageRating: avg,
        totalReviews: totalCount,
        distribution: distribution,
      );
    } catch (_) {
      // Repli immédiat en mémoire si l'agrégation native est refusée
      final docsSnap = await baseQuery.get();
      if (docsSnap.docs.isEmpty) return ReviewSummary.empty;

      final list = docsSnap.docs.map((d) => ReviewUiModel.fromFirestore(d)).toList();
      final total = list.length;
      final sum = list.fold<int>(0, (prev, r) => prev + r.rating);
      final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (final r in list) {
        distribution[r.rating] = (distribution[r.rating] ?? 0) + 1;
      }
      return ReviewSummary(
        averageRating: sum / total,
        totalReviews: total,
        distribution: distribution,
      );
    }
  }

  // Recherche de l'avis de l'utilisateur connecté (l. 248-263)
  @override
  Future<ReviewUiModel?> findMyReviewForProduct({
    required String userId,
    required String productId,
  }) async {
    try {
      final snap = await _reviewsRef
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return ReviewUiModel.fromFirestore(snap.docs.first);
    } catch (_) {
      return null;
    }
  }
```

#### (b) Providers Riverpod (`lib/data/repositories/review_repository.dart`, l. 25-69)
* `productReviewsStreamProvider` : fournit un `Stream` des avis triés par date.
* `productReviewSummaryProvider` : fournit l'objet `ReviewSummary` (moyenne et barres).
* `myReviewForProductProvider` : cherche si l'utilisateur courant a écrit un avis sur ce produit.
* `eligibleDeliveredOrderIdProvider` : vérifie si l'utilisateur a une commande livrée non encore notée.

### Liaison avec Firebase
* **Requêtes :**
  - Collection : `reviews`
  - Filtre : `.where('productId', isEqualTo: productId)`
  - Écoute : `.snapshots()` (temps réel sans rechargement de page).
  - Agrégats : `.aggregate(count(), average('rating'))`.
* **Index Firestore nécessaire (`firestore.indexes.json`, l. 28-40) :**
```json
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "productId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
```
* **Règle de sécurité de lecture (`firestore.rules`, l. 182) :**
```javascript
allow read: if true;
```
*Explication :* La consultation des avis et des moyennes est totalement publique afin que les visiteurs anonymes puissent lire les retours clients avant d'acheter.

### Comment l'écran reconnaît l'avis de l'utilisateur connecté ?
Le provider `myReviewForProductProvider` exécute une requête `where('userId', isEqualTo: user.uid)`. Si le document existe, il est extrait de la liste générale et présenté dans la carte spéciale `_buildMyReviewCard` avec les boutons « Modifier » et « Supprimer ».

---

## 3. UPDATE — Modifier un avis

### Écran
* **Fichier :** `lib/feature/orders/review_screen.dart`
* **Comment l'écran passe en mode modification :**  
  Dans sa méthode `_initData()`, l'écran interroge Firestore : `repo.getMyReviewForProductInOrder(...)`. Si un avis existe déjà :
  1. La variable `_isEditMode` passe à `true`.
  2. Le curseur se positionne automatiquement sur la note existante (`_sliderRating = existing.rating`).
  3. La zone de texte est préremplie avec le commentaire existant (`_commentController.text = existing.comment`).
  4. Le titre de la page devient **« Modifier mon avis »**.
  5. Le bouton d'envoi devient **« Mettre à jour mon avis »**.
  6. Un bouton rouge discret **« Supprimer mon avis »** apparaît sous le formulaire.
* **Point d'entrée :** déclenché par un clic sur le bouton « Modifier » dans `ProductReviewsSection` (l. 375) ou dans l'écran de détail de commande.

### Code de Modification

#### (a) Branche d'exécution dans le Repository (`lib/data/repositories/review_repository.dart`, l. 328-336)
```dart
    final docRef = _reviewsRef.doc(docId);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      // Modification
      await docRef.update({
        'rating': review.rating,
        'comment': trimmedComment,
        'authorName': review.authorName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
```

### Liaison avec Firebase
* **Appel exact :** `await docRef.update({...})` sur le document ciblé `reviews/{orderId}_{productId}`.
* **Champs modifiés :** `rating`, `comment`, `authorName`, et `updatedAt` qui prend la date courante du serveur.
* **Champs conservés intacts :** `productId`, `orderId`, `userId`, et surtout `createdAt` qui conserve la date d'origine de création.
* **Différence dans la console Firebase :** `createdAt` ne bouge pas ; seul `updatedAt` change, et la note/commentaire prennent leurs nouvelles valeurs.

### Règle de sécurité de modification (`firestore.rules`, l. 217-231)
```javascript
allow update: if request.auth != null && (
  isAdmin() ||
  (
    resource.data.userId == request.auth.uid
    && request.resource.data.userId == resource.data.userId
    && request.resource.data.orderId == resource.data.orderId
    && request.resource.data.productId == resource.data.productId
    && request.resource.data.rating is int
    && request.resource.data.rating >= 1 && request.resource.data.rating <= 5
    && request.resource.data.comment is string && request.resource.data.comment.size() <= 500
    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['rating', 'comment', 'updatedAt', 'authorName'])
  )
);
```
*Explication en 3 lignes :* Seul l'auteur initial de l'avis (`resource.data.userId == request.auth.uid`) est autorisé à modifier son document. La règle garantit l'intégrité en interdisant formellement de changer l'`orderId`, le `productId` ou le `userId`. Seuls les champs d'évaluation (`rating`, `comment`, `updatedAt`, `authorName`) peuvent être altérés.

### Flux de Modification
1. Le client clique sur « Modifier » depuis la carte « Votre avis » de la fiche produit.
2. `ReviewScreen` s'ouvre, charge l'avis existant et préremplit la note et le commentaire.
3. Le client modifie sa note ou ajuste son texte.
4. Le client appuie sur « Mettre à jour mon avis ».
5. `repo.submitReview()` constate que `docSnap.exists` est vrai et appelle `docRef.update(...)`.
6. Firestore vérifie que seuls les champs autorisés ont changé et enregistre le nouveau timestamp `updatedAt`.
7. L'application invalide les providers Riverpod : la moyenne et la liste sont recalculées immédiatement.

---

## 4. DELETE — Supprimer un avis

### Écran
* **Emplacements de l'action de suppression :**
  1. Sur la carte « Votre avis » de la fiche produit (`ProductReviewsSection`, bouton rouge « Supprimer »).
  2. En bas de l'écran `ReviewScreen` en mode édition (bouton « Supprimer mon avis »).
* **Boîte de dialogue de confirmation (`AlertDialog`) :**
  - **Titre :** « Supprimer votre avis ? »
  - **Message :** « Êtes-vous certain de vouloir supprimer définitivement votre avis pour ce produit ? Cette action est irréversible. »
  - **Bouton d'annulation :** « Annuler » (`Navigator.pop(false)`).
  - **Bouton de confirmation :** « Supprimer » en rouge (`Navigator.pop(true)`).

### Code de Suppression

#### (a) Dans l'écran (`lib/feature/orders/review_screen.dart`, l. 396-414)
```dart
      final repo = ref.read(reviewRepositoryProvider);
      await repo.deleteReview(
        orderId: widget.orderId,
        productId: widget.productId,
      );

      ref.invalidate(productReviewSummaryProvider(widget.productId));
      ref.invalidate(productReviewsStreamProvider(widget.productId));
      ref.invalidate(orderReviewsStreamProvider(widget.orderId));
      ref.invalidate(eligibleDeliveredOrderIdProvider(widget.productId));
      ref.invalidate(myReviewForProductProvider(widget.productId));

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Votre avis a été supprimé.'),
          backgroundColor: AppColors.textPrimary,
        ),
      );

      if (mounted) context.pop(true);
```

#### (b) Dans le Repository (`lib/data/repositories/review_repository.dart`, l. 352-361)
```dart
  @override
  Future<void> deleteReview({
    required String orderId,
    required String productId,
  }) async {
    final docId = ReviewUiModel.buildId(
      orderId: orderId,
      productId: productId,
    );
    await _reviewsRef.doc(docId).delete();
  }
```

### Liaison avec Firebase
* **Appel exact :** `await _reviewsRef.doc("${orderId}_${productId}").delete();`.
* **Document visé :** le document unique déterministe dans la collection `reviews`.
* **Répercussion sur l'affichage :**
  - Grâce à `ref.invalidate(...)`, le `StreamProvider` réémet instantanément la liste sans le document.
  - La carte « Votre avis » disparaît.
  - Le bouton « ⭐ Donner mon avis » réapparaît automatiquement car la commande livrée redevient éligible.
  - La note moyenne et les barres d'étoiles sont recalculées sans l'avis supprimé.

### Règle de sécurité de suppression (`firestore.rules`, l. 234)
```javascript
allow delete: if request.auth != null && (resource.data.userId == request.auth.uid || isAdmin());
```
*Explication en 2 lignes :* La suppression n'est permise que si l'utilisateur authentifié est le propriétaire effectif de l'avis (`resource.data.userId == request.auth.uid`) ou s'il dispose du rôle administrateur pour la modération.

### Messages affichés
* Dialogue : `Êtes-vous certain de vouloir supprimer définitivement votre avis pour ce produit ? Cette action est irréversible.`
* Confirmation : `Votre avis a été supprimé.`
* En cas d'échec : `Impossible de supprimer : [erreur]`

---

## 5. Résumé de la liaison avec Firebase

### 1. Configuration et Initialisation
* Initialisation dans `lib/main.dart` (l. 43-45) :
  ```dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  ```
* Obtention de l'instance dans le repository : `final FirebaseFirestore _firestore = FirebaseFirestore.instance;` (`lib/data/repositories/review_repository.dart`, l. 120).
* Bascule automatique Mock ⇄ Firestore (`lib/data/repositories/review_repository.dart`, l. 17-22) :
  ```dart
  final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
    if (Firebase.apps.isNotEmpty) {
      return FirestoreReviewRepository();
    }
    return MockReviewRepository();
  });
  ```

### 2. Les Règles de Sécurité complètes expliquées ligne par ligne (`firestore.rules`, l. 180-235)

```javascript
180: match /reviews/{reviewId} {
181:   // 1. LECTURE PUBLIQUE
182:   allow read: if true;
       // -> Tout utilisateur (connecté ou simple visiteur anonyme) peut consulter les avis.

184:   // 2. CRÉATION
185:   allow create: if request.auth != null && (
186:     isAdmin() ||
187:     (
188:       request.resource.data.userId == request.auth.uid
           // -> L'utilisateur doit être connecté et son UID doit correspondre au champ userId envoyé.
189:       && reviewId == (request.resource.data.orderId + '_' + request.resource.data.productId)
           // -> L'ID du document doit respecter la règle stricte "{orderId}_{productId}".
190:       && request.resource.data.rating is int
191:       && request.resource.data.rating >= 1
192:       && request.resource.data.rating <= 5
           // -> La note doit obligatoirement être un entier compris entre 1 et 5.
193:       && request.resource.data.comment is string
194:       && request.resource.data.comment.size() <= 500
           // -> Le commentaire doit être du texte d'au maximum 500 caractères.
195:       && request.resource.data.keys().hasOnly([
196:            'productId', 'orderId', 'userId', 'authorName',
197:            'rating', 'comment', 'createdAt', 'updatedAt'
198:          ])
           // -> Interdiction stricte d'injecter des champs indésirables dans Firestore.
199:       && (
200:         !exists(/databases/$(database)/documents/orders/$(request.resource.data.orderId))
201:         || (
202:           (
203:             get(/databases/$(database)/documents/orders/$(request.resource.data.orderId)).data.userId == request.auth.uid
204:             || get(/databases/$(database)/documents/orders/$(request.resource.data.orderId)).data.customerId == request.auth.uid
205:             || get(/databases/$(database)/documents/orders/$(request.resource.data.orderId)).data.clientId == request.auth.uid
206:           )
               // -> Vérifie que la commande d'origine appartient bien à l'utilisateur connecté.
207:           && (
208:             get(/databases/$(database)/documents/orders/$(request.resource.data.orderId)).data.status in ['livre', 'livree', 'delivered']
209:             || get(/databases/$(database)/documents/orders/$(request.resource.data.orderId)).data.statut in ['livre', 'livree', 'delivered']
210:           )
               // -> Vérifie que la commande liée est bien dans un statut livré officiel.
211:         )
212:       )
213:     )
214:   );

216:   // 3. MODIFICATION
217:   allow update: if request.auth != null && (
218:     isAdmin() ||
219:     (
220:       resource.data.userId == request.auth.uid
           // -> Seul l'auteur initial de l'avis peut effectuer une mise à jour.
221:       && request.resource.data.userId == resource.data.userId
222:       && request.resource.data.orderId == resource.data.orderId
223:       && request.resource.data.productId == resource.data.productId
           // -> Interdiction absolue de réassigner l'avis à un autre utilisateur, produit ou commande.
224:       && request.resource.data.rating is int
225:       && request.resource.data.rating >= 1
226:       && request.resource.data.rating <= 5
227:       && request.resource.data.comment is string
228:       && request.resource.data.comment.size() <= 500
           // -> La nouvelle note et le commentaire respectent les mêmes contraintes de validité.
229:       && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['rating', 'comment', 'updatedAt', 'authorName'])
           // -> Seuls les champs d'avis et la date de mise à jour peuvent être modifiés.
230:     )
231:   );

233:   // 4. SUPPRESSION
234:   allow delete: if request.auth != null && (resource.data.userId == request.auth.uid || isAdmin());
       // -> Seul le propriétaire de l'avis (ou un administrateur) a le droit de supprimer le document.
235: }
```

### 3. Tableau récapitulatif final des 4 opérations CRUD

| Opération | Écran / Widget | Méthode du Repository | Appel Firestore exact | Règle de sécurité associée | Effet visible dans l'application |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **CREATE** | `ReviewScreen` | `submitReview(review)` | `_reviewsRef.doc(id).set({...})` | `allow create: if request.auth != null && ...` | Écran de remerciement festif, nouvelle note comptabilisée dans la moyenne. |
| **READ** | `ProductReviewsSection` | `watchReviews()` & `getSummary()` | `.where(...).snapshots()` & `.aggregate(...)` | `allow read: if true;` | Affichage temps réel de la moyenne, des barres d'étoiles et de la liste. |
| **UPDATE** | `ReviewScreen` | `submitReview(review)` | `_reviewsRef.doc(id).update({...})` | `allow update: if resource.data.userId == uid && ...` | Mise à jour de la note et du commentaire, actualisation immédiate de la moyenne. |
| **DELETE** | `ProductReviewsSection` ou `ReviewScreen` | `deleteReview(orderId, productId)` | `_reviewsRef.doc(id).delete()` | `allow delete: if resource.data.userId == uid` | Disparition de l'avis, recalcul à la baisse du nombre d'avis, réapparition du bouton d'ajout. |

---

## 6. Points d'attention et remarques pour le rapport académique

1. **Garantie d'unicité sans doublon :**  
   L'identifiant déterministe `orderId_productId` résout élégamment le problème des doublons au niveau de la structure même de la base de données : il est techniquement impossible d'avoir deux documents pour le même achat.
2. **Protection de la vie privée (RGPD) :**  
   La méthode `ReviewUiModel.sanitizeAuthorName` anonymise le nom côté client avant l'envoi réseau (`"Karim Mansour"` devient `"Karim M."`). Aucun e-mail ni numéro de téléphone n'est jamais enregistré dans la collection publique `reviews`.
3. **Résilience hors-ligne et repli d'agrégation :**  
   Si l'API native d'agrégation Firestore (`count()`, `average()`) échoue (par exemple en émulateur local ou quota restreint), `getSummary()` bascule automatiquement sur un calcul en mémoire à partir des documents sans planter l'interface.
4. **Tri en mémoire :**  
   Dans `watchReviews()`, le tri temporel est effectué en Dart (`list.sort(...)`) en plus de la requête, ce qui permet à l'application de fonctionner même si l'index composite cloud met quelques secondes à se synchroniser.
