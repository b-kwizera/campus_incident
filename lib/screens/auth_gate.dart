import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/state_views.dart';
import 'auth/login_screen.dart';
import 'auth/verify_email_screen.dart';
import 'main_shell.dart';

/// Chooses the screen from auth state: login -> verify email -> app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.initializing) return const Scaffold(body: LoadingView());
    if (!auth.isLoggedIn) return const LoginScreen();
    if (!auth.isVerified) return const VerifyEmailScreen();
    if (auth.profile == null) return const Scaffold(body: LoadingView());
    return const MainShell();
  }
}
