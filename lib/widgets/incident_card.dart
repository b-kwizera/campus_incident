import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/incident.dart';
import 'status_badge.dart';

class IncidentCard extends StatelessWidget {
  const IncidentCard({super.key, required this.incident, required this.onTap});
  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cat = categoryByKey(incident.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child: incident.photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: incident.photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (_, _, _) => _fallback(cat),
                      )
                    : _fallback(cat),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(incident.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(incident.location,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.schedule, size: 13, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(timeAgo(incident.createdAt),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ]),
              ]),
            ),
            StatusBadge(incident.status),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ]),
        ),
      ),
    );
  }

  Widget _fallback(IncidentCategory cat) => Container(
      color: kPrimary.withValues(alpha: 0.1),
      child: Icon(cat.icon, color: kPrimary));
}
