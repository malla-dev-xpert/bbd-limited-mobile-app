import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CustomCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color backgroundColor;
  final Color iconColor;
  final Color titleColor;
  final void Function(BuildContext context)? onPressed;

  const CustomCard({
    super.key,
    required this.icon,
    required this.title,
    this.backgroundColor = const Color(0xFF26C6DA),
    this.iconColor = Colors.blue,
    this.titleColor = Colors.white,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: 1.0),
          duration: const Duration(milliseconds: 100),
          builder: (context, scale, child) {
            return GestureDetector(
              onTap: () {
                if (onPressed != null) {
                  onPressed!(context);
                }
              },
              child: AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: backgroundColor.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative bubbles
                      Positioned(
                        top: -30,
                        right: -20,
                        child: _Bubble(
                            radius: 60, color: Colors.white.withOpacity(0.12)),
                      ),
                      Positioned(
                        bottom: -20,
                        left: -20,
                        child: _Bubble(
                            radius: 40, color: Colors.white.withOpacity(0.10)),
                      ),
                      Positioned(
                        top: 30,
                        right: -10,
                        child: _Bubble(
                            radius: 24, color: Colors.white.withOpacity(0.08)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon in white circle (plus grand)
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Icon(icon, size: 26, color: iconColor),
                            ),
                            const SizedBox(height: 18),
                            AutoSizeText(
                              title,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: 16,
                                color: titleColor,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.5,
                              ),
                              minFontSize: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Decorative bubble widget
class _Bubble extends StatelessWidget {
  final double radius;
  final Color color;
  const _Bubble({required this.radius, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
