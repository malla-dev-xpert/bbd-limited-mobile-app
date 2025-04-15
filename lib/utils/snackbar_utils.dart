import 'package:flutter/material.dart';

void showSuccessTopSnackBar(BuildContext context, String message) {
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder:
        (context) => Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          right: 20,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(10),
            color: Colors.green,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text(message, style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
  );

  Overlay.of(context).insert(overlayEntry);

  Future.delayed(Duration(seconds: 2), () {
    overlayEntry?.remove();
  });
}

void showErrorTopSnackBar(BuildContext context, String message) {
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder:
        (context) => Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          right: 20,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(10),
            color: Colors.red,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text(message, style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
  );

  Overlay.of(context).insert(overlayEntry);

  Future.delayed(Duration(seconds: 2), () {
    overlayEntry?.remove();
  });
}
