import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/incident_card.dart';
import '../../widgets/state_views.dart';
import 'incident_details_screen.dart';

/// "My Reports" for students, "All Reports" for staff. Same widget, the
/// provider already scopes the data by role.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.staffView});
  final bool staffView;

  @override
  Widget build(BuildContext context) {
    final inc = context.watch<IncidentProvider>();
    final list = inc.filtered;
    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(staffView ? 'All Reports' : 'My Reports',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                  hintText: 'Search title, description or location',
                  prefixIcon: Icon(Icons.search),
                  isDense: true),
              onChanged: inc.setQuery,
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip('All', inc.statusFilter == null, () => inc.setStatusFilter(null)),
                for (final s in IncidentStatus.all)
                  _chip(IncidentStatus.label(s), inc.statusFilter == s,
                      () => inc.setStatusFilter(s)),
              ]),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip('Any category', inc.categoryFilter == null,
                    () => inc.setCategoryFilter(null)),
                for (final c in incidentCategories)
                  _chip(c.label, inc.categoryFilter == c.key,
                      () => inc.setCategoryFilter(c.key)),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: Builder(builder: (_) {
            if (inc.loading) return const LoadingView();
            if (inc.error != null) return ErrorView(message: inc.error!);
            if (list.isEmpty) {
              return EmptyView(
                  message: inc.all.isEmpty
                      ? 'No reports yet.'
                      : 'No reports match your filters.');
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
              itemCount: list.length,
              itemBuilder: (_, i) => IncidentCard(
                incident: list[i],
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => IncidentDetailsScreen(incidentId: list[i].id))),
              ),
            );
          }),
        ),
      ]),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
      );
}
