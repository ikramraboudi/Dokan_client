/// ============================================================================
/// RÔLE DU FICHIER : Modèle et utilitaire de parsing pour le QR Code de livraison
///                   sécurisée et le calcul du code PIN de secours à 6 chiffres.
/// FORMAT DU QR CODE LIVREUR : DOKAN-CONFIRM:{orderId}:{displayNumber}:{total}
/// ALGORITHME DU PIN SECOURS  : pin = ((orderId.hashCode.abs() % 900000) + 100000).toString()
/// ============================================================================
library;

class QrConfirmationPayload {
  /// Identifiant unique du document Firestore de la commande
  final String orderId;

  /// Numéro de commande lisible (ex: DK-20261109-1234 ou DOKAN-102)
  final String displayNumber;

  /// Montant total de la commande
  final double total;

  const QrConfirmationPayload({
    required this.orderId,
    required this.displayNumber,
    required this.total,
  });

  /// Parse la chaîne scannée depuis le QR Code du livreur.
  /// Exemple valide : DOKAN-CONFIRM:cmd-12345:DOKAN-102:45.5
  static QrConfirmationPayload? parse(String? raw) {
    if (raw == null) return null;
    final text = raw.trim();
    if (!text.startsWith('DOKAN-CONFIRM:')) return null;

    final parts = text.split(':');
    if (parts.length < 4) return null;

    final orderId = parts[1].trim();
    final displayNumber = parts[2].trim();
    final total = double.tryParse(parts[3].trim()) ?? 0.0;

    if (orderId.isEmpty) return null;

    return QrConfirmationPayload(
      orderId: orderId,
      displayNumber: displayNumber,
      total: total,
    );
  }

  /// Calcule le code PIN de secours officiel à 6 chiffres partagé avec le livreur :
  /// pin = ((orderId.hashCode.abs() % 900000) + 100000).toString()
  static String calculatePin(String orderId) {
    final cleanId = orderId.trim();
    if (cleanId.isEmpty) return '000000';
    final pinNum = (cleanId.hashCode.abs() % 900000) + 100000;
    return pinNum.toString();
  }

  /// Vérifie si le code PIN saisi correspond à la commande active.
  static bool verifyPin({
    required String orderId,
    required String inputPin,
  }) {
    final cleanInput = inputPin.trim().replaceAll(' ', '');
    if (cleanInput.length != 6) return false;
    return cleanInput == calculatePin(orderId);
  }
}
