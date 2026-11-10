import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile(
      {super.key,
      required this.category,
      required this.selected,
      required this.onTap});
  final IncidentCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: category.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 96,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? kPrimary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? kPrimary : Colors.grey.shade300),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(category.icon, color: selected ? Colors.white : kPrimary),
            const SizedBox(height: 6),
            Text(category.label,
                style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : Colors.black87)),
          ]),
        ),
      ),
    );
  }
}
