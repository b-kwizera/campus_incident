import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants.dart';
import '../models/app_user.dart';

/// Thin wrapper around Firebase Auth + the `users` collection.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Emits on sign-in, sign-out and user reloads (e.g. email verified).
  Stream<User?> get userChanges => _auth.userChanges();
  User? get currentUser => _auth.currentUser;

  /// New accounts are ALWAYS students. Staff role is granted only through
  /// the Firebase console and cannot be set by the client (see firestore.rules).
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String department = '',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(), password: password);
    final user = cred.user!;
    await user.updateDisplayName(name.trim());
    await _db.collection('users').doc(user.uid).set(AppUser(
          uid: user.uid,
          name: name.trim(),
          email: email.trim().toLowerCase(),
          role: UserRole.student,
          department: department.trim(),
          createdAt: DateTime.now(),
        ).toMap());
    await user.sendEmailVerification();
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(), password: password);
  }

  Future<void> logout() => _auth.signOut();

  Future<void> resendVerification() async =>
      _auth.currentUser?.sendEmailVerification();

  /// Reloads the user so `emailVerified` is fresh. Returns the new value.
  Future<bool> refreshVerification() async {
    await _auth.currentUser?.reload();
    final verified = _auth.currentUser?.emailVerified ?? false;
    // Firestore rules read email_verified from the ID token, which is only
    // refreshed hourly. Force a new token so the rules see the verified state.
    if (verified) await _auth.currentUser?.getIdToken(true);
    return verified;
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());

  Stream<AppUser?> watchProfile(String uid) =>
      _db.collection('users').doc(uid).snapshots().map(
          (s) => s.exists ? AppUser.fromMap(s.id, s.data()!) : null);
}

/// Converts Firebase error codes into friendly messages.
String friendlyAuthError(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
    }
    return e.message ?? 'Authentication failed.';
  }
  return 'Something went wrong. Please try again.';
}
