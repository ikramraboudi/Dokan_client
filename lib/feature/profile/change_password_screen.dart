/// ============================================================================
/// RÔLE DU FICHIER : Écran de changement sécurisé du mot de passe avec ré-authentification Firebase Auth.
/// INTERAGIT AVEC : AuthService, Validators, AppFormField.
/// POUR L'ORAL : « Cet écran ré-authentifie le client avec son mot de passe actuel avant d'autoriser la mise à jour sur Firebase Auth. »
/// ============================================================================
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_form_field.dart';
import '../../core/ui/app_top_bar.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe modifié avec succès.'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Le mot de passe actuel est incorrect.';
          break;
        case 'weak-password':
          message = 'Le nouveau mot de passe est trop faible.';
          break;
        case 'too-many-requests':
          message = 'Trop de tentatives. Veuillez réessayer plus tard.';
          break;
        case 'network-request-failed':
          message = 'Problème de connexion réseau.';
          break;
        case 'requires-recent-login':
          message = 'Veuillez vous reconnecter avant de modifier votre mot de passe.';
          break;
        default:
          message = e.message ?? 'Impossible de modifier le mot de passe.';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Une erreur inattendue est survenue. Réessayez.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(
        title: 'Changer le mot de passe',
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
                Container(
                  padding: const EdgeInsets.all(AppDimens.space16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radius16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sécurité du compte',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space4),
                      const Text(
                        'Pour modifier votre mot de passe, confirmez d\'abord votre mot de passe actuel.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space20),

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

                      // Mot de passe actuel
                      AppFormField(
                        label: 'Mot de passe actuel *',
                        hint: 'Votre mot de passe actuel',
                        controller: _currentPasswordController,
                        isPassword: true,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        validator: (val) =>
                            Validators.required(val, 'Saisissez votre mot de passe actuel.'),
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: AppDimens.space16),

                      // Nouveau mot de passe
                      AppFormField(
                        label: 'Nouveau mot de passe *',
                        hint: 'Minimum 6 caractères',
                        controller: _newPasswordController,
                        isPassword: true,
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
                        validator: Validators.password,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: AppDimens.space16),

                      // Confirmation
                      AppFormField(
                        label: 'Confirmer le nouveau mot de passe *',
                        hint: 'Répétez le nouveau mot de passe',
                        controller: _confirmPasswordController,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                        validator: (val) => Validators.confirmPassword(
                          val,
                          _newPasswordController.text,
                        ),
                        enabled: !_isLoading,
                        onFieldSubmitted: (_) => _handleSubmit(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.space24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text('Enregistrer le nouveau mot de passe'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
