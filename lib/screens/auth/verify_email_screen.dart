import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/state_views.dart';

/// Blocks access to the app until the ALU email address is verified.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.mark_email_unread_outlined, size: 72, color: kPrimary),
            const SizedBox(height: 16),
            const Text('Verify your email',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'We sent a verification link to\n${auth.user?.email ?? ''}.\n'
              'Open it, then tap the button below.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () async {
                final ok = await context.read<AuthProvider>().checkVerified();
                if (!ok && context.mounted) {
                  showSnack(context, 'Email not verified yet', error: true);
                }
              },
              child: const Text("I've verified my email"),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: auth.busy
                  ? null
                  : () async {
                      final ok = await context.read<AuthProvider>().resendVerification();
                      if (context.mounted) {
                        showSnack(context,
                            ok ? 'Verification email sent' : (auth.error ?? 'Failed'),
                            error: !ok);
                      }
                    },
              child: const Text('Resend email'),
            ),
            TextButton(
              onPressed: () => context.read<AuthProvider>().logout(),
              child: const Text('Use a different account'),
            ),
          ]),
        ),
      ),
    );
  }
}
