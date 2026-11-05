/// ============================================================================
/// RÔLE DU FICHIER : Service d'encapsulation directe des méthodes du SDK Firebase Authentication (signUp, signIn, reset, signOut).
/// INTERAGIT AVEC : FirebaseAuth.instance, LoginScreen, RegisterScreen, ForgotPasswordScreen.
/// POUR L'ORAL : « AuthService encapsule tous les appels natifs à Firebase Auth pour isoler les écrans du SDK Google. »
/// ============================================================================
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null),
        _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  // ── Stream to listen to real-time auth changes ─────────────────────────────
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  // ── Get currently logged-in user ──────────────────────────────────────────
  User? get currentUser => _auth?.currentUser;

  /// Indique si le compte utilise une authentification e-mail / mot de passe.
  bool get hasPasswordProvider {
    final user = currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  // ── 1. Sign Up (Email & Password) ──────────────────────────────────────────
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ── 2. Sign In (Email & Password) ──────────────────────────────────────────
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ── 3. Password Reset ──────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── 4. Sign Out ────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await auth.signOut();
  }

  // ── 5. Récupération des données utilisateur Firestore ──────────────────────
  Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  // ── 6. Mise à jour du profil (Auth displayName + Firestore users/{uid}) ────
  /// Met à jour uniquement 'name', 'phone' et 'updatedAt' sans écraser 'role' ni les autres champs.
  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String phone,
  }) async {
    final user = currentUser;
    if (user != null && fullName.trim().isNotEmpty) {
      await user.updateDisplayName(fullName.trim());
    }

    await firestore.collection('users').doc(uid).set({
      'name': fullName.trim(),
      'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── 7. Modification du mot de passe avec ré-authentification ────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Aucun utilisateur connecté.',
      );
    }

    // Ré-authentification obligatoire avant de pouvoir changer le mot de passe
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Mise à jour effective du mot de passe
    await user.updatePassword(newPassword);
  }
}
