import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:flutter/material.dart';

class ItemInfoDisplay extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const ItemInfoDisplay({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          "$label : ",
          style: AppTextSize.bodyStyle(context, color: Colors.grey[800]),
        ),
        Text(
          value,
          style: AppTextSize.subtitleStyle(context, color: valueColor ?? Colors.grey[900], fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
