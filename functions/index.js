/**
 * ============================================================================
 * Cloud Function Dokan (v2 Firestore Trigger)
 * Surveille les modifications sur la collection orders/{orderId} et envoie
 * les notifications push FCM aux terminaux du client concerné.
 * 
 * SÉCURITÉ :
 * - Fonctionne exclusivement côté serveur avec le SDK Firebase Admin.
 * - Aucune clé secrète ni compte de service n'est présent dans l'APK Client.
 * - Ne journalise aucune donnée personnelle (nom, téléphone, adresse).
 * ============================================================================
 */

const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');
const { resolveOrderNotification } = require('./message_helper');

// Initialisation idempotente du SDK Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Région recommandée : europe-west1 (Belgique, proche Tunisie / EMEA)
 * ou région par défaut du bucket Firestore.
 */
const REGION = 'europe-west1';

/**
 * Déclencheur Cloud Function sur mise à jour d'une commande.
 */
exports.onOrderUpdatedNotifyClient = onDocumentUpdated(
  {
    document: 'orders/{orderId}',
    region: REGION,
  },
  async (event) => {
    const orderId = event.params.orderId;
    const beforeData = event.data.before ? event.data.before.data() : null;
    const afterData = event.data.after ? event.data.after.data() : null;

    if (!afterData) {
      logger.info(`[Commande ${orderId}] Document supprimé ou vide. Aucun envoi.`);
      return null;
    }

    const userId = afterData.userId;
    if (!userId) {
      logger.info(`[Commande ${orderId}] Aucun userId associé. Aucun envoi.`);
      return null;
    }

    // 1. Détermination du message à notifier
    const notification = resolveOrderNotification(beforeData, afterData, orderId);
    if (!notification) {
      // Aucun changement significatif de statut ou d'arrivée du livreur
      return null;
    }

    // 2. Récupération des tokens de notification du client dans users/{userId}/devices
    const devicesSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('devices')
      .get();

    if (devicesSnapshot.empty) {
      logger.info(`[Commande ${orderId}] Client ${userId} : aucun terminal enregistré.`);
      return null;
    }

    const tokens = devicesSnapshot.docs.map((doc) => doc.id).filter(Boolean);
    if (tokens.length === 0) {
      return null;
    }

    // 3. Construction du payload de notification conforme au contrat Dokan
    const multicastMessage = {
      tokens,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        orderId: String(orderId),
        type: String(notification.type),
        status: String(notification.status),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'orders',
          sound: 'default',
        },
      },
    };

    // 4. Envoi groupé via Firebase Cloud Messaging
    try {
      const response = await admin.messaging().sendEachForMulticast(multicastMessage);

      let successCount = response.successCount;
      let failureCount = response.failureCount;

      logger.info(
        `[Commande ${orderId}] Statut: ${notification.status} | Envois FCM: ${successCount} réussis, ${failureCount} échoués.`
      );

      // 5. Nettoyage automatique des tokens invalides ou désinstallés
      if (failureCount > 0) {
        const batch = db.batch();
        let tokensToDeleteCount = 0;

        response.responses.forEach((resp, idx) => {
          if (!resp.success && resp.error) {
            const errorCode = resp.error.code;
            if (
              errorCode === 'messaging/registration-token-not-registered' ||
              errorCode === 'messaging/invalid-registration-token'
            ) {
              const staleToken = tokens[idx];
              const staleRef = db
                .collection('users')
                .doc(userId)
                .collection('devices')
                .doc(staleToken);

              batch.delete(staleRef);
              tokensToDeleteCount++;
            }
          }
        });

        if (tokensToDeleteCount > 0) {
          await batch.commit();
          logger.info(`[Client ${userId}] ${tokensToDeleteCount} token(s) expiré(s) nettoyé(s).`);
        }
      }
    } catch (error) {
      logger.error(`[Commande ${orderId}] Erreur lors de l'envoi multicast FCM:`, error);
    }

    return null;
  }
);
