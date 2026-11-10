import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String department;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.department = '',
    required this.createdAt,
  });

  bool get isStaff => role == UserRole.staff;

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role,
        'department': department,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        name: (m['name'] ?? '') as String,
        email: (m['email'] ?? '') as String,
        role: (m['role'] ?? UserRole.student) as String,
        department: (m['department'] ?? '') as String,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
