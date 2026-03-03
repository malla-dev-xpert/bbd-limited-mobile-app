import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  const ResponsiveContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.horizontal(context),
      child: child,
    );
  }
}
