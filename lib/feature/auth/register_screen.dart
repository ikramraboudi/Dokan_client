/// ============================================================================
/// RÔLE DU FICHIER : Écran d'inscription d'un nouveau client sur Firebase Auth avec mise à jour du displayName.
/// INTERAGIT AVEC : AuthService.signUp(), sessionProvider.
/// POUR L'ORAL : « Cet écran crée le compte utilisateur dans Firebase Auth et enregistre son nom complet via updateDisplayName. »
/// ============================================================================
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_form_field.dart';
import '../../core/ui/app_top_bar.dart';
import '../../core/utils/validators.dart';
import '../../data/models/user_summary.dart';
import '../../services/auth_service.dart';


///  Dokan — ÉCRAN D'INSCRIPTION
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _acceptTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push(AppRoutes.terms);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push(AppRoutes.privacy);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Veuillez accepter les conditions générales d\'utilisation.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final fullName = _nameController.text.trim();
      if (fullName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(fullName);
      }

      if (!mounted) return;

      final user = UserSummary(
        fullName: fullName.isNotEmpty ? fullName : _emailController.text.trim().split('@').first,
        email: _emailController.text.trim(),
      );

      ref.read(sessionProvider.notifier).loginSuccess(user);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compte créé avec succès ! Bienvenue ${user.fullName}.'),
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message ?? 'Inscription échouée.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Inscription',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.space24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Créer un compte Dokan',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppDimens.space8),
                Text(
                  'Rejoignez notre communauté et profitez de tous nos services',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.space24),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimens.space12),
                    decoration: BoxDecoration(
                      color: AppColors.errorSoft,
                      borderRadius: BorderRadius.circular(AppDimens.radius12),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space16),
                ],

                // Nom complet
                AppFormField(
                  label: 'Nom complet',
                  hint: 'ex. Amine Ben Salem',
                  controller: _nameController,
                  validator: Validators.fullName,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppDimens.space16),

                // Adresse e-mail
                AppFormField(
                  label: 'Adresse e-mail',
                  hint: 'nom@exemple.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppDimens.space16),

                // Mot de passe
                AppFormField(
                  label: 'Mot de passe',
                  hint: 'Minimum 6 caractères',
                  controller: _passwordController,
                  isPassword: true,
                  validator: Validators.password,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppDimens.space16),

                // Confirmation mot de passe
                AppFormField(
                  label: 'Confirmer le mot de passe',
                  hint: 'Répétez votre mot de passe',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (val) => Validators.confirmPassword(val, _passwordController.text),
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  enabled: !_isLoading,
                  onFieldSubmitted: (_) => _handleSignUp(),
                ),
                const SizedBox(height: AppDimens.space16),

                // Case CGU
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _acceptTerms,
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text.rich(
                    TextSpan(
                      text: 'J\'accepte les ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: 'conditions générales d\'utilisation',
                          style: const TextStyle(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: _termsRecognizer,
                        ),
                        const TextSpan(text: ' et la '),
                        TextSpan(
                          text: 'politique de confidentialité',
                          style: const TextStyle(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: _privacyRecognizer,
                        ),
                        const TextSpan(text: ' de Dokan.'),
                      ],
                    ),
                  ),
                  onChanged: _isLoading
                      ? null
                      : (val) {
                    setState(() {
                      _acceptTerms = val ?? false;
                    });
                  },
                ),
                const SizedBox(height: AppDimens.space24),

                // Bouton Créer mon compte
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  child: _isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.onPrimary,
                    ),
                  )
                      : const Text('Créer mon compte'),
                ),
                const SizedBox(height: AppDimens.space16),

                // Lien retour connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Déjà inscrit ?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}