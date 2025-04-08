import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color backgroundColor;
  final Color iconColor;
  final Color titleColor;
  final Color descriptionColor;
  final void Function(BuildContext context)? onPressed;

  const CustomCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    this.backgroundColor = Colors.grey,
    this.iconColor = Colors.blue,
    this.titleColor = Colors.black,
    this.descriptionColor = Colors.grey,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onPressed != null) {
          onPressed!(context);
        }
      },
      child: Card(
        elevation: 2,
        color: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: iconColor),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: titleColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: descriptionColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
