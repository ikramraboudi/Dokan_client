/// ============================================================================
/// RÔLE DU FICHIER : Écran « Modifier le profil » avec gestion PopScope et fusion sécurisée Firestore users/{uid}.
/// INTERAGIT AVEC : sessionProvider, AuthService, Validators, AppFormField.
/// POUR L'ORAL : « Cet écran permet de modifier le nom et le téléphone avec vérification de non-abandon et fusion Firestore sans écraser le rôle. »
/// ============================================================================
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_form_field.dart';
import '../../core/ui/app_top_bar.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final AuthService? authService;

  const EditProfileScreen({super.key, this.authService});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  late final AuthService _authService;

  String _initialName = '';
  String _initialPhone = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    final user = ref.read(sessionProvider).user;
    _initialName = user?.fullName ?? '';
    _initialPhone = user?.phone ?? '';

    _nameController.text = _initialName;
    _phoneController.text = _initialPhone;
    _emailController.text = user?.email ?? '';

    // Écoute les changements pour activer/désactiver le bouton Enregistrer
    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);

    // Si le téléphone n'était pas dans la session, tenter une lecture Firestore
    if (_initialPhone.isEmpty && _authService.currentUser != null) {
      _loadPhoneFromFirestore();
    }
  }

  Future<void> _loadPhoneFromFirestore() async {
    try {
      final data = await _authService.fetchUserData(_authService.currentUser!.uid);
      if (data != null && data['phone'] != null && mounted) {
        final phone = (data['phone'] as String).trim();
        if (phone.isNotEmpty) {
          setState(() {
            _initialPhone = phone;
            _phoneController.text = phone;
          });
        }
      }
    } catch (_) {}
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Indique si l'utilisateur a modifié au moins un champ
  bool get _hasChanges {
    final currentName = _nameController.text.trim();
    final currentPhone = _phoneController.text.trim();
    return currentName != _initialName.trim() || currentPhone != _initialPhone.trim();
  }

  /// Validation globale du formulaire
  bool get _isFormValid {
    final nameValid = Validators.fullName(_nameController.text) == null;
    final phoneValid = Validators.phone(_phoneController.text) == null;
    return nameValid && phoneValid;
  }

  Future<bool> _showDiscardDialog(BuildContext context) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandonner les modifications ?'),
        content: const Text(
          'Des modifications n\'ont pas été enregistrées. Voulez-vous vraiment quitter ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnDark,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _handleSave() async {
    if (_isLoading || !_hasChanges || !_isFormValid) return;
    if (!_formKey.currentState!.validate()) return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      setState(() {
        _errorMessage = 'Votre session a expiré. Veuillez vous reconnecter.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();

    try {
      // 1. Mise à jour Firebase Auth + Firestore users/{uid} (fusion stricte sans écraser 'role')
      await _authService.updateUserProfile(
        uid: currentUser.uid,
        fullName: newName,
        phone: newPhone,
      );

      // 2. Mise à jour immédiate du sessionProvider pour répercussion instantanée
      ref.read(sessionProvider.notifier).updateProfile(
            fullName: newName,
            phone: newPhone,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès.'),
          duration: Duration(seconds: 2),
        ),
      );

      // Réinitialisation de l'état des modifications pour éviter le dialogue PopScope
      _initialName = newName;
      _initialPhone = newPhone;

      Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      String message = 'Impossible d\'enregistrer les modifications.';
      if (e.code == 'permission-denied') {
        message = 'Droits insuffisants pour mettre à jour le profil.';
      } else if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        message = 'Problème de connexion réseau. Réessayez.';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Une erreur inattendue est survenue.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _nameController.text.trim().isNotEmpty
        ? _nameController.text
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'S';

    final canSave = _hasChanges && _isFormValid && !_isLoading;

    return PopScope(
      canPop: !_hasChanges || _isLoading,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showDiscardDialog(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AppTopBar(
          title: 'Modifier le profil',
          showBackButton: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimens.space16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Avatar rond avec initiales
                        Center(
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.primarySoft,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimens.space24),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(AppDimens.space12),
                            margin: const EdgeInsets.only(bottom: AppDimens.space16),
                            decoration: BoxDecoration(
                              color: AppColors.errorSoft,
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radius12),
                              border: Border.all(color: AppColors.error),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: AppDimens.space8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Carte formulaire
                        Container(
                          padding: const EdgeInsets.all(AppDimens.space16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppDimens.radius16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nom complet
                              AppFormField(
                                label: 'Nom complet *',
                                hint: 'ex. Amine Ben Salem',
                                controller: _nameController,
                                validator: Validators.fullName,
                                prefixIcon: const Icon(Icons.person_outline_rounded),
                                enabled: !_isLoading,
                              ),
                              const SizedBox(height: AppDimens.space16),

                              // Numéro de téléphone
                              AppFormField(
                                label: 'Numéro de téléphone *',
                                hint: 'ex. 21 000 000',
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                validator: Validators.phone,
                                prefixIcon: const Icon(Icons.phone_outlined),
                                enabled: !_isLoading,
                              ),
                              const SizedBox(height: AppDimens.space16),

                              // Adresse e-mail (lecture seule)
                              AppFormField(
                                label: 'Adresse e-mail',
                                hint: '',
                                controller: _emailController,
                                enabled: false,
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: AppColors.textHint,
                                ),
                              ),
                              const SizedBox(height: AppDimens.space4),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: AppDimens.space4),
                                child: Text(
                                  'L\'adresse e-mail ne peut pas être modifiée ici.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Ligne changer le mot de passe si compte email/mot de passe
                        if (_authService.hasPasswordProvider) ...[
                          const SizedBox(height: AppDimens.space16),
                          Material(
                            color: AppColors.surface,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radius14),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.lock_reset_rounded,
                                color: AppColors.primary,
                              ),
                              title: const Text(
                                'Changer le mot de passe',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textSecondary,
                              ),
                              onTap: _isLoading
                                  ? null
                                  : () => context.push(AppRoutes.changePassword),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Barre fixe inférieure pour Enregistrer
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canSave ? _handleSave : null,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Text('Enregistrer les modifications'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
