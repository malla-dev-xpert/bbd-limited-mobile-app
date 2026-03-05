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

/// Menu pour le rôle EMPLOYE_D : Conteneur, Liste des articles, et gestion CBM (tout faire).
List<MenuCategory> _getMenuCategoriesEmployeD(
    BuildContext context, AppLocalizations localizations) {
  return [
    MenuCategory(
      title: localizations.translate('home_inventory_logistics'),
      items: [
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
        CardData(
          icon: Icons.assessment,
          title: localizations.translate('home_items_list'),
          backgroundColor: Colors.grey[50]!,
          iconColor: const Color(0xFF13084F),
          titleColor: const Color(0xFF13084F),
          onPressed: (context) {
            Navigator.of(context).pushNamed('/items-list');
          },
          description: localizations.translate('home_items_list_desc'),
        ),
        CardData(
          icon: Icons.square_foot,
          title: localizations.translate('home_manage_cbm_pricing_title'),
          backgroundColor: Colors.grey[50]!,
          iconColor: const Color(0xFF13084F),
          titleColor: const Color(0xFF13084F),
          onPressed: (context) {
            Navigator.of(context).pushNamed('/cbm-pricing');
          },
          description: localizations.translate('home_manage_cbm_pricing_desc'),
        ),
      ],
    ),
  ];
}

List<MenuCategory> getMenuCategories(
    BuildContext context, AppLocalizations localizations,
    {User? user, bool isAdmin = false}) {
  if (user != null && AccessControlService().isEmployeD(user)) {
    return _getMenuCategoriesEmployeD(context, localizations);
  }

  final isRestricted =
      user != null && AccessControlService().isRestrictedBranch(user);

  List<CardData> basicInfoItems = [];

  // 1. Partenaires (Accessible à tous)
  basicInfoItems.add(
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
  );

  // 2. Fournisseurs (Masqué pour restreints)
  if (!isRestricted) {
    basicInfoItems.add(
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
    );
  }

  // 3. Entrepôts (Accessible à tous)
  basicInfoItems.add(
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
  );

  // 4. Ports (Masqué pour restreints)
  if (!isRestricted) {
    basicInfoItems.add(
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
    );
  }

  // 5. Devises (Accessible à tous)
  basicInfoItems.add(
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
  );

  // 6. CBM Pricing (Accessible à tous)
  basicInfoItems.add(
    CardData(
      icon: Icons.square_foot,
      title: localizations.translate('home_manage_cbm_pricing_title'),
      backgroundColor: Colors.grey[50]!,
      iconColor: const Color(0xFF13084F),
      titleColor: const Color(0xFF13084F),
      onPressed: (context) {
        Navigator.of(context).pushNamed('/cbm-pricing');
      },
      description: localizations.translate('home_manage_cbm_pricing_desc'),
    ),
  );

  List<MenuCategory> categories = [
    MenuCategory(
      title: localizations.translate('home_basic_info'),
      items: basicInfoItems,
    ),
  ];

  // Catégorie: Inventaire et Logistique (Masqué pour restreints)
  if (!isRestricted) {
    categories.add(
      MenuCategory(
        title: localizations.translate('home_inventory_logistics'),
        items: [
          // CardData(
          //   icon: Icons.inventory_2,
          //   title: localizations.translate('home_manage_packages_title'),
          //   backgroundColor: Colors.grey[50]!,
          //   iconColor: const Color(0xFF13084F),
          //   titleColor: const Color(0xFF13084F),
          //   onPressed: (context) {
          //     Navigator.of(context).pushNamed('/package');
          //   },
          //   description: localizations.translate('home_manage_packages_desc'),
          // ),
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
          CardData(
            icon: Icons.local_shipping,
            title: localizations.translate('home_manage_carriers_title'),
            backgroundColor: Colors.grey[50]!,
            iconColor: const Color(0xFF13084F),
            titleColor: const Color(0xFF13084F),
            onPressed: (context) {
              Navigator.of(context).pushNamed('/carriers');
            },
            description: localizations.translate('home_manage_carriers_desc'),
          ),
        ],
      ),
    );
  }

  if (isAdmin && !isRestricted) {
    categories.add(
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
    );
  }

  return categories;
}

// Fonction de compatibilité pour l'ancien code
List<CardData> getCardDataList(
    BuildContext context, AppLocalizations localizations,
    {bool isAdmin = false}) {
  final categories =
      getMenuCategories(context, localizations, isAdmin: isAdmin);
  return categories.expand((category) => category.items).toList();
}
