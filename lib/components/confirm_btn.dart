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
      minimumSize: Size(double.infinity, 50),
      backgroundColor: Colors.green,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    icon:
        isLoading
            ? SizedBox(
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
      style: TextStyle(color: Colors.white),
    ),
    onPressed: isLoading ? null : onPressed,
  );
}
