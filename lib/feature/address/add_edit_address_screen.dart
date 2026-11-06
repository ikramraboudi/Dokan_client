/// ============================================================================
/// RÔLE DU FICHIER : Formulaire de création ou modification d'une adresse avec validation et écriture dans Firestore.
/// INTERAGIT AVEC : firestore_addresses_repository.dart, AddressesScreen.
/// POUR L'ORAL : « Ce formulaire valide les données de contact tunisiennes et enregistre la nouvelle adresse dans users/{uid}/addresses. »
/// ============================================================================
/// ============================================================================
/// RÔLE DU FICHIER :
/// Formulaire d'ajout et de modification d'une adresse de livraison client.
/// Valide les champs obligatoires et écrit dans users/{uid}/addresses.
///
/// COUCHE DANS L'ARCHITECTURE :
/// Couche feature/address/ (Interface Utilisateur / Formulaire).
///
/// RELATIONS ET DÉPENDANCES :
/// - Utilisé par : AddressesScreen, CheckoutScreen.
/// - Dépend de : addressesRepositoryProvider, address_ui_model.dart,
///   app_form_field.dart, validators.dart, app_colors.dart, app_dimens.dart.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_form_field.dart';
import '../../core/ui/app_top_bar.dart';
import '../../core/utils/validators.dart';
import '../../data/models/address_ui_model.dart';
import '../../data/repositories/firestore_addresses_repository.dart';
import '../../services/auth_service.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final String? addressId;

  const AddEditAddressScreen({
    super.key,
    this.addressId,
  });

  @override
  ConsumerState<AddEditAddressScreen> createState() =>
      _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final _recipientController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _cityController = TextEditingController();
  final _zoneController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  final _instructionsController = TextEditingController();

  final MapController _miniMapController = MapController();
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;

  bool _isDefault = false;
  bool _isLoading = false;
  bool _isInitialLoading = false;

  bool get _isEditMode => widget.addressId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadExistingAddress();
    }
  }

  Future<void> _loadExistingAddress() async {
    setState(() => _isInitialLoading = true);
    final user = AuthService().currentUser;
    if (user != null) {
      final list =
          await ref.read(addressesRepositoryProvider).getAddresses(user.uid);
      final existing = list.where((a) => a.id == widget.addressId).firstOrNull;
      if (existing != null && mounted) {
        _recipientController.text = existing.recipientName;
        _phoneController.text = existing.phone;
        _addressLineController.text = existing.addressLine;
        _cityController.text = existing.city;
        _zoneController.text = existing.zone ?? '';
        _additionalInfoController.text = existing.additionalInfo ?? '';
        _instructionsController.text = existing.deliveryInstructions ?? '';
        _isDefault = existing.isDefault;
        _latitude = existing.latitude;
        _longitude = existing.longitude;
      }
    }
    if (mounted) {
      setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Veuillez activer le service de localisation (GPS) sur votre téléphone.',
              ),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Permission refusée. Vous pouvez pointer votre position manuellement sur la carte.',
                ),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La localisation est bloquée dans vos paramètres. Vous pouvez pointer votre adresse directement sur la carte.',
              ),
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
        });
        _miniMapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Position GPS actuelle appliquée avec succès.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'obtenir la position : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _phoneController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _zoneController.dispose();
    _additionalInfoController.dispose();
    _instructionsController.dispose();
    _miniMapController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final user = AuthService().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(addressesRepositoryProvider);
      final address = AddressUiModel(
        id: widget.addressId ?? '',
        recipientName: _recipientController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine: _addressLineController.text.trim(),
        city: _cityController.text.trim(),
        zone: _zoneController.text.trim().isNotEmpty
            ? _zoneController.text.trim()
            : null,
        additionalInfo: _additionalInfoController.text.trim().isNotEmpty
            ? _additionalInfoController.text.trim()
            : null,
        deliveryInstructions: _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
        isDefault: _isDefault,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (_isEditMode) {
        await repo.updateAddress(user.uid, address);
      } else {
        await repo.addAddress(user.uid, address);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Adresse modifiée avec succès.'
                : 'Adresse ajoutée avec succès.'),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Scaffold(
        appBar: AppTopBar(
          title: _isEditMode ? 'Modifier l\'adresse' : 'Nouvelle adresse',
          showBackButton: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: _isEditMode ? 'Modifier l\'adresse' : 'Nouvelle adresse',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppFormField(
                  label: 'Nom complet du destinataire *',
                  hint: 'Ex: Mohamed Ben Salah',
                  controller: _recipientController,
                  validator: (val) => Validators.required(val, 'Le nom du destinataire est obligatoire.'),
                  prefixIcon: const Icon(Icons.person_outline),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppDimens.space16),

                AppFormField(
                  label: 'Numéro de téléphone *',
                  hint: 'Ex: 21 000 000',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Le numéro de téléphone est obligatoire.';
                    }
                    if (val.trim().length < 8) {
                      return 'Numéro de téléphone incomplet.';
                    }
                    return null;
                  },
                  prefixIcon: const Icon(Icons.phone_outlined),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppDimens.space16),

                AppFormField(
                  label: 'Adresse (Rue, Numéro, Bâtiment) *',
                  hint: 'Ex: 15 Rue de la Liberté, Apt 4B',
                  controller: _addressLineController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'L\'adresse exacte est obligatoire.';
                    }
                    return null;
                  },
                  prefixIcon: const Icon(Icons.home_outlined),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppDimens.space16),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppFormField(
                        label: 'Ville *',
                        hint: 'Ex: Tunis',
                        controller: _cityController,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'La ville est obligatoire.';
                          }
                          return null;
                        },
                        prefixIcon: const Icon(Icons.location_city_outlined),
                        enabled: !_isLoading,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      flex: 2,
                      child: AppFormField(
                        label: 'Région / Quartier',
                        hint: 'Ex: El Menzah',
                        controller: _zoneController,
                        enabled: !_isLoading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.space16),

                AppFormField(
                  label: 'Complément d\'adresse (facultatif)',
                  hint: 'Ex: Étage 3, Interphone 12',
                  controller: _additionalInfoController,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppDimens.space16),

                AppFormField(
                  label: 'Instructions pour le livreur (facultatif)',
                  hint: 'Ex: Appeler à l\'arrivée, laisser au concierge',
                  controller: _instructionsController,
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppDimens.space16),

                // ── Bloc Position sur la carte (facultatif) ──
                _buildMapPositionSection(),
                const SizedBox(height: AppDimens.space16),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primary,
                  title: const Text(
                    'Définir comme adresse principale par défaut',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Cette adresse sera présélectionnée lors de vos commandes.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  value: _isDefault,
                  onChanged: _isLoading
                      ? null
                      : (val) => setState(() => _isDefault = val),
                ),
                const SizedBox(height: AppDimens.space24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : Text(_isEditMode
                          ? 'Enregistrer les modifications'
                          : 'Ajouter cette adresse'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapPositionSection() {
    final hasCoord = _latitude != null && _longitude != null;
    final initialCenter = hasCoord
        ? LatLng(_latitude!, _longitude!)
        : const LatLng(36.8065, 10.1815);

    return Container(
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radius12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppDimens.space8),
              const Expanded(
                child: Text(
                  'Position sur la carte (facultatif)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (hasCoord)
                IconButton(
                  tooltip: 'Supprimer la position',
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                            _latitude = null;
                            _longitude = null;
                          }),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.space4),
          const Text(
            'Permet au livreur de vous situer avec une précision GPS sur la carte.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimens.space12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size.fromHeight(42),
            ),
            onPressed: _isLoading || _isLocating ? null : _getCurrentLocation,
            icon: _isLocating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.my_location_rounded, size: 18),
            label: Text(
              _isLocating
                  ? 'Recherche GPS en cours...'
                  : 'Utiliser ma position actuelle',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: AppDimens.space12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radius8),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                mapController: _miniMapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: hasCoord ? 15.0 : 11.0,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _latitude = point.latitude;
                      _longitude = point.longitude;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.Dokan.Dokan_client',
                  ),
                  if (hasCoord)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_latitude!, _longitude!),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            size: 38,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  hasCoord
                      ? '📍 Lat: ${_latitude!.toStringAsFixed(4)}, Lon: ${_longitude!.toStringAsFixed(4)} (Touchez pour ajuster)'
                      : 'Touchez la carte pour pointer votre domicile.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const Text(
                '© OpenStreetMap',
                style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
