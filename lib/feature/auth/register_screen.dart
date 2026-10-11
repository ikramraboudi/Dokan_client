import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/ui/app_form_field.dart';
import '../../core/ui/app_top_bar.dart';
import '../../core/utils/validators.dart';
import '../../data/mock/mock_auth_repository.dart';

/// ============================================================
///  SOUKNA — ÉCRAN D'INSCRIPTION (ÉTAPE 4)
/// ============================================================
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

  bool _acceptTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
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
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        // Enregistre la session et exécute l'action protégée en attente
        ref.read(sessionProvider.notifier).loginSuccess(user);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Compte créé avec succès ! Bienvenue ${user.fullName}.'),
            duration: const Duration(seconds: 2),
          ),
        );

        // Retour à l'écran précédent
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
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
                  'Créer un compte Soukna',
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
                  onFieldSubmitted: (_) => _submitRegister(),
                ),
                const SizedBox(height: AppDimens.space16),

                // Case CGU
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _acceptTerms,
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'J\'accepte les conditions générales d\'utilisation et la politique de confidentialité de Soukna.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
                  onPressed: _isLoading ? null : _submitRegister,
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
