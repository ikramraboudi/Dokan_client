# Points d'Attention et Axes d'Amélioration (Dokan Client)

> **Document de transparence technique pour la soutenance orale**  
> Ce document recense de manière honnête et constructive les particularités, incohérences mineures, choix d'architecture temporaires et limites techniques relevés dans la base de code Dokan Client sans modification de logique, conformément aux consignes du projet.

---

## Tableau Récapitulatif des Points Relevés

| N° | Domaine | Fichier concerné | Description succincte | Risque identifié | Correction recommandée |
|---|---|---|---|---|---|
| **1** | Navigation | `lib/core/navigation/app_router.dart` (lignes 170-210) | Bloc de routes dupliqué à l'identique (checkout, confirmation, commandes, adresses) | Aucun plantage (GoRouter utilise la 1ère occurrence), mais alourdit la maintenance | Supprimer le second bloc en doublon |
| **2** | Interface & Débogage | `lib/feature/profile/profile_screen.dart` (lignes 180-210) | Bouton « Simuler session expirée » visible dans le profil client | Présent dans l'interface finale accessible à l'utilisateur final | Encadrer par `if (kDebugMode)` pour le masquer en production |
| **3** | Persistance des données | `lib/data/mock/mock_cart_repository.dart` et `mock_favorites_repository.dart` | Panier et favoris conservés en mémoire vive uniquement | Perte du panier si l'application est tuée par le système Android | Migrer vers des sous-collections Firestore (`users/{uid}/cart`) |
| **4** | Gestion des stocks | `lib/data/repositories/firestore_orders_repository.dart` (ligne 172) | Stock non décrémenté lors de la commande | Risque de survente (« overselling ») si 2 clients commandent en même temps | Implémenter une Cloud Function Firebase `onOrderCreated` |
| **5** | Numérotation commandes | `lib/data/models/order_model.dart` (`generateDisplayNumber`) | Numéro `DK-AAMMJJ-XXXX` généré aléatoirement côté client | Risque théorique de collision à très fort volume | Générer un numéro séquentiel via transaction ou Cloud Function |
| **6** | Codes promotionnels | `lib/data/models/promo_code.dart` (`PromoRules`) | Liste des codes promo codée en dur dans l'application (`Dokan10`) | L'administrateur ne peut pas créer de code promo sans recompiler l'app | Créer une collection Firestore `promo_codes/{code}` |
| **7** | Convention Dart | `pubspec.yaml` (ligne 1 : `name: Dokan_client`) | Présence d'une lettre majuscule dans le nom de package Dart | Avertissement d'information (info) dans le rapport `flutter analyze` | Renommer le package en `dokan_client` en minuscules |

---

## Analyse Détaillée des 7 Points

---

### 1. Doublons de Déclaration de Routes dans GoRouter

* **Fichier** : `lib/core/navigation/app_router.dart` (lignes 127-168 et lignes 170-210).
* **Description** : Les 7 routes suivantes sont enregistrées deux fois consécutivement dans la liste `routes` de l'instance `GoRouter` :
  - `AppRoutes.checkout` (`/checkout`)
  - `${AppRoutes.orderConfirmation}/:id`
  - `AppRoutes.myOrders` (`/orders`)
  - `${AppRoutes.myOrders}/:id`
  - `AppRoutes.addresses` (`/addresses`)
  - `AppRoutes.addAddress` (`/addresses/add`)
  - `${AppRoutes.editAddress}/:id`
* **Risque** : `GoRouter` résout les routes dans leur ordre de déclaration et sélectionne la première occurrence valide. Il n'y a donc pas de dysfonctionnement à l'exécution, mais cela crée une dette technique et un risque de divergence si un développeur modifie le premier bloc sans mettre à jour le second.
* **Correction suggérée** : Supprimer purement et simplement le second bloc (lignes 170-210) lors du prochain nettoyage de code.

---

### 2. Bouton de Débogage « Simuler session expirée » Visible dans le Profil

* **Fichier** : `lib/feature/profile/profile_screen.dart` (≈ lignes 180-210) et `lib/core/session/session_provider.dart` (`simulateSessionExpired()`).
* **Description** : L'écran de profil client intègre une tuile de liste active intitulée « Simuler session expirée - Test du hook onSessionExpired sans perte du panier ».
* **Contexte & Justification actuelle** : Ce composant a été conçu comme un **outil pédagogique de démonstration** pour prouver lors de l'évaluation que l'application repasse en mode visiteur avec un message d'erreur tout en conservant scrupuleusement les articles du panier en mémoire.
* **Risque en production** : Sur une application publiée sur les magasins d'applications (Google Play Store), un utilisateur pourrait cliquer sur cette option et se déconnecter de manière involontaire.
* **Correction suggérée** : Conditionner l'affichage avec la constante Flutter standard :
  ```dart
/*  if (kDebugMode) ...[
    _buildSimulateSessionExpiredTile(context, ref),
  ],
  ```
*/
---

### 3. Panier et Favoris Gérés en Mémoire Vive (Non Synchronisés sur Firestore)

* **Fichiers** : `lib/data/mock/mock_cart_repository.dart` et `lib/data/mock/mock_favorites_repository.dart`.
* **Description** : Bien que le catalogue de produits, les commandes et les adresses soient pleinement connectés à Cloud Firestore en temps réel, le panier d'achat et les favoris utilisent des référentiels locaux en mémoire (`MockCartRepository` et `MockFavoritesRepository`) gérés par Riverpod.
* **Contexte & Justification actuelle** : Ce choix a permis de développer une interface extrêmement réactive (60 FPS) sans latence réseau à l'incrémentation des quantités, et d'offrir une navigation complète aux visiteurs sans les forcer à ouvrir un compte.
* **Risque** : Si l'utilisateur ferme complètement l'application (ou si le système Android la termine par manque de mémoire vive), son panier et ses favoris sont réinitialisés.
* **Correction suggérée** : Implémenter une synchronisation hybride :
  1. Stocker le panier local dans `shared_preferences` ou `Hive` pour le mode visiteur et hors-ligne.
  2. Synchroniser automatiquement avec une sous-collection Firestore `users/{uid}/cart` dès que le client est authentifié.

---

### 4. Décrémentation du Stock Non Réalisée Côté Client

* **Fichier** : `lib/data/repositories/firestore_orders_repository.dart` (commentaire explicite ligne 172).
* **Description** : Au moment de `createOrder()`, l'application vérifie que l'article est disponible (`availability != 'outOfStock'` et `inStock != false`), mais ne modifie pas le champ stock du document `products/{productId}`.
* **Contexte & Justification actuelle** : **C'est une excellente pratique de sécurité** : un client mobile ne doit jamais posséder les privilèges d'écriture sur le catalogue des produits (sinon un utilisateur pirate pourrait modifier les prix ou vider les stocks d'un concurrent).
* **Risque** : Si deux clients valident en même temps la commande du dernier article disponible, les deux commandes seront créées au statut `pending` avant que l'Admin ne constate la rupture.
* **Correction suggérée** : Déployer une fonction sans serveur **Firebase Cloud Function** avec déclencheur `onDocumentCreated('orders/{orderId}')` :
  ```javascript
  exports.onOrderCreated = functions.firestore
    .document('orders/{orderId}')
    .onCreate(async (snap, context) => {
      const order = snap.data();
      // Décrémentation atomique sécurisée côté serveur
    });
  ```

---

### 5. Numéro Lisible de Commande (`displayNumber`) Généré Côté Client

* **Fichier** : `lib/data/models/order_model.dart` → méthode statique `generateDisplayNumber()`.
* **Description** : Le numéro de commande (ex: `DK-261101-7F3K`) est calculé sur le téléphone mobile par concaténation de la date du jour et de 4 caractères aléatoires majuscules tirés de `0123456789ABCDEFGHJKLMNPQRSTUVWXYZ`.
* **Contexte & Justification actuelle** : Cette solution fonctionne parfaitement sans nécessiter d'infrastructure serveur complexe pour un projet étudiant et évite d'exposer l'identifiant opaque Firestore de 20 caractères au client.
* **Risque** : Avec 4 caractères choisis parmi 32, il existe 1 048 576 combinaisons par jour. Le risque de collision est infime à l'échelle académique mais deviendrait réel sur une plateforme traitant des millions de transactions par jour.
* **Correction suggérée** : Gérer un document de compteur séquentiel dans Firestore (`counters/orders`) mis à jour dans une transaction atomique, ou confier l'attribution du numéro à la Cloud Function de création.

---

### 6. Codes Promotionnels Gérés dans le Code Source Client

* **Fichier** : `lib/data/models/promo_code.dart` (`PromoRules`).
* **Description** : Le code promo `Dokan10` (-10%) est enregistré dans une classe Dart locale annotée d'un commentaire : `// TODO Firebase : les codes promo seront gérés par l'Admin dans Firestore`.
* **Risque** : L'équipe marketing ou l'administrateur ne peut pas lancer une nouvelle opération promotionnelle temporaire (ex: soldes d'été, réduction de bienvenue) sans demander une recompilation et une mise à jour complète de l'application sur le Play Store.
* **Correction suggérée** : Déplacer les règles promotionnelles dans une collection Firestore `promo_codes/{codeId}` contenant : `code`, `discountPercent`, `startDate`, `endDate`, `minSubtotal`, `maxUsageCount` et `currentUsageCount`.

---

### 7. Avertissement Stylistique sur le Nom de Package dans `pubspec.yaml`

* **Fichier** : `pubspec.yaml` (ligne 1).
* **Description** : Le fichier déclare : `name: Dokan_client`. L'outil `flutter analyze` émet une information de style :
  `The package name 'Dokan_client' isn't a lower_case_with_underscores identifier.`
* **Risque** : Aucun risque d'exécution : l'application compile et tourne sans anomalie. C'est simplement une recommandation de style officielle du langage Dart (qui préconise `dokan_client` tout en minuscules).
* **Correction suggérée** : Renommer la ligne en `name: dokan_client` si une standardisation complète des conventions Dart est souhaitée.
