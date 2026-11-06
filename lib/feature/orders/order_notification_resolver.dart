/// ============================================================================
/// RÔLE DU FICHIER : Résolveur pur des notifications de commande Dokan (mode gratuit 100% autonome).
/// Détermine les transitions de statut et l'arrivée du livreur sans aucun appel réseau.
/// INTERAGIT AVEC : LocalOrderTrackerService, NotificationService, OrderUiModel.
/// POUR L'ORAL : « OrderNotificationResolver est une fonction pure qui compare l'ancien état local
/// et le nouvel état Firestore pour déclencher exactement une notification locale par transition. »
/// ============================================================================
library;

/// État persistant d'une commande mémorisé localement dans SharedPreferences.
class OrderNotificationState {
  final String status;
  final bool driverArrivedNotified;
  final bool cancelledByClient;

  const OrderNotificationState({
    required this.status,
    this.driverArrivedNotified = false,
    this.cancelledByClient = false,
  });

  Map<String, dynamic> toJson() => {
        'status': status,
        'driverArrivedNotified': driverArrivedNotified,
        'cancelledByClient': cancelledByClient,
      };

  factory OrderNotificationState.fromJson(Map<String, dynamic> json) {
    return OrderNotificationState(
      status: json['status'] as String? ?? '',
      driverArrivedNotified: json['driverArrivedNotified'] as bool? ?? false,
      cancelledByClient: json['cancelledByClient'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderNotificationState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          driverArrivedNotified == other.driverArrivedNotified &&
          cancelledByClient == other.cancelledByClient;

  @override
  int get hashCode =>
      status.hashCode ^
      driverArrivedNotified.hashCode ^
      cancelledByClient.hashCode;
}

/// Contenu textuel et identifiant d'une notification locale prête à afficher.
class OrderNotificationPayload {
  final int notificationId;
  final String title;
  final String body;
  final String orderId;

  const OrderNotificationPayload({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.orderId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderNotificationPayload &&
          runtimeType == other.runtimeType &&
          notificationId == other.notificationId &&
          title == other.title &&
          body == other.body &&
          orderId == other.orderId;

  @override
  int get hashCode =>
      notificationId.hashCode ^
      title.hashCode ^
      body.hashCode ^
      orderId.hashCode;

  @override
  String toString() =>
      'OrderNotificationPayload(id: $notificationId, title: "$title", body: "$body", orderId: "$orderId")';
}

/// Résolveur logique pure déterminant si un changement de commande nécessite une alerte.
class OrderNotificationResolver {
  OrderNotificationResolver._();

  /// Calcule un ID numérique stable (positif sur 31 bits) pour la notification.
  /// Ainsi, chaque nouvelle mise à jour d'une même commande remplace l'ancienne
  /// au lieu d'empiler des dizaines de notifications dans le centre Android.
  static int stableNotificationId(String orderId) {
    if (orderId.isEmpty) return 1000;
    return orderId.hashCode.abs() % 0x7FFFFFFF;
  }

  /// Normalisation tolérante des statuts issus des applications Client, Admin ou Livreur
  /// (supporte anglais, français avec/sans accents, tirets et underscores).
  static String normalizeStatus(String? status) {
    if (status == null || status.trim().isEmpty) return '';
    final s = status
        .toLowerCase()
        .trim()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll(' ', '_')
        .replaceAll('-', '_');

    if (s == 'en_attente' ||
        s == 'enattente' ||
        s == 'pending' ||
        s == 'attente' ||
        s == 'recue' ||
        s == 'nouvelle') {
      return 'pending';
    }

    if (s == 'confirmed' ||
        s == 'confirmee' ||
        s == 'confirme' ||
        s == 'acceptee' ||
        s == 'accepte' ||
        s == 'validee' ||
        s == 'valide' ||
        s == 'approuvee' ||
        s == 'approuve') {
      return 'confirmed';
    }

    if (s == 'preparing' ||
        s == 'en_preparation' ||
        s == 'enpreparation' ||
        s == 'preparation' ||
        s == 'en_cours_de_preparation') {
      return 'preparing';
    }

    if (s == 'in_progress' ||
        s == 'inprogress' ||
        s == 'out_for_delivery' ||
        s == 'outfordelivery' ||
        s == 'en_livraison' ||
        s == 'enlivraison' ||
        s == 'livraison' ||
        s == 'en_route' ||
        s == 'enroute') {
      return 'out_for_delivery';
    }

    if (s == 'delivered' ||
        s == 'livree' ||
        s == 'livre' ||
        s == 'terminee' ||
        s == 'termine') {
      return 'delivered';
    }

    if (s == 'cancelled' ||
        s == 'canceled' ||
        s == 'annulee' ||
        s == 'annule' ||
        s == 'refusee' ||
        s == 'refuse') {
      return 'cancelled';
    }

    return s;
  }

  /// FONCTION PURE :
  /// Compare l'ancien état connu de la commande et le nouvel état Firestore.
  /// Renvoie le payload de la notification locale à émettre, ou `null` si aucune
  /// notification ne doit être affichée.
  static OrderNotificationPayload? notificationFor({
    required OrderNotificationState? oldState,
    required String orderId,
    required String displayNumber,
    required String rawStatus,
    required bool hasDriverArrived,
    required bool isFirstSync,
    bool isDetailScreenOpen = false,
    String? cancelledBy,
  }) {
    // Règle 1 : Première synchronisation (lancement ou connexion) -> mémorise sans spammer
    if (isFirstSync) {
      return null;
    }

    // Règle 2 : Écran de détail déjà ouvert sous les yeux du client -> pas de popup
    if (isDetailScreenOpen) {
      return null;
    }

    final normStatus = normalizeStatus(rawStatus);
    final number = displayNumber.isNotEmpty ? displayNumber : orderId;
    final notifId = stableNotificationId(orderId);

    // Règle 3 : Détection prioritaire de l'arrivée du livreur devant le domicile
    final hadDriverArrived = oldState?.driverArrivedNotified ?? false;
    if (hasDriverArrived && !hadDriverArrived) {
      return OrderNotificationPayload(
        notificationId: notifId,
        title: 'Le livreur est arrivé 📍',
        body: 'Il est devant chez vous. Préparez le paiement en espèces.',
        orderId: orderId,
      );
    }

    // Règle 4 : Si le statut n'a pas changé, aucune notification
    final oldNormStatus =
        oldState != null ? normalizeStatus(oldState.status) : null;
    if (oldNormStatus == normStatus) {
      return null;
    }

    // Règle 5 : Pas de notification pour le statut initial 'pending'
    if (normStatus == 'pending') {
      return null;
    }

    // Règle 6 : Commande annulée
    if (normStatus == 'cancelled') {
      final isClientCancelled = (cancelledBy == 'client' ||
          cancelledBy == 'customer' ||
          (oldState?.cancelledByClient ?? false));
      // Si l'annulation émane du client lui-même, pas de notification
      if (isClientCancelled) {
        return null;
      }
      return OrderNotificationPayload(
        notificationId: notifId,
        title: 'Commande annulée ❌',
        body: 'Votre commande $number a été annulée.',
        orderId: orderId,
      );
    }

    // Règle 7 : Statuts opérationnels Dokan
    switch (normStatus) {
      case 'confirmed':
        return OrderNotificationPayload(
          notificationId: notifId,
          title: 'Commande acceptée ✅',
          body: 'Dokan a accepté votre commande $number.',
          orderId: orderId,
        );
      case 'preparing':
        return OrderNotificationPayload(
          notificationId: notifId,
          title: 'En préparation 👩‍🍳',
          body: 'Votre commande $number est en cours de préparation.',
          orderId: orderId,
        );
      case 'out_for_delivery':
        return OrderNotificationPayload(
          notificationId: notifId,
          title: 'En route 🚚',
          body: 'Le livreur est en chemin avec votre commande $number.',
          orderId: orderId,
        );
      case 'delivered':
        return OrderNotificationPayload(
          notificationId: notifId,
          title: 'Commande livrée 🎉',
          body: 'Merci d\'avoir choisi Dokan !',
          orderId: orderId,
        );
      default:
        return null;
    }
  }

  /// Calcule le nouvel état persistant à sauvegarder après traitement.
  static OrderNotificationState nextState({
    required OrderNotificationState? oldState,
    required String rawStatus,
    required bool hasDriverArrived,
    String? cancelledBy,
  }) {
    return OrderNotificationState(
      status: normalizeStatus(rawStatus),
      driverArrivedNotified:
          hasDriverArrived || (oldState?.driverArrivedNotified ?? false),
      cancelledByClient: (cancelledBy == 'client' ||
          cancelledBy == 'customer' ||
          (oldState?.cancelledByClient ?? false)),
    );
  }
}
