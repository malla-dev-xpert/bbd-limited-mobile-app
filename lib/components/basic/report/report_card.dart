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
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 800;

    // Taille fixe pour toutes les devices
    final double cardWidth = isTablet ? 200 : 160;
    final double cardHeight = isTablet ? 140 : 120;
    final double iconSize = isTablet ? 36 : 32;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 24 : 20,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
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
              SizedBox(height: isTablet ? 12 : 10),
            ],
            Flexible(
              child: AutoSizeText(
                title,
                style: TextStyle(
                  color: textColor.withOpacity(0.85),
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                minFontSize: isTablet ? 12 : 10,
                maxLines: 2,
                wrapWords: true,
              ),
            ),
            SizedBox(height: isTablet ? 10 : 8),
            Flexible(
              child: AutoSizeText(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: isTablet ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
                minFontSize: isTablet ? 16 : 14,
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
