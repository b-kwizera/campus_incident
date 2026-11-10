import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/incident_card.dart';
import '../../widgets/state_views.dart';
import '../../widgets/stat_tile.dart';
import '../incidents/incident_details_screen.dart';
import '../incidents/report_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onSeeAll});
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final inc = context.watch<IncidentProvider>();
    final first = auth.displayName.split(' ').first;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          Text('Hello, $first 👋',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
              auth.isStaff
                  ? 'Review reports and keep students updated.'
                  : 'Report issues and track their resolution.',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          if (!auth.isStaff) _Banner(onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ReportFormScreen()))),
          const SizedBox(height: 16),
          const Text('Report Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            StatTile(icon: Icons.description, color: kPrimary, value: inc.total,
                label: auth.isStaff ? 'All Reports' : 'My Reports'),
            StatTile(icon: Icons.schedule, color: IncidentStatus.color(IncidentStatus.inProgress),
                value: inc.count(IncidentStatus.inProgress), label: 'In Progress'),
            StatTile(icon: Icons.check_circle, color: IncidentStatus.color(IncidentStatus.resolved),
                value: inc.count(IncidentStatus.resolved), label: 'Resolved'),
            StatTile(icon: Icons.priority_high, color: IncidentStatus.color(IncidentStatus.submitted),
                value: inc.count(IncidentStatus.submitted), label: 'Submitted'),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Recent Reports',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            TextButton(onPressed: onSeeAll, child: const Text('See all')),
          ]),
          if (inc.loading)
            const Padding(padding: EdgeInsets.all(32), child: LoadingView())
          else if (inc.error != null)
            ErrorView(message: inc.error!)
          else if (inc.recent.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: EmptyView(message: 'No reports yet.'))
          else
            ...inc.recent.map((i) => IncidentCard(
                  incident: i,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => IncidentDetailsScreen(incidentId: i.id))),
                )),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF7B5CFF), Color(0xFF5B3DE0)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('See an issue\non campus?',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Report it and help improve\nour learning environment.',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 14),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(children: [
                  Icon(Icons.add_circle, color: kPrimary),
                  SizedBox(width: 10),
                  Expanded(child: Text('Report an Issue',
                      style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700))),
                  Icon(Icons.chevron_right, color: kPrimary),
                ]),
              ),
            ),
          ),
        ]),
      );
}
