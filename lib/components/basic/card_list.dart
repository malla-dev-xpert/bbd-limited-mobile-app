// card_data.dart

import 'package:bbd_limited/core/services/access_control_service.dart';
import 'package:bbd_limited/models/user.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class CardData {
  final IconData icon;
  final String title;
  final Color backgroundColor;
  final Color iconColor;
  final Color titleColor;
  final void Function(BuildContext context) onPressed;
  final String? description;

  CardData({
    required this.icon,
    required this.title,
    required this.backgroundColor,
    required this.iconColor,
    required this.titleColor,
    required this.onPressed,
    this.description,
  });
}

class MenuCategory {
  final String title;
  final List<CardData> items;

  MenuCategory({
    required this.title,
    required this.items,
  });
}

List<MenuCategory> getMenuCategories(
    BuildContext context, AppLocalizations localizations,
    {User? user, bool isAdmin = false}) {
  // Si l'utilisateur est restreint, on ne montre aucune option
  if (user != null && !AccessControlService().canShowBasicHomeOptions(user)) {
    return [];
  }

  return [
    // Catégorie: Informations de base
    MenuCategory(
      title: localizations.translate('home_basic_info'),
      items: [
        CardData(
          icon: Icons.person_3_rounded,
          title: localizations.translate('home_manage_partners_title'),
          backgroundColor: Colors.grey[50]!,
          iconColor: const Color(0xFF13084F),
          titleColor: const Color(0xFF13084F),
          onPressed: (context) {
            Navigator.of(context).pushNamed('/partners');
          },
          description: localizations.translate('home_manage_partners_desc'),
        ),
        CardData(
          icon: Icons.local_shipping,
          title: localizations.translate('home_manage_suppliers_title'),
          backgroundColor: Colors.grey[50]!,
          iconColor: const Color(0xFF13084F),
          titleColor: const Color(0xFF13084F),
          onPressed: (context) {
            Navigator.of(context).pushNamed('/suppliers');
          },
          description: localizations.translate('home_manage_suppliers_desc'),
        ),
        CardData(
          icon: Icons.warehouse,
          title: localizations.translate('home_manage_warehouses_title'),
          backgroundColor: Colors.grey[50]!,
          iconColor: const Color(0xFF13084F),
          titleColor: const Color(0xFF13084F),
          onPressed: (context) {
            Navigator.of(context).pushNamed('/warehouse');
          },
          description: localizations.translate('home_manage_warehouses_desc'),
        ),
        CardData(
          icon: Icons.info,
          title: localizations.translate('home_manage_ports_title'),
          backgroundColor: Colors.grey[50]!,
          iconColor: const Color(0xFF13084F),
          titleColor: const Color(0xFF13084F),
          onPressed: (context) {
            Navigator.of(context).pushNamed('/harbor');
          },
          description: localizations.translate('home_manage_ports_desc'),
        ),
        CardData(
          icon: Icons.monetization_on_rounded,
          title: localizations.translate('home_manage_devices_title'),
          backgroundColor: Colors.grey[50]!,
          iconColor: const Color(0xFF13084F),
          titleColor: const Color(0xFF13084F),
          onPressed: (context) {
            Navigator.of(context).pushNamed('/devises');
          },
          description: localizations.translate('home_manage_devices_desc'),
        ),
      ],
    ),
    // Catégorie: Inventaire et Logistique
    MenuCategory(
      title: localizations.translate('home_inventory_logistics'),
      items: [
        CardData(
          icon: Icons.inventory_2,
          title: localizations.translate('home_manage_packages_title'),
          backgroundColor: Colors.grey[50]!,
          iconColor: const Color(0xFF13084F),
          titleColor: const Color(0xFF13084F),
          onPressed: (context) {
            Navigator.of(context).pushNamed('/package');
          },
          description: localizations.translate('home_manage_packages_desc'),
        ),
        CardData(
          icon: Icons.view_quilt,
          title: localizations.translate('home_manage_containers_title'),
          backgroundColor: Colors.grey[50]!,
          iconColor: const Color(0xFF13084F),
          titleColor: const Color(0xFF13084F),
          onPressed: (context) {
            Navigator.of(context).pushNamed('/container');
          },
          description: localizations.translate('home_manage_containers_desc'),
        ),
      ],
    ),
    // Catégorie: Administration (si admin)
    if (isAdmin)
      MenuCategory(
        title: localizations.translate('home_administration'),
        items: [
          CardData(
            icon: Icons.history,
            title: localizations.translate('home_activity_history_title'),
            backgroundColor: Colors.grey[50]!,
            iconColor: const Color(0xFF13084F),
            titleColor: const Color(0xFF13084F),
            onPressed: (context) {
              Navigator.of(context).pushNamed('/activity-history');
            },
            description: localizations.translate('home_activity_history_desc'),
          ),
        ],
      ),
  ];
}

// Fonction de compatibilité pour l'ancien code
List<CardData> getCardDataList(
    BuildContext context, AppLocalizations localizations,
    {bool isAdmin = false}) {
  final categories =
      getMenuCategories(context, localizations, isAdmin: isAdmin);
  return categories.expand((category) => category.items).toList();
}
