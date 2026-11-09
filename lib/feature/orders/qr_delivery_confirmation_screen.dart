/// ============================================================================
/// RÔLE DU FICHIER : Écran de confirmation de livraison par scan de caméra (mobile_scanner)
///                   avec validation cryptographique du QR Code livreur
///                   et option de secours par code PIN à 6 chiffres.
/// PROTOCOLE QR : DOKAN-CONFIRM:{orderId}:{displayNumber}:{total}
/// ALGORITHME PIN : ((orderId.hashCode.abs() % 900000) + 100000).toString()
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../data/models/order_model.dart';
import '../../data/models/qr_confirmation_payload.dart';
import '../../data/repositories/firestore_orders_repository.dart';
import 'widgets/delivery_success_dialog.dart';

class QrDeliveryConfirmationScreen extends ConsumerStatefulWidget {
  final String orderId;
  final OrderUiModel? initialOrder;

  const QrDeliveryConfirmationScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  ConsumerState<QrDeliveryConfirmationScreen> createState() =>
      _QrDeliveryConfirmationScreenState();
}

class _QrDeliveryConfirmationScreenState
    extends ConsumerState<QrDeliveryConfirmationScreen> {
  late final MobileScannerController _scannerController;
  bool _isProcessing = false;
  bool _hasScanned = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_hasScanned || _isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null || rawValue.isEmpty) continue;

      final payload = QrConfirmationPayload.parse(rawValue);
      if (payload == null) {
        // QR Code non Dokan
        _showInvalidCodeSnackBar(
          'Format de QR Code non reconnu. Scannez le QR Code officiel sur l\'écran du livreur Dokan.',
        );
        return;
      }

      // Vérification que le orderId correspond bien à la commande en cours
      if (payload.orderId != widget.orderId) {
        _showInvalidCodeSnackBar(
          'Ce QR Code correspond à une autre commande (${payload.displayNumber}).',
        );
        return;
      }

      // Validé !
      _hasScanned = true;
      await _validateDelivery(
        confirmationMethod: 'client_qr_scan',
        successMessage: 'QR Code du livreur validé avec succès !',
      );
      break;
    }
  }

  void _showInvalidCodeSnackBar(String message) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _validateDelivery({
    required String confirmationMethod,
    required String successMessage,
  }) async {
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      await _scannerController.stop();
    } catch (_) {}

    try {
      final repo = ref.read(ordersRepositoryProvider);
      await repo.confirmDelivery(
        orderId: widget.orderId,
        confirmationMethod: confirmationMethod,
      );

      // Récupération de la commande mise à jour pour le dialogue
      final updatedOrder = await repo.watchOrder(widget.orderId).first;
      final orderForDialog = updatedOrder ?? widget.initialOrder;

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // Fermeture de l'écran scanner
      Navigator.of(context).pop(true);

      // Affichage du dialogue de célébration et notation
      if (orderForDialog != null) {
        DeliverySuccessDialog.show(context, orderForDialog);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _hasScanned = false;
      });
      _scannerController.start();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la validation : $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _openPinFallbackDialog(OrderUiModel? order) {
    final pinController = TextEditingController();
    final expectedPin = QrConfirmationPayload.calculatePin(widget.orderId);
    String? pinError;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radius24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppDimens.space20,
                right: AppDimens.space20,
                top: AppDimens.space24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                    AppDimens.space24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Code PIN de secours',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space8),
                  const Text(
                    'Si la caméra ne fonctionne pas, demandez au livreur le code PIN à 6 chiffres affiché sur son écran.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space20),

                  // Champ de saisie du PIN à 6 chiffres
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                      color: AppColors.primary,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: '••••••',
                      counterText: '',
                      errorText: pinError,
                      filled: true,
                      fillColor: AppColors.surfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radius16),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radius16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      if (pinError != null) {
                        setSheetState(() => pinError = null);
                      }
                      // Validation automatique dès que les 6 chiffres sont saisis
                      if (val.trim().length == 6) {
                        if (val.trim() == expectedPin) {
                          Navigator.of(sheetContext).pop();
                          _validateDelivery(
                            confirmationMethod: 'client_pin_code',
                            successMessage: 'Code PIN validé avec succès !',
                          );
                        } else {
                          HapticFeedback.heavyImpact();
                          setSheetState(() {
                            pinError =
                                'Code PIN incorrect. Vérifiez le code sur le téléphone du livreur.';
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: AppDimens.space20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radius12),
                      ),
                    ),
                    onPressed: () {
                      final input = pinController.text.trim();
                      if (input == expectedPin) {
                        Navigator.of(sheetContext).pop();
                        _validateDelivery(
                          confirmationMethod: 'client_pin_code',
                          successMessage: 'Code PIN validé avec succès !',
                        );
                      } else {
                        HapticFeedback.heavyImpact();
                        setSheetState(() {
                          pinError =
                              'Code PIN incorrect. Vérifiez le code sur le téléphone du livreur.';
                        });
                      }
                    },
                    child: const Text(
                      'Confirmer le code PIN',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(singleOrderStreamProvider(widget.orderId));
    final order = orderAsync.value ?? widget.initialOrder;
    final displayNumber = order?.displayNumber ?? 'Commande';
    final totalText = order != null ? '${order.total.toStringAsFixed(3)} DT' : '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirmer la réception',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              displayNumber,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? Colors.amber : Colors.white,
            ),
            onPressed: () async {
              await _scannerController.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Scanner Camera View ──
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),

          // ── Cadre de visée interactif avec ombre semi-transparente ──
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // ── Bandeau d'instructions supérieur ──
          Positioned(
            top: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(AppDimens.radius16),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.primaryLight,
                    size: 28,
                  ),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scannez le QR Code du livreur',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pointez votre caméra vers l\'écran du livreur pour certifier la remise $totalText',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Indicateur de traitement ──
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Validation de la livraison en cours...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Option de secours (Code PIN) en bas ──
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: const Size.fromHeight(50),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radius16),
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  icon: const Icon(Icons.pin_rounded, color: AppColors.primary),
                  label: const Text(
                    'Problème de caméra ? Saisir le code PIN',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _openPinFallbackDialog(order),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dessine le masque d'assombrissement avec viseur transparent au centre
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scanSize = size.width * 0.72;
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45),
      width: scanSize,
      height: scanSize,
    );

    final backgroundPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    // Dessin du fond assombri avec découpe centrale
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(24)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Coins décoratifs couleur Dokan Primary
    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;
    final r = scanRect;

    // Coin haut gauche
    canvas.drawLine(Offset(r.left, r.top + cornerLength), Offset(r.left, r.top), borderPaint);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + cornerLength, r.top), borderPaint);

    // Coin haut droit
    canvas.drawLine(Offset(r.right - cornerLength, r.top), Offset(r.right, r.top), borderPaint);
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.top + cornerLength), borderPaint);

    // Coin bas gauche
    canvas.drawLine(Offset(r.left, r.bottom - cornerLength), Offset(r.left, r.bottom), borderPaint);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left + cornerLength, r.bottom), borderPaint);

    // Coin bas droit
    canvas.drawLine(Offset(r.right - cornerLength, r.bottom), Offset(r.right, r.bottom), borderPaint);
    canvas.drawLine(Offset(r.right, r.bottom), Offset(r.right, r.bottom - cornerLength), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
