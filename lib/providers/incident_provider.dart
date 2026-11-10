import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/incident.dart';
import '../models/status_event.dart';
import '../services/incident_repository.dart';
import '../services/storage_service.dart';

/// Holds the incident list for the signed-in user (all for staff, own for
/// students), plus search/filter state. Every screen reads from here, so a
/// status change made by staff propagates everywhere via the Firestore stream.
class IncidentProvider extends ChangeNotifier {
  IncidentProvider(this._repo, this._storage);

  final IncidentRepository _repo;
  final StorageService _storage;
  StreamSubscription<List<Incident>>? _sub;

  List<Incident> _incidents = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  String? _statusFilter; // null = All
  String? _categoryFilter;
  bool _saving = false;
  bool _disposed = false;
  String? _boundUid;
  bool _boundStaff = false;

  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;
  String get query => _query;
  String? get statusFilter => _statusFilter;
  String? get categoryFilter => _categoryFilter;
  List<Incident> get all => _incidents;

  /// Called by ProxyProvider whenever the auth state changes.
  String? get boundUid => _boundUid;
  bool get boundStaff => _boundStaff;

  void bind({required String? uid, required bool isStaff}) {
    _boundUid = uid;
    _boundStaff = isStaff;
    _sub?.cancel();
    _incidents = [];
    if (uid == null) {
      _loading = false;
      _notifyLater();
      return;
    }
    _loading = true;
    _error = null;
    final stream = isStaff ? _repo.watchAll() : _repo.watchMine(uid);
    _sub = stream.listen((list) {
      _incidents = list;
      _loading = false;
      _error = null;
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('Incident stream error: $e');
      _loading = false;
      _error = e is FirebaseException && e.code == 'permission-denied'
          ? 'Permission denied by Firestore rules. Make sure your email is '
              'verified and the rules are published.'
          : 'Could not load reports (${e is FirebaseException ? e.code : 'unknown'}).';
      notifyListeners();
    });
    _notifyLater();
  }

  /// bind() runs during a widget build (ProxyProvider.update), so notify
  /// after the frame instead of synchronously.
  void _notifyLater() => Future.microtask(() {
        if (!_disposed) notifyListeners();
      });

  // ---- filtering -----------------------------------------------------
  List<Incident> get filtered => applyFilters(
      _incidents, query: _query, status: _statusFilter, category: _categoryFilter);

  @visibleForTesting
  static List<Incident> applyFilters(List<Incident> src,
      {String query = '', String? status, String? category}) {
    final q = query.trim().toLowerCase();
    return src.where((i) {
      if (status != null && i.status != status) return false;
      if (category != null && i.category != category) return false;
      if (q.isEmpty) return true;
      return i.title.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q) ||
          i.location.toLowerCase().contains(q);
    }).toList();
  }

  int count(String status) => _incidents.where((i) => i.status == status).length;
  int get total => _incidents.length;
  List<Incident> get recent => _incidents.take(3).toList();

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setStatusFilter(String? s) {
    _statusFilter = s;
    notifyListeners();
  }

  void setCategoryFilter(String? c) {
    _categoryFilter = c;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _statusFilter = null;
    _categoryFilter = null;
    notifyListeners();
  }

  Incident? byId(String id) {
    for (final i in _incidents) {
      if (i.id == id) return i;
    }
    return null;
  }

  // ---- mutations -----------------------------------------------------
  Future<T> _guard<T>(Future<T> Function() fn) async {
    _saving = true;
    notifyListeners();
    try {
      return await fn();
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> submit({
    required String uid,
    required String reporterName,
    required String title,
    required String description,
    required String category,
    required String location,
    File? photo,
  }) =>
      _guard(() async {
        final id = _repo.newId();
        String? url;
        if (photo != null) {
          url = await _storage.uploadIncidentPhoto(
              uid: uid, incidentId: id, file: photo);
        }
        final now = DateTime.now();
        await _repo.create(Incident(
          id: id,
          title: title.trim(),
          description: description.trim(),
          category: category,
          location: location,
          photoUrl: url,
          reporterId: uid,
          reporterName: reporterName,
          createdAt: now,
          updatedAt: now,
          history: [
            StatusEvent(
                status: IncidentStatus.submitted, at: now, by: reporterName),
          ],
        ));
      });

  Future<void> edit(Incident updated, {File? newPhoto, bool removePhoto = false}) =>
      _guard(() async {
        var next = updated;
        if (removePhoto) {
          await _storage.deleteByUrl(updated.photoUrl);
          next = updated.copyWith(clearPhoto: true);
        }
        if (newPhoto != null) {
          final url = await _storage.uploadIncidentPhoto(
              uid: updated.reporterId, incidentId: updated.id, file: newPhoto);
          next = next.copyWith(photoUrl: url);
        }
        await _repo.updateContent(next);
      });

  Future<void> updateStatus(String id, String status, String staffName) =>
      _guard(() => _repo.updateStatus(id, status, staffName));

  Future<void> delete(Incident i) => _guard(() async {
        await _repo.delete(i.id);
        await _storage.deleteByUrl(i.photoUrl);
      });

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
