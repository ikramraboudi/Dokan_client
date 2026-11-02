# 10 — L'Intégration Firebase dans l'Application Dokan Client

> **Guide technique et aide-mémoire pour la soutenance orale**  
> Ce document recense tous les services Firebase intégrés dans le client mobile Dokan : Firebase Auth, Cloud Firestore (produits, commandes, adresses), configuration native et état des futures migrations.

---

## 1. Vue d'Ensemble des Services Firebase Utilisés

L'application Dokan utilise **Google Firebase** comme backend as a Service (BaaS). Deux briques technologiques principales sont sollicitées :

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        PROJET FIREBASE : Dokan                         │
└───────────────────┬────────────────────────────────┬───────────────────┘
                    │                                │
     ┌──────────────▼─────────────┐   ┌──────────────▼─────────────┐
     │       Firebase Auth        │   │      Cloud Firestore       │
     │ (Authentification Clients) │   │  (Base NoSQL Documentaire) │
     └──────────────┬─────────────┘   └──────────────┬─────────────┘
                    │                                │
    ┌───────────────┴───────────────┐  ┌─────────────┴─────────────┐
    │ • Inscription (Email/MDP)     │  │ • Collection 'products'   │
    │ • Connexion (Email/MDP)       │  │ • Collection 'orders'     │
    │ • Mot de passe oublié         │  │ • Sous-coll. 'addresses'  │
    │ • Restauration session Splash │  │ • Écoute temps réel       │
    │ • Déconnexion                 │  │ • Transactions atomiques  │
    └───────────────────────────────┘  └───────────────────────────┘
```

---

## 2. Firebase Authentication (Gestion des Comptes Utilisateurs)

### 2.1 Emplacement du service
Toutes les interactions avec le SDK Firebase Auth sont encapsulées dans la classe `AuthService` située dans `lib/services/auth_service.dart`. Les écrans appellent ce service et répercutent le résultat dans le `sessionProvider` (Riverpod).

---

### 2.2 Actions Utilisateur & Méthodes Firebase

#### 1. Inscription d'un nouveau client (`signUp`)
* **Fichier UI** : `lib/feature/auth/register_screen.dart` → méthode `_handleSignUp()` (≈ lignes 43-103).
* **Fichier Service** : `lib/services/auth_service.dart` → méthode `signUp()` (≈ lignes 13-21).
* **Méthode Firebase appelée** :
  ```dart
  FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );
  ```
* **Mise à jour du profil** : Après création du compte Auth, le nom complet est injecté via `userCredential.user?.updateDisplayName(fullName)`.
* **Gestion des erreurs** : Les exceptions `FirebaseAuthException` sont interceptées :
  - `email-already-in-use` : « Cette adresse email est déjà associée à un compte. »
  - `weak-password` : « Le mot de passe doit comporter au moins 6 caractères. »
  - `invalid-email` : « Adresse email invalide. »

#### 2. Connexion d'un client existant (`signIn`)
* **Fichier UI** : `lib/feature/auth/login_screen.dart` → méthode `_handleLogin()` (≈ lignes 42-88).
* **Fichier Service** : `lib/services/auth_service.dart` → méthode `signIn()` (≈ lignes 24-32).
* **Méthode Firebase appelée** :
  ```dart
  FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );
  ```
* **Gestion d'état** : En cas de succès, `ref.read(sessionProvider.notifier).loginSuccess(userSummary)` est appelé. Si une action protégée était en attente (ex: commande initiée en mode visiteur), elle est débloquée et exécutée immédiatement.
* **Gestion des erreurs** :
  - `user-not-found` / `wrong-password` / `invalid-credential` : « Identifiants invalides. Vérifiez votre email et mot de passe. »
  - `user-disabled` : « Ce compte utilisateur a été désactivé. »
  - `too-many-requests` : « Trop de tentatives infructueuses. Veuillez patienter quelques instants. »

#### 3. Réinitialisation de mot de passe (`sendPasswordResetEmail`)
* **Fichier UI** : `lib/feature/auth/forgot_password_screen.dart` → méthode `_submitReset()` (≈ lignes 32-60).
* **Fichier Service** : `lib/services/auth_service.dart` → méthode `sendPasswordResetEmail()` (≈ lignes 35-37).
* **Méthode Firebase appelée** :
  ```dart
  FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  ```
* **Sécurité & ergonomie** : L'écran applique le principe de confirmation neutre : que l'adresse email existe ou non dans la base, l'application affiche un écran de succès confirmant l'envoi pour éviter la divulgation d'utilisateurs inscrits (« User Enumeration attack »).

#### 4. Déconnexion (`signOut`)
* **Fichier UI** : `lib/feature/profile/profile_screen.dart` → bouton déconnexion.
* **Fichier Service** : `lib/services/auth_service.dart` → méthode `signOut()` (≈ lignes 40-42).
* **Méthode Firebase appelée** :
  ```dart
  FirebaseAuth.instance.signOut();
  ```
* **Conséquence dans l'app** : Appel de `ref.read(sessionProvider.notifier).logout()`. L'application repasse instantanément en mode « Visiteur ». Le panier reste préservé en mémoire.

#### 5. Restauration de session au démarrage (Splash Screen)
* **Fichier UI** : `lib/feature/splash/splash_screen.dart` → méthode `_verifyFirebaseAuth()` (≈ lignes 306-316).
* **Mécanisme** : Pendant l'affichage de l'animation d'ouverture (3 secondes configurées dans `AppConfig.splashDuration`), l'application écoute le flux Firebase Auth :
  ```dart
  await FirebaseAuth.instance.authStateChanges().first.timeout(
    const Duration(seconds: 2),
    onTimeout: () => null,
  );
  ```
  Si un jeton valide est stocké sur l'appareil dans le SecureStorage natif d'Android, l'utilisateur est automatiquement reconnecté avant d'atteindre l'écran d'accueil sans aucune saisie requise.

---

## 3. Cloud Firestore — Catalogue Produits (`products`)

### 3.1 Structure de la collection `products/{productId}`
La collection `products` est alimentée par l'application d'administration. L'application Client la consulte en lecture seule (`allow read: if true;`).

Champs exploités par `ProductUiModel.fromFirestore` (`lib/data/models/product_ui_model.dart`) :
- `name` / `title` (`string`) : Nom affiché de l'article (tolérance sur les deux clés).
- `description` (`string`) : Descriptif complet pour la fiche produit.
- `price` (`number`) : Prix de vente unitaire actuel en Dinars Tunisiens.
- `oldPrice` (`number?`) : Ancien prix barré en cas de promotion.
- `discountLabel` (`string?`) : Macaron promotionnel (ex: `"-20%"`).
- `availability` (`string`) : Disponibilité (`inStock`, `limitedStock`, `outOfStock`).
- `inStock` (`bool?`) : Drapeau booléen vérifié lors de la commande.
- `imageUrls` (`list<string>`) / `imageUrl` (`string`) : Photographies du produit (gestion du singulier et pluriel).
- `category` / `categoryName` (`string`) : Catégorie de rattachement (Mode, Électronique, Maison...).
- `rating` (`number?`) : Note moyenne sur 5 étoiles.
- `reviewCount` (`number`) : Nombre d'avis clients déposés.
- `variants` (`list<string>?`) : Tailles ou déclinaisons de couleurs disponibles.
- `isNew` (`bool`) : Arrivage récent (badge "Nouveau").
- `isPopular` (`bool`) : Produit tendance sur l'accueil.

---

### 3.2 Deux Modes d'Accès aux Produits

#### Mode 1 : Écoute en Temps Réel (`Stream` et `snapshots()`)
* **Fichier** : `lib/services/product_service.dart`.
* **Utilisation** : Sur la page d'accueil (`HomeScreen`), pour animer en direct les bannières de promotions et les nouveaux arrivages dès que l'Admin publie un article :
  - `getNewProducts()` : `_productsRef.where('isNew', isEqualTo: true).snapshots()`
  - `getDiscountedProducts()` : `_productsRef.snapshots()` filtré sur `hasDiscount`
  - `getPopularProducts()` : `_productsRef.where('isPopular', isEqualTo: true).snapshots()`

#### Mode 2 : Requêtes Ponctuelles (`Future` et `get()`)
* **Fichier** : `lib/data/repositories/firestore_catalog_repository.dart`.
* **Utilisation** : Catalogue par catégorie et moteur de recherche :
  - `getProductsByCategory(category)` : Requête paginée avec filtre en mémoire.
  - `searchProducts(...)` : Recherche textuelle multicritères avec tri (prix croissant/décroissant, popularité, nouveautés) et filtres (disponible uniquement, fourchette de prix min/max).
  - `createOrder()` : Relecture unitaire ponctuelle via `_productsRef.doc(productId).get()` pour vérifier le prix officiel avant encaissement.

---

## 4. Cloud Firestore — Commandes (`orders`) et Adresses (`addresses`)

### 4.1 Collection des commandes : `orders/{orderId}`
* **Fichier Repository** : `lib/data/repositories/firestore_orders_repository.dart`.
* **Opérations supportées** :
  1. `createOrder(...)` :
     - Relecture des prix dans `products`.
     - Écriture atomique par lot via `WriteBatch`.
     - Attribution d'un numéro lisible `displayNumber: "DK-AAMMJJ-XXXX"`.
     - Horodatage certifié serveur via `FieldValue.serverTimestamp()`.
  2. `watchMyOrders(userId)` :
     - Écoute réactive `Stream<List<OrderUiModel>>`.
     - Requête : `_ordersRef.where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots()`.
     - Nécessite l'index composite déclaré dans `firestore.indexes.json`.
  3. `watchOrder(orderId)` :
     - Suivi direct d'un colis précis sur `_ordersRef.doc(orderId).snapshots()`.
  4. `cancelOrder(orderId)` :
     - Annulation sécurisée par `FirebaseFirestore.instance.runTransaction`.
     - Vérifie que le statut est encore strictement `pending` avant de basculer sur `cancelled`.

### 4.2 Sous-collection des adresses : `users/{uid}/addresses/{addressId}`
* **Fichier Repository** : `lib/data/repositories/firestore_addresses_repository.dart`.
* **Opérations supportées** :
  - `watchAddresses(userId)` : Écoute en temps réel de toutes les adresses enregistrées par le client.
  - `addAddress(userId, address)` : Ajout d'une nouvelle adresse avec gestion de l'adresse par défaut via un lot `WriteBatch`.
  - `updateAddress(userId, address)` : Modification d'une adresse existante.
  - `deleteAddress(userId, addressId)` : Suppression d'une adresse.

---

## 5. Initialisation Technique de Firebase dans le Projet

### 5.1 Point d'entrée `lib/main.dart`
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: DokanApp(),
    ),
  );
}
```

### 5.2 Fichier `lib/firebase_options.dart`
Ce fichier est généré automatiquement par la commande officielle **FlutterFire CLI** (`flutterfire configure`). Il contient les identifiants de liaison pour chaque plateforme cible :
- `projectId` : Nom du projet Firebase Google Cloud (`ee-comeerce`).
- `appId` : Identifiant unique de l'application cliente compilée.
- `apiKey` : Clé d'API publique Google pour authentifier les requêtes vers les endpoints Firebase.
- `messagingSenderId` : Identifiant Google Cloud Messaging (Firebase Cloud Messaging).
- `storageBucket` : URL du compartiment de stockage pour les images de produits.

### 5.3 Fichier natif `android/app/google-services.json`
* **Rôle** : Fournit au plugin Gradle Google Services (`com.google.gms.google-services`) les métadonnées de packaging pour Android (numéro de projet, package name `com.example.dokan_client`, empreintes de certificats SHA-1 et SHA-256 pour Firebase Auth).
* **Important pour l'oral** : Ce fichier ne doit jamais être partagé publiquement sur un dépôt Git car il lie l'application Android physique au backend cloud.

---

## 6. Tableau Récapitulatif : Action Utilisateur → Méthode Firebase

| Action de l'utilisateur | Méthode Firebase SDK | Chemin Firestore / Auth | Fichier du projet |
|---|---|---|---|
| Créer un compte | `createUserWithEmailAndPassword` | Firebase Auth | `lib/services/auth_service.dart` |
| Se connecter | `signInWithEmailAndPassword` | Firebase Auth | `lib/services/auth_service.dart` |
| Mot de passe oublié | `sendPasswordResetEmail` | Firebase Auth | `lib/services/auth_service.dart` |
| Se déconnecter | `signOut` | Firebase Auth | `lib/services/auth_service.dart` |
| Démarrage de l'app | `authStateChanges().first` | Firebase Auth | `lib/feature/splash/splash_screen.dart` |
| Voir les nouveautés | `.where('isNew', true).snapshots()` | Collection `products` | `lib/services/product_service.dart` |
| Consulter une catégorie | `.get()` | Collection `products` | `lib/data/repositories/firestore_catalog_repository.dart` |
| Rechercher un produit | `.get()` avec filtres Dart | Collection `products` | `lib/data/repositories/firestore_catalog_repository.dart` |
| Vérifier stock & prix | `.doc(productId).get()` | Document `products/{id}` | `lib/data/repositories/firestore_orders_repository.dart` |
| Valider la commande | `WriteBatch.commit()` | Collection `orders` | `lib/data/repositories/firestore_orders_repository.dart` |
| Liste « Mes commandes » | `where('userId').snapshots()` | Collection `orders` | `lib/data/repositories/firestore_orders_repository.dart` |
| Suivre un colis en direct | `.doc(orderId).snapshots()` | Document `orders/{id}` | `lib/data/repositories/firestore_orders_repository.dart` |
| Annuler une commande | `runTransaction()` | Document `orders/{id}` | `lib/data/repositories/firestore_orders_repository.dart` |
| Mes adresses | `.orderBy('createdAt').snapshots()` | `users/{uid}/addresses` | `lib/data/repositories/firestore_addresses_repository.dart` |
| Ajouter une adresse | `collection.add(...)` | `users/{uid}/addresses` | `lib/data/repositories/firestore_addresses_repository.dart` |

---

## 7. Ce qui n'est Pas Encore sur Firebase et Pourquoi

Pour la soutenance, il est très valorisant d'expliquer au professeur les choix d'architecture actuels et la feuille de route d'évolution :

1. **Le Panier d'achat (`MockCartRepository`)** :
   - *État actuel* : Géré en mémoire locale de l'application via Riverpod (`CartNotifier`).
   - *Pourquoi ce choix* : Permet une fluidité absolue à 60 FPS (incrémentation/décrémentation instantanée des quantités sans latence réseau de 200 ms) et permet aux visiteurs non connectés d'acheter sans compte.
   - *Évolution future* : Sauvegarder le panier dans `users/{uid}/cart` lors de la fermeture de l'app pour le retrouver sur tablette ou sur le web.
2. **Les Favoris (`MockFavoritesRepository`)** :
   - *État actuel* : Gérés en mémoire avec simulation de persistance locale.
   - *Pourquoi ce choix* : Isoler la logique UI des favoris avant d'implémenter la synchronisation multi-appareils.
   - *Évolution future* : Créer une sous-collection `users/{uid}/favorites/{productId}` avec écoute en temps réel.
3. **Les Promotions et Remises** :
   - *État actuel* : Gérées exclusivement par l'application Admin. Le Client ne saisit aucun code promo et écrit `promoCode: null` et `discount: 0` lors de la création de la commande.
   - *Pourquoi ce choix* : Sécurité et centralisation métier : le client ne calcule ni ne valide de réduction arbitraire. Si l'Admin applique une remise sur une commande, l'application Client l'affiche fidèlement en lecture seule dans l'écran de détail de commande.
4. **La Décrémentation du Stock** :
   - *État actuel* : Le client vérifie la disponibilité (`inStock`), mais ne modifie pas le champ `stock` du produit.
   - *Pourquoi ce choix* : **Règle de sécurité fondamentale** : un client ne doit jamais avoir le droit d'écrire directement dans la collection `products`.
   - *Évolution future* : Une **Firebase Cloud Function** (déclenchée par `onCreate` sur `orders/{orderId}`) décrémentera automatiquement les stocks sur le serveur avec des droits d'administration sécurisés.
