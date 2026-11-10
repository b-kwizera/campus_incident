import 'package:campus_incident/core/constants.dart';
import 'package:campus_incident/core/utils.dart';
import 'package:campus_incident/models/incident.dart';
import 'package:campus_incident/models/status_event.dart';
import 'package:campus_incident/providers/incident_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Incident make(String id, String title, String status, String cat,
        {String loc = 'Block A'}) =>
    Incident(
      id: id,
      title: title,
      description: 'desc of $title',
      category: cat,
      location: loc,
      status: status,
      reporterId: 'u1',
      reporterName: 'Amina',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  test('Incident survives a toMap/fromMap round trip', () {
    final i = Incident(
      id: 'abc',
      title: 'Water shortage',
      description: 'No water on 2nd floor',
      category: 'water',
      location: 'Student Residence',
      photoUrl: 'https://x/y.jpg',
      reporterId: 'u1',
      reporterName: 'Amina',
      createdAt: DateTime(2026, 10, 15, 10, 24),
      updatedAt: DateTime(2026, 10, 15, 10, 24),
      history: [
        StatusEvent(
            status: 'submitted', at: DateTime(2026, 10, 15, 10, 24), by: 'Amina')
      ],
    );
    final back = Incident.fromMap('abc', i.toMap());
    expect(back.title, i.title);
    expect(back.category, 'water');
    expect(back.photoUrl, i.photoUrl);
    expect(back.history.single.status, 'submitted');
    expect(back.createdAt, i.createdAt);
  });

  group('applyFilters', () {
    final list = [
      make('1', 'Water shortage', IncidentStatus.submitted, 'water'),
      make('2', 'Broken projector', IncidentStatus.inProgress, 'facilities',
          loc: 'Block B'),
      make('3', 'Overflowing bin', IncidentStatus.resolved, 'sanitation',
          loc: 'Cafeteria'),
    ];
    test('no filters returns everything', () {
      expect(IncidentProvider.applyFilters(list).length, 3);
    });
    test('by status', () {
      final r = IncidentProvider.applyFilters(list, status: IncidentStatus.resolved);
      expect(r.map((e) => e.id), ['3']);
    });
    test('by category', () {
      final r = IncidentProvider.applyFilters(list, category: 'water');
      expect(r.map((e) => e.id), ['1']);
    });
    test('search matches title and location, case-insensitive', () {
      expect(IncidentProvider.applyFilters(list, query: 'PROJECTOR').single.id, '2');
      expect(IncidentProvider.applyFilters(list, query: 'cafeteria').single.id, '3');
    });
    test('filters combine', () {
      final r = IncidentProvider.applyFilters(list,
          query: 'water', status: IncidentStatus.resolved);
      expect(r, isEmpty);
    });
  });

  test('timeAgo formats relative times', () {
    final now = DateTime(2026, 1, 10, 12);
    expect(timeAgo(DateTime(2026, 1, 10, 11, 59, 30), now: now), 'just now');
    expect(timeAgo(DateTime(2026, 1, 10, 10), now: now), '2 hours ago');
    expect(timeAgo(DateTime(2026, 1, 9, 12), now: now), '1 day ago');
  });
}
