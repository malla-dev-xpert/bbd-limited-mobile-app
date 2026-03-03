import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/components/reusable_item_card.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/models/achats/achat.dart';

/// Liste des articles du client/partenaire, même design que l'historique des achats.
class PartnerArticlesListWidget extends StatelessWidget {
  final List<Items>? items;
  final Future<void> Function() onRefresh;

  const PartnerArticlesListWidget({
    Key? key,
    required this.items,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items == null || items!.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)
                        .translate('purchase_history_no_items'),
                    style: AppTextSize.titleStyle(context, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        itemCount: items!.length,
        itemBuilder: (context, index) {
          final item = items![index];
          return ReusableItemCard(
            item: item,
            showSupplierInfo: true,
            // Note: achat might not be available here as it's a list from item services
            // but the ReusableItemCard handles null achat gracefully.
          );
        },
      ),
    );
  }
}
