import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_badge.dart';
import 'report_form_screen.dart';

/// Looks the incident up by id in IncidentProvider so staff status changes
/// show up live (the provider is fed by a Firestore stream).
class IncidentDetailsScreen extends StatelessWidget {
  const IncidentDetailsScreen({super.key, required this.incidentId});
  final String incidentId;

  @override
  Widget build(BuildContext context) {
    final inc = context.watch<IncidentProvider>();
    final auth = context.watch<AuthProvider>();
    final i = inc.byId(incidentId);

    if (i == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Incident Details')),
          body: const EmptyView(message: 'This report no longer exists.'));
    }

    final isOwner = i.reporterId == auth.user?.uid;
    final canEdit = isOwner && i.status == IncidentStatus.submitted;
    final cat = categoryByKey(i.category);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        actions: [
          if (canEdit)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ReportFormScreen(existing: i)));
                } else {
                  _confirmDelete(context, i);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                    backgroundColor: kPrimary.withValues(alpha: 0.12),
                    child: Icon(cat.icon, color: kPrimary)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(i.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${cat.label} · ${i.location}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ]),
                ),
                StatusBadge(i.status),
              ]),
              const Divider(height: 24),
              _meta(Icons.event, 'Submitted on ${fullDate(i.createdAt)}'),
              const SizedBox(height: 6),
              _meta(Icons.person_outline, 'Reported by ${i.reporterName}'),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Status Timeline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        _Timeline(incident: i),
        const SizedBox(height: 16),
        const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 6),
        Text(i.description),
        if (i.photoUrl != null) ...[
          const SizedBox(height: 16),
          const Text('Attached Photo',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: i.photoUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) => const SizedBox(height: 180, child: LoadingView()),
              errorWidget: (_, _, _) =>
                  const SizedBox(height: 120, child: ErrorView(message: 'Could not load photo')),
            ),
          ),
        ],
        // Staff-only controls. Also enforced server-side in firestore.rules.
        if (auth.isStaff) ...[
          const SizedBox(height: 24),
          _StaffStatusPanel(incident: i),
        ],
      ]),
    );
  }

  Widget _meta(IconData icon, String text) => Row(children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
      ]);

  Future<void> _confirmDelete(BuildContext context, Incident i) async {
    final inc = context.read<IncidentProvider>();
    final nav = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete report?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await inc.delete(i);
      nav.pop();
    } catch (_) {
      if (context.mounted) showSnack(context, 'Could not delete the report', error: true);
    }
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final reached = <String, DateTime>{
      for (final e in incident.history) e.status: e.at,
    };
    reached.putIfAbsent(IncidentStatus.submitted, () => incident.createdAt);
    return Row(children: [
      for (var n = 0; n < IncidentStatus.all.length; n++) ...[
        if (n > 0)
          Expanded(
              child: Container(
                  height: 2,
                  color: reached.containsKey(IncidentStatus.all[n]) ? kPrimary : Colors.grey.shade300)),
        _step(IncidentStatus.all[n], reached[IncidentStatus.all[n]]),
      ],
    ]);
  }

  Widget _step(String s, DateTime? at) {
    final done = at != null;
    return Column(children: [
      CircleAvatar(
        radius: 12,
        backgroundColor: done ? kPrimary : Colors.grey.shade300,
        child: Icon(done ? Icons.check : Icons.circle, size: 12, color: Colors.white),
      ),
      const SizedBox(height: 4),
      Text(IncidentStatus.label(s), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      Text(at == null ? '—' : timeAgo(at), style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
    ]);
  }
}

class _StaffStatusPanel extends StatelessWidget {
  const _StaffStatusPanel({required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final inc = context.watch<IncidentProvider>();
    final auth = context.read<AuthProvider>();
    return Card(
      color: kPrimary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.admin_panel_settings, color: kPrimary),
            SizedBox(width: 8),
            Text('Staff: update status', style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            for (final s in IncidentStatus.all)
              ChoiceChip(
                label: Text(IncidentStatus.label(s)),
                selected: incident.status == s,
                onSelected: (inc.saving || incident.status == s)
                    ? null
                    : (_) async {
                        try {
                          await inc.updateStatus(incident.id, s, auth.displayName);
                          if (context.mounted) {
                            showSnack(context, 'Status set to ${IncidentStatus.label(s)}');
                          }
                        } catch (_) {
                          if (context.mounted) {
                            showSnack(context, 'Could not update status', error: true);
                          }
                        }
                      },
              ),
          ]),
        ]),
      ),
    );
  }
}
