import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lms/core/services/auth_service.dart';
import 'package:lms/core/services/firestore_service.dart';
import 'package:lms/core/services/file_upload_service.dart';
import 'package:lms/features/auth/models/user_model.dart';

/// Result of an account deletion attempt.
enum DeleteAccountStatus { success, requiresRecentLogin, failure }

/// Central auth state manager – wraps [AuthService] + [FirestoreService].
/// Provides reactive state for the entire app via `ChangeNotifier`.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // ── State ──────────────────────────────────────────────
  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = true; // starts true while we check auth state
  String? _errorMessage;
  bool _skipNextAuthStateLoad = false; // prevents race on Google sign-in

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null && _userModel != null;
  String? get errorMessage => _errorMessage;

  // ── Constructor ────────────────────────────────────────
  AuthProvider() {
    _initAuthListener();
  }

  /// Listen to Firebase auth state and load Firestore user doc on changes.
  void _initAuthListener() {
    _authService.authStateChanges.listen((User? user) async {
      // Allow custom splash screen animation to play out
      if (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 2500));
      }

      if (_skipNextAuthStateLoad) {
        // The sign-in flow already loaded _userModel — skip the redundant load
        _skipNextAuthStateLoad = false;
        _isLoading = false;
        notifyListeners();
        return;
      }
      _firebaseUser = user;
      if (user != null) {
        try {
          _userModel = await _firestoreService.getUserDocument(user.uid);
        } catch (_) {
          // Firestore unreachable — preserve any previously loaded model
          // rather than setting null, which would break isAuthenticated
          _userModel ??= null;
        }
      } else {
        _userModel = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  // ── Email / Password Login ────────────────────────────
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _clearError();
    try {
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      if (user != null) {
        _firebaseUser = user;
        _userModel = await _firestoreService.getUserDocument(user.uid);
        if (_userModel == null) {
          _setError('User profile not found. Please contact support.');
          await _authService.signOut();
          _firebaseUser = null;
          _setLoading(false);
          return false;
        }
        _setLoading(false);
        return true;
      }
      _setError('Login failed. Please try again.');
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // ── Email / Password Register ────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    String? phoneNumber,
    required String password,
    required String role,
  }) async {
    _setLoading(true);
    _clearError();

    // ✔ Security: only allow known roles to prevent role injection
    final safeRole = role.toLowerCase();
    if (safeRole != 'student' && safeRole != 'teacher') {
      _setError('Invalid role selected.');
      _setLoading(false);
      return false;
    }

    try {
      final user = await _authService.registerWithEmail(
        email: email,
        password: password,
      );
      if (user != null) {
        // Update Firebase display name
        await user.updateDisplayName(name);

        final newUserId = _generateUserId(safeRole);

        try {
          // Create Firestore doc
          await _firestoreService.createUserDocument(
            uid: user.uid,
            name: name,
            email: email,
            phoneNumber: phoneNumber,
            role: safeRole,
            studentId: newUserId,
          );
        } catch (e) {
          // ✔ Security: If Firestore write fails, delete the orphaned Auth account
          // so the user doesn't have a half-created account they can't access
          await user.delete();
          _setError('Failed to create user profile. Please try again.');
          _setLoading(false);
          return false;
        }

        _firebaseUser = user;
        _userModel = await _firestoreService.getUserDocument(user.uid);
        _setLoading(false);
        return true;
      }
      _setError('Registration failed. Please try again.');
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // ── Google Sign-In ────────────────────────────────────
  /// Returns `true` if the flow is complete. Returns `false` if the user is
  /// new and needs to pick a role (the caller should show a role dialog and
  /// then call [completeGoogleRegistration]).
  Future<GoogleSignInResult> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) {
        // User cancelled
        _setLoading(false);
        return GoogleSignInResult.cancelled;
      }

      _firebaseUser = user;

      // Check if Firestore profile already exists
      final exists = await _firestoreService.userExists(user.uid);
      if (exists) {
        _userModel = await _firestoreService.getUserDocument(user.uid);
        _skipNextAuthStateLoad = true; // ← prevent listener from overwriting
        _setLoading(false);
        return GoogleSignInResult.existingUser;
      }

      // New user — needs role selection
      _setLoading(false);
      return GoogleSignInResult.newUser;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      _setLoading(false);
      return GoogleSignInResult.error;
    } catch (e) {
      _setError('Google Sign-In failed. Please try again.');
      _setLoading(false);
      return GoogleSignInResult.error;
    }
  }

  /// Called after the user selects a role from the role-picker dialog
  /// following a first-time Google Sign-In.
  Future<bool> completeGoogleRegistration(String role) async {
    if (_firebaseUser == null) return false;
    _setLoading(true);
    try {
      final newUserId = _generateUserId(role);

      await _firestoreService.createUserDocument(
        uid: _firebaseUser!.uid,
        name: _firebaseUser!.displayName ?? 'User',
        email: _firebaseUser!.email ?? '',
        role: role.toLowerCase(),
        profileImageUrl: _firebaseUser!.photoURL ?? '',
        studentId: newUserId,
      );
      _userModel = await _firestoreService.getUserDocument(_firebaseUser!.uid);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to complete registration. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // ── ID Generator ─────────────────────────────────────
  /// Generates a meaningful role-based user ID.
  /// Format: [prefix][2-digit year][6-digit sequential number]
  /// Examples: S26000001 (Student), L26000042 (Lecturer)
  String _generateUserId(String role) {
    final prefix = switch (role.toLowerCase()) {
      'student' => 'S',
      'teacher' => 'L', // L for Lecturer — professional LMS term
      _ => 'U',
    };
    final year = DateTime.now().year.toString().substring(
      2,
    ); // last 2 digits of year
    final seqNumber = (Random().nextInt(900000) + 100000).toString().padLeft(
      6,
      '0',
    );
    return '$prefix$year$seqNumber';
  }

  // ── Update Profile Image ──────────────────────────────
  /// Updates Firestore `profileImageUrl` and refreshes local [UserModel].
  Future<void> updateProfileImage(String url) async {
    if (_firebaseUser == null || _userModel == null) return;
    await _firestoreService.updateProfileImageUrl(_firebaseUser!.uid, url);
    _userModel = _userModel!.copyWith(profileImageUrl: url);
    notifyListeners();
  }

  // ── Update Profile Details ────────────────────────────
  /// Updates Firestore user data and refreshes local [UserModel].
  Future<void> updateProfileDetails({
    required String name,
    required String phoneNumber,
    required String role,
  }) async {
    if (_firebaseUser == null || _userModel == null) return;

    // Update Firebase Auth Display Name if changed
    if (_firebaseUser!.displayName != name) {
      await _firebaseUser!.updateDisplayName(name);
    }

    final data = {'name': name, 'phoneNumber': phoneNumber, 'role': role};

    await _firestoreService.updateUserData(_firebaseUser!.uid, data);

    _userModel = _userModel!.copyWith(
      name: name,
      phoneNumber: phoneNumber,
      role: role,
    );
    notifyListeners();
  }

  // ── Sign Out ──────────────────────────────────────────
  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    _firebaseUser = null;
    _userModel = null;
    _setLoading(false);
  }

  // ── Delete Account ────────────────────────────────────
  /// Safe deletion order:
  /// 1. Try Firebase Auth (throws requires-recent-login → bail out early, nothing destroyed)
  /// 2. Delete Firestore document
  /// 3. Delete Laravel image (best-effort, non-blocking)
  /// 4. Clear local session
  Future<DeleteAccountStatus> deleteAccount() async {
    if (_firebaseUser == null || _userModel == null) {
      _setError(
        'User not authenticated locally. Please sign out and try again.',
      );
      return DeleteAccountStatus.failure;
    }

    _setLoading(true);
    _clearError();

    final uid = _firebaseUser!.uid;
    final profileUrl = _userModel!.profileImageUrl;

    try {
      // 1. Delete Firebase Auth account FIRST.
      //    If this throws requires-recent-login, we bail immediately
      //    before touching any data — nothing is corrupted.
      await _firebaseUser!.delete();
    } on FirebaseAuthException catch (e) {
      print('Delete account error: ${e.code} - ${e.message}');
      if (e.code == 'requires-recent-login') {
        _setError(
          'Security Check: Please sign out and sign back in to confirm your identity before deleting your account.',
        );
        _setLoading(false);
        return DeleteAccountStatus.requiresRecentLogin;
      } else {
        _setError(_mapFirebaseError(e));
        _setLoading(false);
        return DeleteAccountStatus.failure;
      }
    } catch (e) {
      print('Delete account generic error: $e');
      _setError('Failed to delete account. Please try again.');
      _setLoading(false);
      return DeleteAccountStatus.failure;
    }

    // Auth deletion succeeded — now clean up data (best effort)
    try {
      await _firestoreService.deleteUserDocument(uid);
    } catch (_) {
      /* ignore: user is already deauthenticated */
    }

    // 3. Delete image from Laravel API (fire-and-forget)
    if (profileUrl.isNotEmpty) {
      FileUploadService().deleteFile(profileUrl).ignore();
    }

    // 4. Clear session via signOut (also signs out Google session)
    await _authService.signOut();
    _firebaseUser = null;
    _userModel = null;
    _setLoading(false);
    return DeleteAccountStatus.success;
  }

  // ── Helpers ───────────────────────────────────────────
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Maps common Firebase error codes to user-friendly messages.
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}

/// Result of a Google Sign-In attempt.
enum GoogleSignInResult {
  existingUser, // already has Firestore profile → go to dashboard
  newUser, // first time → needs role selection
  cancelled, // user cancelled the flow
  error, // something went wrong
}
