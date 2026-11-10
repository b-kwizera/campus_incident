import 'constants.dart';

class Validators {
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// True when the email belongs to an allowed ALU domain.
  static bool isAluEmail(String email) {
    final e = email.trim().toLowerCase();
    return e.endsWith('@$studentDomain') || e.endsWith('@$staffDomain');
  }

  static String? email(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Email is required';
    if (!_emailRe.hasMatch(value)) return 'Enter a valid email address';
    if (!isAluEmail(value)) {
      return 'Use your ALU email (@$studentDomain or @$staffDomain)';
    }
    return null;
  }

  static String? password(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include at least one number';
    return null;
  }

  static String? name(String? v) {
    if ((v ?? '').trim().length < 2) return 'Enter your full name';
    return null;
  }

  static String? title(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Title is required';
    if (value.length < 5) return 'Title must be at least 5 characters';
    if (value.length > 80) return 'Title must be under 80 characters';
    return null;
  }

  static String? description(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Description is required';
    if (value.length < 15) return 'Please give more detail (15+ characters)';
    return null;
  }
}
