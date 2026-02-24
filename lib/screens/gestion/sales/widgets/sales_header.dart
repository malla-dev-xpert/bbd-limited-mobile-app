import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';

/// Couleurs existantes de l'application (aucune nouvelle couleur).
abstract final class SalesColors {
  static const Color primary = Color(0xFF1A1E49);
  static const Color primaryLight = Color(0xFF2A2E69);
}

/// Header / AppBar de la page Sales. Design system strict.
class SalesHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const SalesHeader({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: AppTextSize.titleStyle(context, color: Colors.white),
      ),
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: SalesColors.primary,
    );
  }
}
