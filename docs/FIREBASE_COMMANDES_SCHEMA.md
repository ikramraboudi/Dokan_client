# Schéma Officiel de la Collection `orders` (Dokan E-commerce)

Ce document constitue la **spécification d'interopérabilité officielle** partagée entre l'application **Client (Dokan)**, l'application **Admin** et l'application **Livreur**. Toutes les applications lisent et écrivent selon cette structure exacte.

---

## 1. Vue d'ensemble de la Collection

- **Chemin Firestore** : `orders/{orderId}` (l'identifiant `orderId` est généré automatiquement par Firestore).
- **Principe fondamental des copies (snapshots)** : Les articles (`items`) et l'adresse de livraison (`deliveryAddress`) sont copiés au moment de la commande. Si l'Admin modifie ultérieurement le prix d'un produit dans `products`, l'ancienne commande conserve fidèlement le prix historique payé par le client.

---

## 2. Table des Champs et Types

| Champ | Type Firestore | Obligatoire ? | Rempli / Modifié par | Description |
|---|---|---|---|---|
| `displayNumber` | `string` | Oui | Client | Numéro lisible formaté : `DK-AAMMJJ-XXXX` (ex: `DK-261101-7F3K`) |
| `userId` | `string` | Oui | Client | UID Firebase Auth du client ayant passé la commande |
| `customerName` | `string` | Oui | Client | Nom complet du destinataire / client |
| `customerPhone` | `string` | Oui | Client | Numéro de téléphone joignable pour la livraison |
| `status` | `string` | Oui | Client / Admin / Livreur | Statut en cours (voir énumération ci-dessous) |
| `statusHistory` | `array<map>` | Oui | Client / Admin / Livreur | Chronologie des étapes : `[{status: string, at: Timestamp}]` |
| `items` | `array<map>` | Oui | Client | Lignes d'articles commandés (voir schéma d'un item ci-dessous) |
| `itemCount` | `number` | Oui | Client | Quantité physique totale d'articles (`sum(quantity)`) |
| `subtotal` | `number` | Oui | Client | Montant brut hors réductions (en Dinars Tunisiens) |
| `discount` | `number` | Oui | Admin (Client écrit 0) | Montant total déduit par une promotion éventuelle. Les promotions sont gérées par l'app Admin ; le Client écrit toujours 0 |
| `promoCode` | `string` \| `null` | Non | Admin (Client écrit null) | Code promo éventuel renseigné par l'Admin. Le Client n'écrit jamais de code promo (écrit `null`) |
| `deliveryFee` | `number` | Oui | Client | Frais d'expédition (ex: 7.000 ou 0.000) |
| `total` | `number` | Oui | Client | Montant final TTC à régler à la livraison |
| `currency` | `string` | Oui | Client | Monnaie officielle (`"TND"`) |
| `deliveryAddress` | `map` | Oui | Client | Copie de l'adresse (voir schéma adresse ci-dessous) |
| `deliveryMode` | `string` | Oui | Client | Mode de livraison (`"standard"`) |
| `paymentMethod` | `string` | Oui | Client | Méthode de paiement (`"cash_on_delivery"`) |
| `paymentStatus` | `string` | Oui | Client / Admin / Livreur | `"unpaid"` à la création, `"paid"` à la livraison |
| `estimatedDelivery` | `Timestamp` \| `null` | Non | **Admin** | Date estimée de livraison choisie par l'Admin (ne pas inventer) |
| `driver` | `map` \| `null` | Non | **Admin / Livreur** | Livreur assigné : `{driverId, name, phone}` ou `null` |
| `createdAt` | `Timestamp` | Oui | Client | Date de création serveur (`FieldValue.serverTimestamp()`) |
| `updatedAt` | `Timestamp` | Oui | Tous | Dernière mise à jour (`FieldValue.serverTimestamp()`) |

---

## 3. Schéma des Sous-Objets (Maps)

### Ligne d'article (`items[i]`)
```json
{
  "productId": "string (ID du produit dans la collection products)",
  "name": "string (Nom du produit au moment de la commande)",
  "imageUrl": "string (URL de la miniature du produit)",
  "unitPrice": 89.900,
  "quantity": 2,
  "variantLabel": "string? (ex: 'Taille M, Blanc')",
  "lineTotal": 179.800
}
```

### Adresse de livraison (`deliveryAddress`)
```json
{
  "recipientName": "Mohamed Ben Salah",
  "phone": "21000000",
  "addressLine": "15 Rue de la Liberté, Apt 4B",
  "city": "Tunis",
  "zone": "El Menzah",
  "additionalInfo": "Étage 3",
  "deliveryInstructions": "Appeler à l'interphone"
}
```

### Informations du Livreur (`driver`)
```json
{
  "driverId": "string? (UID Firebase du livreur)",
  "name": "Karim Trad",
  "phone": "98123456"
}
```

---

## 4. Cycle de Vie et Évolution des Statuts (`status`)

| Valeur stockée | Libellé français | Qui la fait évoluer ? | Quand ? |
|---|---|---|---|
| `pending` | En attente | **Client** | Dès que le client clique sur « Confirmer la commande » |
| `confirmed` | Confirmée | **Admin** | Quand l'Admin valide la disponibilité de la commande |
| `preparing` | En préparation | **Admin** | Quand la commande est en cours d'emballage en entrepôt |
| `out_for_delivery` | En livraison | **Admin ou Livreur** | Quand le livreur prend en charge le colis pour la tournée |
| `delivered` | Livrée | **Livreur ou Admin** | Quand le client a réceptionné et payé le colis |
| `cancelled` | Annulée | **Client** *(uniquement si pending)* ou **Admin** | En cas de désistement ou d'imprévu |

> **Règle importante pour l'historique** : À chaque changement de statut par l'Admin ou le Livreur, ajoutez obligatoirement une entrée dans le tableau `statusHistory` :
> ```json
> {
>   "status": "out_for_delivery",
>   "at": Timestamp.now()
> }
> ```
> Cela permet à l'application Client de tracer la chronologie visuelle en temps réel.

---

## 5. Exemple de Document JSON Complet dans `orders`

```json
{
  "displayNumber": "DK-261101-7F3K",
  "userId": "WbulqStAkMeWZblkdhehLwMBs8p2",
  "customerName": "Mohamed Ben Salah",
  "customerPhone": "21000000",
  "status": "out_for_delivery",
  "statusHistory": [
    {
      "status": "pending",
      "at": "2026-11-01T08:30:00Z"
    },
    {
      "status": "confirmed",
      "at": "2026-11-01T09:15:00Z"
    },
    {
      "status": "preparing",
      "at": "2026-11-01T10:00:00Z"
    },
    {
      "status": "out_for_delivery",
      "at": "2026-11-01T11:20:00Z"
    }
  ],
  "items": [
    {
      "productId": "prod_chemise_lin",
      "name": "Chemise en lin premium",
      "imageUrl": "https://picsum.photos/seed/chemise/600/600",
      "unitPrice": 89.900,
      "quantity": 1,
      "variantLabel": "Bleu ciel, L",
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
    "addressLine": "15 Rue de la Liberté",
    "city": "Tunis",
    "zone": "Centre Ville",
    "additionalInfo": "Immeuble B, 2ème étage",
    "deliveryInstructions": "Sonner à l'interphone Ben Salah"
  },
  "deliveryMode": "standard",
  "paymentMethod": "cash_on_delivery",
  "paymentStatus": "unpaid",
  "estimatedDelivery": "2026-11-02T16:00:00Z",
  "driver": {
    "driverId": "driver_uid_123",
    "name": "Karim Trad",
    "phone": "98123456"
  },
  "createdAt": "2026-11-01T08:30:00Z",
  "updatedAt": "2026-11-01T11:20:00Z"
}
```
