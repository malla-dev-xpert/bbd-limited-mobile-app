import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';

class RoundedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool loading;

  const RoundedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7F78AF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 4,
        minimumSize: const Size.fromHeight(48),
      ),
      child: loading
          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
          : Text(
              text,
              style: AppTextSize.buttonStyle(context,
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
    );
  }
}
