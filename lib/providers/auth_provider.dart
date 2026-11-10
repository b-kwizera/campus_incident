import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

/// Holds session + profile state. The UI listens to this to decide which
/// screen to show (login / verify email / app) and which role features to show.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service) {
    _authSub = _service.userChanges.listen(_onUser);
  }

  final AuthService _service;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  User? _user;
  AppUser? _profile;
  bool _initializing = true;
  bool _busy = false;
  String? _error;

  User? get user => _user;
  AppUser? get profile => _profile;
  bool get initializing => _initializing;
  bool get busy => _busy;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isVerified => _user?.emailVerified ?? false;
  bool get isStaff => _profile?.isStaff ?? false;
  String get displayName =>
      _profile?.name ?? _user?.displayName ?? _user?.email ?? '';

  void _onUser(User? u) {
    _user = u;
    // Existing session whose token predates verification: refresh it once.
    if (u != null && u.emailVerified) {
      u.getIdToken(true).catchError((_) => null);
    }
    _profileSub?.cancel();
    _profile = null;
    if (u != null) {
      _profileSub = _service.watchProfile(u.uid).listen((p) {
        _profile = p;
        notifyListeners();
      });
    }
    _initializing = false;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _error = friendlyAuthError(e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password,
          String department) =>
      _run(() => _service.register(
          name: name, email: email, password: password, department: department));

  Future<bool> login(String email, String password) =>
      _run(() => _service.login(email, password));

  Future<void> logout() => _service.logout();

  Future<bool> resendVerification() => _run(_service.resendVerification);

  Future<bool> checkVerified() async {
    final ok = await _service.refreshVerification();
    // userChanges() does not always fire on reload; force a refresh.
    _user = _service.currentUser;
    notifyListeners();
    return ok;
  }

  Future<bool> resetPassword(String email) =>
      _run(() => _service.sendPasswordReset(email));

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
