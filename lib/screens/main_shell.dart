import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'home/home_screen.dart';
import 'incidents/report_form_screen.dart';
import 'incidents/reports_screen.dart';
import 'profile/profile_screen.dart';

/// Bottom navigation: Home, Reports, Profile, plus a Report FAB for students.
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void goToReports() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    final isStaff = context.watch<AuthProvider>().isStaff;
    final pages = [
      HomeScreen(onSeeAll: goToReports),
      ReportsScreen(staffView: isStaff),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: isStaff
          ? null
          : FloatingActionButton(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              tooltip: 'Report an incident',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ReportFormScreen())),
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
              icon: const Icon(Icons.description_outlined),
              selectedIcon: const Icon(Icons.description),
              label: isStaff ? 'All Reports' : 'Reports'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
