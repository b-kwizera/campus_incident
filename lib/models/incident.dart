import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import 'status_event.dart';

class Incident {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String? photoUrl;
  final String status;
  final String reporterId;
  final String reporterName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StatusEvent> history;

  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.photoUrl,
    this.status = IncidentStatus.submitted,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    required this.updatedAt,
    this.history = const [],
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'photoUrl': photoUrl,
        'status': status,
        'reporterId': reporterId,
        'reporterName': reporterName,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'statusHistory': history.map((e) => e.toMap()).toList(),
      };

  factory Incident.fromMap(String id, Map<String, dynamic> m) => Incident(
        id: id,
        title: (m['title'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        category: (m['category'] ?? 'facilities') as String,
        location: (m['location'] ?? '') as String,
        photoUrl: m['photoUrl'] as String?,
        status: (m['status'] ?? IncidentStatus.submitted) as String,
        reporterId: (m['reporterId'] ?? '') as String,
        reporterName: (m['reporterName'] ?? '') as String,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        history: ((m['statusHistory'] ?? []) as List)
            .map((e) => StatusEvent.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Incident copyWith({
    String? title,
    String? description,
    String? category,
    String? location,
    String? photoUrl,
    bool clearPhoto = false,
  }) =>
      Incident(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        location: location ?? this.location,
        photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
        status: status,
        reporterId: reporterId,
        reporterName: reporterName,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        history: history,
      );
}
