import 'package:flutter/material.dart';

Widget buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
  String? errorText,
  ValueChanged<String>? onChanged,
  VoidCallback? onEditingComplete,
  ValueChanged<String>? onFieldSubmitted,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    autocorrect: false,
    onChanged: onChanged,
    onEditingComplete: onEditingComplete,
    onFieldSubmitted: onFieldSubmitted,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.black),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      errorText: errorText,
    ),
    validator: validator,
  );
}
