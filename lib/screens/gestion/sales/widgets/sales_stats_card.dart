import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';

/// Couleurs existantes pour les gradients des KPI (blue, green).
abstract final class _KpiColors {
  static const Color blueStart = Color(0xFF42A5F5);
  static const Color blueEnd = Color(0xFF1A1E49);
  static const Color greenStart = Color(0xFF66BB6A);
  static const Color greenEnd = Color(0xFF1A1E49);
}

/// Carte KPI type dashboard : gradient, grande métrique, icône coin, ombre.
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final bool isLoading;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = DeviceBreakpoints.isTablet(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: EdgeInsets.all(isTablet ? AppSpacing.xl : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isTablet ? AppSpacing.xl : AppSpacing.lg,
            offset: Offset(0, AppSpacing.sm),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              child: CustomPaint(
                size: Size(
                  isTablet ? AppSpacing.xxl * 2 : AppSpacing.xxl * 1.5,
                  isTablet ? AppSpacing.xxl * 1.2 : AppSpacing.xxl,
                ),
                painter: _WavyLinePainter(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      child: Icon(
                        icon,
                        size: AppTextSize.title(context),
                        color: Colors.white,
                      ),
                    ),
                    Icon(
                      Icons.more_horiz,
                      color: Colors.white.withOpacity(0.9),
                      size: AppTextSize.subtitle(context),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? AppSpacing.xl : AppSpacing.lg),
                Text(
                  isLoading ? '...' : value,
                  style: AppTextSize.headlineStyle(
                    context,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  style: AppTextSize.bodyStyle(
                    context,
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne ondulée discrète en arrière-plan.
class _WavyLinePainter extends CustomPainter {
  final Color color;

  _WavyLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    path.moveTo(0, size.height * 0.6);
    for (var i = 0.0; i <= size.width + 8; i += 8) {
      path.quadraticBezierTo(
        i + 4,
        size.height * 0.3,
        i + 8,
        size.height * 0.6,
      );
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Deux cartes KPI côte à côte (Achats du mois + Chiffre d'affaires).
class SalesStatsCard extends StatelessWidget {
  final String monthlyPurchasesLabel;
  final String monthlyPurchasesValue;
  final String revenueLabel;
  final String revenueValue;
  final bool isLoading;

  const SalesStatsCard({
    super.key,
    required this.monthlyPurchasesLabel,
    required this.monthlyPurchasesValue,
    required this.revenueLabel,
    required this.revenueValue,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: monthlyPurchasesLabel,
            value: monthlyPurchasesValue,
            icon: Icons.calendar_month,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_KpiColors.blueStart, _KpiColors.blueEnd],
            ),
            isLoading: isLoading,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _KpiCard(
            label: revenueLabel,
            value: revenueValue,
            icon: Icons.currency_yen,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_KpiColors.greenStart, _KpiColors.greenEnd],
            ),
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}
