import 'package:cloud_firestore/cloud_firestore.dart';

/// One entry of an incident's status timeline.
class StatusEvent {
  final String status;
  final DateTime at;
  final String by;

  const StatusEvent({required this.status, required this.at, required this.by});

  Map<String, dynamic> toMap() =>
      {'status': status, 'at': Timestamp.fromDate(at), 'by': by};

  factory StatusEvent.fromMap(Map<String, dynamic> m) => StatusEvent(
        status: (m['status'] ?? 'submitted') as String,
        at: (m['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        by: (m['by'] ?? '') as String,
      );
}
