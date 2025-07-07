import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const ReportCard({
    super.key,
    required this.title,
    required this.value,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.55;
    final double iconSize = cardWidth * 0.18; // taille adaptative
    return Container(
      constraints: BoxConstraints(
        minWidth: 120,
        maxWidth: cardWidth,
        minHeight: 90,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Flexible(
                child: Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: textColor.withOpacity(0.85),
                      size: iconSize * 0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Flexible(
              child: AutoSizeText(
                title,
                style: TextStyle(
                  color: textColor.withOpacity(0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                minFontSize: 10,
                maxLines: 2,
                wrapWords: true,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: AutoSizeText(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
                minFontSize: 14,
                maxLines: 2,
                wrapWords: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
