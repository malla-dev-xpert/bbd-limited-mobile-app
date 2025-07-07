import 'package:flutter/material.dart';

Widget confirmationButton({
  required bool isLoading,
  required VoidCallback onPressed,
  required String label,
  required IconData icon,
  required String subLabel,
}) {
  return ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      backgroundColor: Colors.green,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
    ),
    icon: isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Icon(icon, color: Colors.white),
    label: Text(
      isLoading ? subLabel : label,
      style: const TextStyle(color: Colors.white),
    ),
    onPressed: isLoading ? null : onPressed,
  );
}
