import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Stream to listen to real-time auth changes ─────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Get currently logged-in user ──────────────────────────────────────────
  User? get currentUser => _auth.currentUser;

  // ── 1. Sign Up (Email & Password) ──────────────────────────────────────────
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ── 2. Sign In (Email & Password) ──────────────────────────────────────────
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ── 3. Password Reset ──────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── 4. Sign Out ────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
