const assert = require('assert');
const { resolveOrderNotification, normalizeStatus } = require('../message_helper');

console.log('--- Démarrage des tests unitaires de resolveOrderNotification ---');

// Test 1 : Pas de notification pour 'pending'
const notifPending = resolveOrderNotification(
  { status: 'pending' },
  { status: 'pending', displayNumber: 'DK-261105-0001' },
  'order_1'
);
assert.strictEqual(notifPending, null, 'Doit retourner null quand le statut ne change pas');

// Test 2 : Commande acceptée ('confirmed')
const notifConfirmed = resolveOrderNotification(
  { status: 'pending' },
  { status: 'confirmed', displayNumber: 'DK-261105-0001' },
  'order_1'
);
assert.notStrictEqual(notifConfirmed, null);
assert.strictEqual(notifConfirmed.title, 'Commande acceptée ✅');
assert.strictEqual(notifConfirmed.body, 'Dokan a accepté votre commande DK-261105-0001.');
assert.strictEqual(notifConfirmed.type, 'order_status');
assert.strictEqual(notifConfirmed.status, 'confirmed');

// Test 3 : En préparation ('preparing')
const notifPreparing = resolveOrderNotification(
  { status: 'confirmed' },
  { status: 'preparing', displayNumber: 'DK-261105-0001' },
  'order_1'
);
assert.strictEqual(notifPreparing.title, 'En préparation 👩‍🍳');
assert.strictEqual(notifPreparing.body, 'Votre commande DK-261105-0001 est en cours de préparation.');

// Test 4 : En route ('out_for_delivery' ou 'in_progress')
const notifDelivery = resolveOrderNotification(
  { status: 'preparing' },
  { status: 'in_progress', displayNumber: 'DK-261105-0001' },
  'order_1'
);
assert.strictEqual(notifDelivery.title, 'En route 🚚');
assert.strictEqual(notifDelivery.body, 'Le livreur est en chemin avec votre commande DK-261105-0001.');
assert.strictEqual(notifDelivery.status, 'out_for_delivery');

// Test 5 : Arrivée du livreur ('driverArrivedAt')
const notifDriverArrived = resolveOrderNotification(
  { status: 'in_progress', driverArrivedAt: null },
  { status: 'in_progress', driverArrivedAt: new Date(), displayNumber: 'DK-261105-0001' },
  'order_1'
);
assert.strictEqual(notifDriverArrived.title, 'Le livreur est arrivé 📍');
assert.strictEqual(notifDriverArrived.body, 'Il est devant chez vous. Préparez le paiement en espèces.');
assert.strictEqual(notifDriverArrived.type, 'driver_arrived');

// Test 6 : Commande livrée ('delivered')
const notifDelivered = resolveOrderNotification(
  { status: 'in_progress' },
  { status: 'delivered', displayNumber: 'DK-261105-0001' },
  'order_1'
);
assert.strictEqual(notifDelivered.title, 'Commande livrée 🎉');
assert.strictEqual(notifDelivered.body, 'Merci d\'avoir choisi Dokan !');

// Test 7 : Annulation par le client -> pas de notification
const notifCancelledByClient = resolveOrderNotification(
  { status: 'pending' },
  { status: 'cancelled', cancelledBy: 'client', displayNumber: 'DK-261105-0001' },
  'order_1'
);
assert.strictEqual(notifCancelledByClient, null, 'Pas de notification si le client annule lui-même');

// Test 8 : Annulation par l'admin -> notification d'annulation
const notifCancelledByAdmin = resolveOrderNotification(
  { status: 'preparing' },
  { status: 'cancelled', cancelledBy: 'admin', displayNumber: 'DK-261105-0001' },
  'order_1'
);
assert.strictEqual(notifCancelledByAdmin.title, 'Commande annulée ❌');
assert.strictEqual(notifCancelledByAdmin.body, 'Votre commande DK-261105-0001 a été annulée.');

console.log('✅ Tous les tests unitaires Node.js de message_helper sont validés avec succès !');
