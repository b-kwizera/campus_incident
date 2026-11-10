import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident.dart';
import '../models/status_event.dart';

/// All Firestore access for incidents lives here (UI never touches Firestore).
class IncidentRepository {
  IncidentRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('incidents');

  String newId() => _col.doc().id;

  /// Staff: every incident, newest first.
  Stream<List<Incident>> watchAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(_toList);

  /// Student: only their own incidents. Sorted client-side to avoid needing a
  /// composite index.
  Stream<List<Incident>> watchMine(String uid) => _col
      .where('reporterId', isEqualTo: uid)
      .snapshots()
      .map((s) => _toList(s)..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  List<Incident> _toList(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => Incident.fromMap(d.id, d.data())).toList();

  // CREATE
  Future<void> create(Incident i) => _col.doc(i.id).set(i.toMap());

  // UPDATE (reporter edits content while still "submitted")
  Future<void> updateContent(Incident i) => _col.doc(i.id).update({
        'title': i.title,
        'description': i.description,
        'category': i.category,
        'location': i.location,
        'photoUrl': i.photoUrl,
        'updatedAt': Timestamp.fromDate(i.updatedAt),
      });

  // UPDATE (staff only, enforced by security rules)
  Future<void> updateStatus(String id, String status, String staffName) =>
      _col.doc(id).update({
        'status': status,
        'updatedAt': Timestamp.now(),
        'statusHistory': FieldValue.arrayUnion([
          StatusEvent(status: status, at: DateTime.now(), by: staffName).toMap()
        ]),
      });

  // DELETE
  Future<void> delete(String id) => _col.doc(id).delete();
}
