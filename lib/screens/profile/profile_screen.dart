import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/stat_tile.dart';
import '../../core/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final inc = context.watch<IncidentProvider>();
    final p = auth.profile;
    return SafeArea(
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: kPrimary.withValues(alpha: 0.12),
                child: Text(
                  (auth.displayName.isEmpty ? '?' : auth.displayName[0]).toUpperCase(),
                  style: const TextStyle(fontSize: 24, color: kPrimary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(auth.displayName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(p?.email ?? '', style: TextStyle(color: Colors.grey.shade600)),
                  if ((p?.department ?? '').isNotEmpty)
                    Text(p!.department, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Chip(
                    label: Text(auth.isStaff ? 'Staff' : 'Student'),
                    visualDensity: VisualDensity.compact,
                  ),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          StatTile(icon: Icons.description, color: kPrimary, value: inc.total, label: 'Total'),
          StatTile(icon: Icons.schedule, color: IncidentStatus.color(IncidentStatus.inProgress),
              value: inc.count(IncidentStatus.inProgress), label: 'In Progress'),
          StatTile(icon: Icons.check_circle, color: IncidentStatus.color(IncidentStatus.resolved),
              value: inc.count(IncidentStatus.resolved), label: 'Resolved'),
        ]),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Log out?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
                ],
              ),
            );
            if (ok == true && context.mounted) context.read<AuthProvider>().logout();
          },
        ),
      ]),
    );
  }
}
