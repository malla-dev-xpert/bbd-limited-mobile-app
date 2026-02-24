import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';

/// Section liste / contenu principal de la page Sales.
/// Réutilisable pour afficher un bloc avec titre et contenu (liste, CTA, etc.).
class SalesListSection extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsets? padding;

  const SalesListSection({
    super.key,
    required this.title,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = DeviceBreakpoints.isTablet(context);
    final sectionPadding = padding ??
        EdgeInsets.only(
          top: isTablet ? AppSpacing.xxl : AppSpacing.xl,
        );

    return Padding(
      padding: sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextSize.titleStyle(context, color: Colors.grey[700]),
          ),
          SizedBox(height: AppSpacing.lg),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: EdgeInsets.all(isTablet ? AppSpacing.xl : AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.lg),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: AppSpacing.sm,
                  offset: Offset(0, AppSpacing.xs),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
