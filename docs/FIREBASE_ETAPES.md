# Guide pas à pas : Configuration Firebase Console pour Dokan

Ce guide détaille les actions exactes à réaliser dans la console Firebase pour activer les règles de sécurité et les index composites pour les commandes et les adresses, **sans écraser le travail des applications Admin et Livreur**.

---

## 1. Mise à jour des Règles de Sécurité (Firestore Rules)

Le projet Firebase étant **partagé** avec les applications Admin et Livreur, **ne remplacez jamais l'intégralité des règles existantes sans vérifier**.

### Étapes dans la Console Firebase :
1. Ouvrez votre navigateur sur [console.firebase.google.com](https://console.firebase.google.com).
2. Sélectionnez le projet : **`ee-comeerce`**.
3. Dans le menu de gauche (rubrique *Build* ou *Création*), cliquez sur **Firestore Database**.
4. Cliquez sur l'onglet **Règles** (*Rules*).
5. Vous visualisez les règles actuellement publiées.
6. **Conservez toutes les règles existantes** (notamment sur `products`) et **ajoutez** à l'intérieur de `match /databases/{database}/documents { ... }` les blocs suivants :

```javascript
    // =========================================================================
    // NOUVELLES RÈGLES CLIENT : ADRESSES (users/{uid}/addresses)
    // =========================================================================
    match /users/{userId}/addresses/{addressId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // =========================================================================
    // NOUVELLES RÈGLES CLIENT : COMMANDES (orders/{orderId})
    // =========================================================================
    match /orders/{orderId} {
      // 1. Lecture : uniquement ses propres commandes
      // (À COMPLÉTER par vos amies : || request.auth.token.role in ['admin', 'driver'])
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;

      // 2. Création : uniquement sa propre commande avec statut 'pending'
      allow create: if request.auth != null 
                    && request.resource.data.userId == request.auth.uid
                    && request.resource.data.status == 'pending'
                    && request.resource.data.total is number
                    && request.resource.data.items is list
                    && request.resource.data.items.size() > 0;

      // 3. Modification : annulation uniquement si 'pending' -> 'cancelled'
      // (À COMPLÉTER par vos amies pour permettre à l'Admin et au Livreur de faire avancer le statut)
      allow update: if request.auth != null 
                    && resource.data.userId == request.auth.uid
                    && resource.data.status == 'pending'
                    && request.resource.data.status == 'cancelled'
                    && request.resource.data.userId == resource.data.userId
                    && request.resource.data.total == resource.data.total
                    && request.resource.data.items == resource.data.items
                    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status', 'statusHistory', 'updatedAt']);

      // 4. Suppression interdite côté client
      allow delete: if false;
    }
```
7. Cliquez sur le bouton bleu **Publier** (*Publish*).

---

## 2. Création de l'Index Composite pour « Mes commandes »

La requête qui alimente l'écran « Mes commandes » filtre par utilisateur (`userId == uid`) et trie par date antichronologique (`orderBy createdAt desc`). Elle nécessite un **index composite**.

### Méthode A — La plus simple (en un clic via le lien d'erreur) :
1. Lancez l'application Dokan et rendez-vous sur l'écran **Mes commandes**.
2. Dans la console de débogage Flutter (terminal ou panneau Run), Firebase affichera un message d'avertissement contenant une URL commençant par :
   `https://console.firebase.google.com/v1/r/project/ee-comeerce/firestore/indexes?create_composite=...`
3. Cliquez directement sur ce lien : la console Firebase s'ouvrira avec les champs pré-remplis.
4. Cliquez sur **Créer l'index**.

### Méthode B — Manuelle dans la Console Firebase :
1. Allez dans **Firestore Database** → onglet **Index** (*Indexes*).
2. Dans la section *Index composites*, cliquez sur **Ajouter un index** (*Create Index*).
3. Renseignez les paramètres suivants :
   - **ID de la collection** : `orders`
   - **Portée de la requête** : `Collection`
   - **Premier champ** :
     - Chemin du champ : `userId`
     - Ordre d'index : `Croissant` (*Ascending*)
   - **Deuxième champ** (cliquez sur *Ajouter un champ*) :
     - Chemin du champ : `createdAt`
     - Ordre d'index : `Décroissant` (*Descending*)
4. Cliquez sur **Créer**. L'index passera de l'état *En cours de création* à **Activé** en 1 à 3 minutes.

---

## 3. Comment tester et simuler l'Admin & le Livreur en direct

Pour vérifier que le flux temps réel fonctionne parfaitement sans attendre l'app Admin :

1. **Passer une commande test dans l'app Dokan** :
   - Connectez-vous avec votre compte utilisateur.
   - Ajoutez un ou deux articles au panier.
   - Cliquez sur « Continuer la commande », ajoutez une adresse, puis cliquez sur **Confirmer la commande**.
   - Vous arrivez sur l'écran d'animation de succès avec le numéro (ex : `DK-261101-7F3K`).
2. **Vérifier les données dans Firestore** :
   - Dans la console Firebase → **Firestore Database** → onglet **Données**.
   - Vous verrez apparaître la collection **`orders`** avec votre nouveau document.
3. **Simuler l'avancement du statut par l'Admin et le Livreur** :
   - Dans la console Firebase, cliquez sur le document de votre commande.
   - Modifiez le champ `status` manuellement :
     - `pending` *(créé par le client)*
     - `confirmed` *(confirmé par l'Admin)*
     - `preparing` *(en préparation)*
     - `out_for_delivery` *(en livraison avec le livreur)*
     - `delivered` *(livré au client)*
   - Dans le tableau `statusHistory`, vous pouvez ajouter une map : `{status: "preparing", at: Timestamp}`.
   - **Regardez votre écran mobile** : l'écran *Mes commandes* et l'écran *Suivi de commande* se mettent à jour **instantanément en direct (Stream)** avec la nouvelle couleur, le ruban et le camion sur la barre d'étapes !
