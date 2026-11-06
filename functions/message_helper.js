/**
 * Helper pur pour déterminer le message de notification en fonction
 * de l'évolution de la commande (changement de statut ou arrivée du coursier).
 * Ne réalise aucun appel réseau : testable unitairement sans dépendances externes.
 */

/**
 * Normalise les statuts provenant indifféremment des apps Client, Admin ou Livreur.
 * @param {string|null|undefined} status
 * @returns {string}
 */
function normalizeStatus(status) {
  if (!status || typeof status !== 'string') return '';
  const s = status.toLowerCase().trim();
  if (s === 'en_attente' || s === 'enattente') return 'pending';
  if (s === 'in_progress' || s === 'inprogress' || s === 'outfordelivery') {
    return 'out_for_delivery';
  }
  return s;
}

/**
 * Détermine le titre et le texte de notification selon le contrat Dokan.
 * @param {object} beforeData - Données Firestore avant modification
 * @param {object} afterData - Données Firestore après modification
 * @param {string} orderId - Identifiant du document commande
 * @returns {{ title: string, body: string, type: string, status: string } | null}
 */
function resolveOrderNotification(beforeData, afterData, orderId) {
  if (!afterData) return null;

  const before = beforeData || {};
  const after = afterData || {};

  const beforeStatus = normalizeStatus(before.status);
  const afterStatus = normalizeStatus(after.status);
  const displayNumber = after.displayNumber || orderId || 'en cours';

  // 1. Détection prioritaire : Arrivée du coursier
  // Le champ driverArrivedAt passe de vide (null/undefined) à renseigné (Timestamp/Date)
  const hadDriverArrived = Boolean(before.driverArrivedAt);
  const hasDriverArrived = Boolean(after.driverArrivedAt);

  if (!hadDriverArrived && hasDriverArrived) {
    return {
      title: 'Le livreur est arrivé 📍',
      body: 'Il est devant chez vous. Préparez le paiement en espèces.',
      type: 'driver_arrived',
      status: afterStatus || 'out_for_delivery',
    };
  }

  // 2. Si le statut n'a pas changé, aucune notification de statut
  if (beforeStatus === afterStatus) {
    return null;
  }

  // 3. Pas de notification pour le statut initial 'pending' (le client vient de valider son panier)
  if (afterStatus === 'pending') {
    return null;
  }

  // 4. Cas spécifique de l'annulation
  if (afterStatus === 'cancelled') {
    // Si l'annulation a été demandée par le client lui-même, pas de notification
    if (after.cancelledBy === 'client' || after.cancelledBy === 'customer') {
      return null;
    }

    return {
      title: 'Commande annulée ❌',
      body: `Votre commande ${displayNumber} a été annulée.`,
      type: 'order_status',
      status: 'cancelled',
    };
  }

  // 5. Statuts opérationnels standards
  switch (afterStatus) {
    case 'confirmed':
      return {
        title: 'Commande acceptée ✅',
        body: `Dokan a accepté votre commande ${displayNumber}.`,
        type: 'order_status',
        status: 'confirmed',
      };

    case 'preparing':
      return {
        title: 'En préparation 👩‍🍳',
        body: `Votre commande ${displayNumber} est en cours de préparation.`,
        type: 'order_status',
        status: 'preparing',
      };

    case 'out_for_delivery':
      return {
        title: 'En route 🚚',
        body: `Le livreur est en chemin avec votre commande ${displayNumber}.`,
        type: 'order_status',
        status: 'out_for_delivery',
      };

    case 'delivered':
      return {
        title: 'Commande livrée 🎉',
        body: 'Merci d\'avoir choisi Dokan !',
        type: 'order_status',
        status: 'delivered',
      };

    default:
      // Les statuts 'failed' ou 'refused' ne déclenchent pas de notification standard
      return null;
  }
}

module.exports = {
  normalizeStatus,
  resolveOrderNotification,
};
