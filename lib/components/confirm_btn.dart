import 'package:flutter/material.dart';

Widget confirmationButton({
  required bool isLoading,
  required VoidCallback onPressed,
  required String label,
  required IconData icon,
  required String subLabel,
  Color? backgroundColor,
  Color? foregroundColor,
}) {
  final bg = backgroundColor ?? Colors.green;
  final fg = foregroundColor ?? Colors.white;
  return ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      backgroundColor: bg,
      foregroundColor: fg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    icon: isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
            ),
          )
        : Icon(icon, color: fg),
    label: Text(
      isLoading ? subLabel : label,
      style: TextStyle(color: fg),
    ),
    onPressed: isLoading ? null : onPressed,
  );
}
