/// ============================================================================
/// RÔLE DU FICHIER : Énumération officielle des 6 statuts de commande avec labels français, couleurs du thème, icônes et étapes de progression (0-3).
/// INTERAGIT AVEC : OrderUiModel, MyOrdersScreen, OrderDetailScreen.
/// POUR L'ORAL : « OrderStatus convertit les statuts texte de Firestore en libellés français, couleurs et étapes de camion pour la barre de progression. »
/// ============================================================================
/// ============================================================================
/// RÔLE DU FICHIER :
/// Énumération unique et tolérante des statuts de commande Dokan.
/// Gère la conversion bidirectionnelle chaîne ⇄ enum, les libellés français,
/// les couleurs du thème (AppColors) et l'étape d'avancement graphique.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche data/models/ (Modèle Métier / Statuts).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : OrderUiModel, MyOrdersScreen, OrderDetailScreen.
/// - Dépend de : core/theme/app_colors.dart et material.dart pour les icônes/couleurs.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Statuts officiels d'une commande Dokan (partagés avec Admin et Livreur).
enum OrderStatus {
  pending('en_attente', 'En attente'),
  confirmed('confirmed', 'Confirmée'),
  preparing('preparing', 'En préparation'),
  outForDelivery('in_progress', 'En livraison'),
  delivered('delivered', 'Livrée'),
  failed('failed', 'Échec de livraison'),
  refused('refused', 'Colis refusé'),
  cancelled('cancelled', 'Annulée');

  /// Valeur textuelle brute stockée dans Firestore.
  final String value;

  /// Libellé officiel affiché à l'utilisateur en français.
  final String label;

  const OrderStatus(this.value, this.label);

  /// Conversion tolérante : accepte les conventions des 3 applications (Client, Admin, Livreur).
  static OrderStatus fromString(String? value) {
    if (value == null) return OrderStatus.pending;
    final s = value
        .toLowerCase()
        .trim()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll(' ', '_')
        .replaceAll('-', '_');

    return switch (s) {
      'en_attente' ||
      'enattente' ||
      'pending' ||
      'attente' ||
      'recue' ||
      'nouvelle' =>
        OrderStatus.pending,
      'confirmed' ||
      'confirmee' ||
      'confirme' ||
      'acceptee' ||
      'accepte' ||
      'validee' ||
      'valide' ||
      'approuvee' ||
      'approuve' =>
        OrderStatus.confirmed,
      'preparing' ||
      'en_preparation' ||
      'enpreparation' ||
      'preparation' =>
        OrderStatus.preparing,
      'in_progress' ||
      'inprogress' ||
      'out_for_delivery' ||
      'outfordelivery' ||
      'en_livraison' ||
      'enlivraison' ||
      'en_route' ||
      'enroute' =>
        OrderStatus.outForDelivery,
      'delivered' ||
      'livree' ||
      'livre' ||
      'terminee' ||
      'termine' =>
        OrderStatus.delivered,
      'failed' || 'echec' => OrderStatus.failed,
      'refused' || 'refusee' || 'refuse' => OrderStatus.refused,
      'cancelled' ||
      'canceled' ||
      'annulee' ||
      'annule' =>
        OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };
  }

  /// Couleur principale du badge ou ruban (depuis AppColors).
  Color get color => switch (this) {
        OrderStatus.pending => AppColors.statusPending,
        OrderStatus.confirmed => AppColors.statusPreparing,
        OrderStatus.preparing => AppColors.statusPreparing,
        OrderStatus.outForDelivery => AppColors.statusOutForDelivery,
        OrderStatus.delivered => AppColors.statusDelivered,
        OrderStatus.failed => AppColors.error,
        OrderStatus.refused => AppColors.error,
        OrderStatus.cancelled => AppColors.statusCancelled,
      };

  /// Couleur de fond douce (soft) du badge ou ruban (depuis AppColors).
  Color get softColor => switch (this) {
        OrderStatus.pending => AppColors.statusPendingSoft,
        OrderStatus.confirmed => AppColors.statusPreparingSoft,
        OrderStatus.preparing => AppColors.statusPreparingSoft,
        OrderStatus.outForDelivery => AppColors.statusOutForDeliverySoft,
        OrderStatus.delivered => AppColors.statusDeliveredSoft,
        OrderStatus.failed => AppColors.errorSoft,
        OrderStatus.refused => AppColors.errorSoft,
        OrderStatus.cancelled => AppColors.statusCancelledSoft,
      };

  /// Icône Material représentative du statut.
  IconData get icon => switch (this) {
        OrderStatus.pending => Icons.hourglass_top_rounded,
        OrderStatus.confirmed => Icons.check_circle_outline_rounded,
        OrderStatus.preparing => Icons.inventory_2_outlined,
        OrderStatus.outForDelivery => Icons.local_shipping_outlined,
        OrderStatus.delivered => Icons.task_alt_rounded,
        OrderStatus.failed => Icons.error_outline_rounded,
        OrderStatus.refused => Icons.block_rounded,
        OrderStatus.cancelled => Icons.cancel_outlined,
      };

  /// Indice de l'étape sur la barre de progression en 4 étapes :
  /// 0: Reçue / En attente
  /// 1: Préparation (Confirmée + En préparation)
  /// 2: En livraison (In progress)
  /// 3: Livrée
  /// -1: Annulée / Échec / Refusée (barre grisée)
  int get progressStep => switch (this) {
        OrderStatus.pending => 0,
        OrderStatus.confirmed => 1,
        OrderStatus.preparing => 1,
        OrderStatus.outForDelivery => 2,
        OrderStatus.delivered => 3,
        OrderStatus.failed => -1,
        OrderStatus.refused => -1,
        OrderStatus.cancelled => -1,
      };

  /// Indique si la commande est encore annulable par le client.
  bool get canBeCancelledByCustomer => this == OrderStatus.pending;
}
