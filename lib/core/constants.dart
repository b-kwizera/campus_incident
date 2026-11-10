import 'package:flutter/material.dart';

/// Allowed registration domains (ALU only).
const String studentDomain = 'alustudent.com';
const String staffDomain = 'alueducation.com';

class UserRole {
  static const student = 'student';
  static const staff = 'staff';
}

class IncidentStatus {
  static const submitted = 'submitted';
  static const inProgress = 'in_progress';
  static const resolved = 'resolved';
  static const all = [submitted, inProgress, resolved];

  static String label(String s) {
    switch (s) {
      case inProgress:
        return 'In Progress';
      case resolved:
        return 'Resolved';
      default:
        return 'Submitted';
    }
  }

  static Color color(String s) {
    switch (s) {
      case inProgress:
        return const Color(0xFF5B4BDB);
      case resolved:
        return const Color(0xFF2E9E5B);
      default:
        return const Color(0xFFE09A00);
    }
  }
}

class IncidentCategory {
  final String key;
  final String label;
  final IconData icon;
  const IncidentCategory(this.key, this.label, this.icon);
}

const List<IncidentCategory> incidentCategories = [
  IncidentCategory('facilities', 'Facilities', Icons.apartment_rounded),
  IncidentCategory('water', 'Water', Icons.water_drop_outlined),
  IncidentCategory('electricity', 'Electricity', Icons.bolt_rounded),
  IncidentCategory('safety', 'Safety', Icons.shield_outlined),
  IncidentCategory('sanitation', 'Sanitation', Icons.delete_outline_rounded),
];

IncidentCategory categoryByKey(String key) => incidentCategories
    .firstWhere((c) => c.key == key, orElse: () => incidentCategories.first);

const List<String> campusLocations = [
  'Block A',
  'Block B',
  'Block C',
  'Student Residence',
  'Cafeteria',
  'Library',
  'Sports Grounds',
  'Parking Lot',
  'Other',
];
