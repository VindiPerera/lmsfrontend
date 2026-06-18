import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around FirebaseAuth — handles Email/Password & Google Sign-In.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '1030315957216-n9g1d3th65108sretn9lrpov5u38lqap.apps.googleusercontent.com'
        : null,
  );

  // ── Stream ─────────────────────────────────────────────
  /// Emits when the user's sign-in state changes (login / logout).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in user, or `null`.
  User? get currentUser => _auth.currentUser;

  // ── Email / Password ──────────────────────────────────
  /// Creates a new user and returns the [User] object.
  Future<User?> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Signs in an existing user. Returns the [User] object.
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  // ── Google Sign-In ────────────────────────────────────
  /// Launches the Google Sign-In flow and returns the Firebase [User].
  Future<User?> signInWithGoogle() async {
    // Trigger the native Google Sign-In UI
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled

    // Obtain auth details from the Google account
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a Firebase credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  // ── Sign Out ──────────────────────────────────────────
  /// Signs out of both Firebase and Google (if applicable).
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
