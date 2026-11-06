/// ============================================================================
/// RÔLE DU FICHIER : Écran de connexion client avec validation et reprise automatique d'action en attente.
/// INTERAGIT AVEC : AuthService.signIn(), sessionProvider, RegisterScreen.
/// POUR L'ORAL : « Cet écran authentifie le client sur Firebase et déclenche immédiatement la reprise de l'action qu'il avait tentée en mode visiteur. »
/// ============================================================================
library;

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
import '../../data/models/user_summary.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../orders/notification_permission_dialog.dart';


///  Dokan — ÉCRAN DE CONNEXION
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // 1) Contrôle de présence des champs email et mot de passe
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      // 2) Appel Firebase Auth : signInWithEmailAndPassword
      final userCredential = await _authService.signIn(email: email, password: password);
      if (!mounted) return;

      final firebaseUser = userCredential.user;
      final displayName = (firebaseUser?.displayName != null && firebaseUser!.displayName!.isNotEmpty)
          ? firebaseUser.displayName!
          : email.split('@').first;

      String? phone;
      if (firebaseUser != null) {
        try {
          final userData = await _authService.fetchUserData(firebaseUser.uid);
          if (userData != null && userData['phone'] != null) {
            phone = userData['phone'] as String?;
          }
        } catch (_) {}
      }

      final userSummary = UserSummary(
        fullName: displayName,
        email: firebaseUser?.email ?? email,
        phone: phone,
      );

      // 3) Mise à jour de la session Riverpod et reprise de l'action en attente
      ref.read(sessionProvider.notifier).loginSuccess(
            userSummary,
            userId: firebaseUser?.uid,
          );

      // Proposition bienveillante des notifications après connexion réussie
      if (firebaseUser != null && mounted) {
        final notifService = ref.read(notificationServiceProvider);
        final granted = await notifService.isPermissionGranted();
        if (!granted && mounted) {
          await NotificationPermissionDialog.show(
            context,
            notificationService: notifService,
            userId: firebaseUser.uid,
          );
        } else if (granted) {
          await notifService.registerDeviceToken(firebaseUser.uid);
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bienvenue, $displayName !'),
          duration: const Duration(seconds: 2),
        ),
      );

      // 4) Redirection vers l'écran appelant ou l'accueil
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Connexion',
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
                const SizedBox(height: AppDimens.space12),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.space16),
                Text(
                  'Heureux de vous revoir',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppDimens.space8),
                Text(
                  'Connectez-vous pour accéder à vos favoris et vos commandes',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppDimens.space32),

                // Message d'erreur s'il y a lieu
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimens.space12),
                    decoration: BoxDecoration(
                      color: AppColors.errorSoft,
                      borderRadius: BorderRadius.circular(AppDimens.radius12),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppDimens.space12),
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
                  const SizedBox(height: AppDimens.space20),
                ],

                // Champ E-mail
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

                // Champ Mot de passe
                AppFormField(
                  label: 'Mot de passe',
                  hint: '••••••••',
                  controller: _passwordController,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: Validators.password,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  enabled: !_isLoading,
                  onFieldSubmitted: (_) => _handleLogin(),
                ),

                // Mot de passe oublié
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => context.push(AppRoutes.forgotPassword),
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),
                const SizedBox(height: AppDimens.space16),

                // Bouton Se connecter avec état de chargement
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text('Se connecter'),
                ),
                const SizedBox(height: AppDimens.space24),

                // Lien Inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Pas encore de compte ?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => context.push(AppRoutes.register),
                      child: const Text('Créer un compte'),
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
