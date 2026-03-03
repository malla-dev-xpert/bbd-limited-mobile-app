import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';

class ItemDetailChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool fullWidth;

  const ItemDetailChip({
    Key? key,
    required this.text,
    required this.icon,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Séparer le label et la valeur
    final colonIndex = text.indexOf(':');
    final label = colonIndex != -1 ? text.substring(0, colonIndex + 1) : text;
    final value = colonIndex != -1 ? text.substring(colonIndex + 1).trim() : '';

    final chipContent = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: fullWidth ? 16 : 14,
          color: Colors.grey[700],
        ),
        SizedBox(width: fullWidth ? 8 : 4),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: AppTextSize.bodyStyle(context,
                      color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                if (value.isNotEmpty)
                  TextSpan(
                    text: ' $value',
                    style: AppTextSize.bodyStyle(context,
                        color: Colors.grey[800], fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (fullWidth) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: chipContent,
      );
    } else {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: chipContent,
        ),
      );
    }
  }
}
