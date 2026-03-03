import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'report_card.dart';

class ReportCardData {
  final String title;
  final String value;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  ReportCardData({
    required this.title,
    required this.value,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });
}

class ReportCardList extends StatelessWidget {
  final List<ReportCard> items;
  final int crossAxisCount;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const ReportCardList({
    super.key,
    required this.items,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.1,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune donnée disponible',
                style: AppTextSize.titleStyle(context,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return items[index];
      },
    );
  }
}
