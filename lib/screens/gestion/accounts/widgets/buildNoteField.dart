import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';

Widget buildNoteField(BuildContext context, String? note) {
  if (note == null || note.isEmpty) return const SizedBox.shrink();

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(16),
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Note",
          style: AppTextSize.bodyStyle(context,
              fontWeight: FontWeight.w500, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        Text(
          note,
          style: AppTextSize.bodyStyle(context,
              color: const Color(0xFF1A1E49)),
        ),
      ],
    ),
  );
}
