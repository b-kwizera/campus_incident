import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/incident_repository.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CampusIncidentApp());
}

class CampusIncidentApp extends StatelessWidget {
  const CampusIncidentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services/repositories are plain objects, created once.
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => IncidentRepository()),
        Provider(create: (_) => StorageService()),
        ChangeNotifierProvider(
            create: (c) => AuthProvider(c.read<AuthService>())),
        // IncidentProvider re-binds its Firestore stream when auth/role changes.
        ChangeNotifierProxyProvider<AuthProvider, IncidentProvider>(
          create: (c) => IncidentProvider(
              c.read<IncidentRepository>(), c.read<StorageService>()),
          update: (c, auth, prev) {
            final p = prev ??
                IncidentProvider(
                    c.read<IncidentRepository>(), c.read<StorageService>());
            final uid = (auth.isLoggedIn && auth.isVerified && auth.profile != null)
                ? auth.user!.uid
                : null;
            if (p.boundUid != uid || p.boundStaff != auth.isStaff) {
              p.bind(uid: uid, isStaff: auth.isStaff);
            }
            return p;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Campus Incident Reporter',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const AuthGate(),
      ),
    );
  }
}
