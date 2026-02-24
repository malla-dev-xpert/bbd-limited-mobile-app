import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';

/// Reusable filter chip/button with optional active state and badge.
/// Uses Design System spacing and typography.
class FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final IconData? icon;
  final int? badgeCount;

  const FilterButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.icon,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = DeviceBreakpoints.isTablet(context);
    final primaryColor = const Color(0xFF1A1E49);

    return Padding(
      padding: EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          // borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? AppSpacing.xl : AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: isActive ? primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? primaryColor : Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: AppTextSize.body(context),
                    color: isActive ? Colors.white : primaryColor,
                  ),
                  SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTextSize.body(context),
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.white : primaryColor,
                  ),
                ),
                if (badgeCount != null && badgeCount! > 0) ...[
                  SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withOpacity(0.3)
                          : primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeCount! > 99 ? '99+' : '$badgeCount',
                      style: TextStyle(
                        fontSize: AppTextSize.caption(context),
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : primaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
