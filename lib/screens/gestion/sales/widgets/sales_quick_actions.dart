import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/screens/gestion/sales/widgets/sales_header.dart';

/// Une action rapide (label, icône, couleur existante, callback).
class SalesQuickActionItem {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const SalesQuickActionItem({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });
}

/// Tablet : 4 actions sur une ligne. Mobile : une action par ligne.
/// Toutes avec fond blanc, padding augmenté, icônes et texte plus grands.
class SalesQuickActions extends StatelessWidget {
  final String sectionTitle;
  final List<SalesQuickActionItem> items;

  const SalesQuickActions({
    super.key,
    required this.sectionTitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = DeviceBreakpoints.isTablet(context);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          sectionTitle,
          style: AppTextSize.titleStyle(context, color: Colors.grey[700]),
        ),
        SizedBox(height: AppSpacing.md),
        if (isTablet)
          Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i < items.length - 1 ? AppSpacing.md : 0,
                    ),
                    child: _CompactActionCard(item: items[i]),
                  ),
                ),
            ],
          )
        else
          Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _FullWidthActionTile(item: items[i]),
                ),
            ],
          ),
      ],
    );
  }
}

/// Tablette : carte compacte fond blanc (icône au-dessus du label).
class _CompactActionCard extends StatelessWidget {
  final SalesQuickActionItem item;

  const _CompactActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.lg),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: AppSpacing.md,
                offset: Offset(0, AppSpacing.xs),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: item.iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  item.icon,
                  size: AppTextSize.headline(context),
                  color: item.iconColor,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                item.label,
                style: AppTextSize.subtitleStyle(
                  context,
                  color: SalesColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mobile : une action par ligne, fond blanc, même style pour toutes.
class _FullWidthActionTile extends StatelessWidget {
  final SalesQuickActionItem item;

  const _FullWidthActionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.lg),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: AppSpacing.md,
                offset: Offset(0, AppSpacing.xs),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: item.iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  item.icon,
                  size: AppTextSize.headline(context),
                  color: item.iconColor,
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  item.label,
                  style: AppTextSize.titleStyle(
                    context,
                    color: SalesColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: AppTextSize.title(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
