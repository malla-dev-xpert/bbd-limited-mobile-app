// Widget utilitaire pour afficher une info avec icône
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';

class InfoIconText extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const InfoIconText(
      {required this.icon, required this.label, required this.value, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Text('$label: ',
            style: AppTextSize.bodyStyle(context, color: Colors.grey[600])),
        Text(value,
            style: AppTextSize.bodyStyle(context,
                fontWeight: FontWeight.w600, color: const Color(0xFF1A1E49))),
      ],
    );
  }
}
