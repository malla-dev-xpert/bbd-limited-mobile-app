import 'package:flutter/material.dart';
import 'package:bbd_limited/components/item_detail_chip.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/utils/amount_format.dart';

/// Liste des articles du client/partenaire, même design que l'historique des achats.
class PartnerArticlesListWidget extends StatelessWidget {
  final List<Items>? items;
  final Future<void> Function() onRefresh;

  const PartnerArticlesListWidget({
    Key? key,
    required this.items,
    required this.onRefresh,
  }) : super(key: key);

  String _formatAmount(double? amount) {
    if (amount == null) return '0,00';
    return formatAmount(amount).replaceAll('.', ',');
  }

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
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
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
          return _buildItemCard(context, item);
        },
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Items item) {
    final loc = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1E49).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Color(0xFF1A1E49),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                          children: [
                            TextSpan(
                              text: '${loc.translate('invoice_number')}: ',
                            ),
                            TextSpan(
                              text: item.invoiceNumber ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Image.asset(
                  item.status == Status.RECEIVED
                      ? 'assets/images/delivery.png'
                      : 'assets/images/no-delivery.png',
                  width: 44,
                  height: 44,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ItemDetailChip(
                  text: '${loc.translate('carton')}: ${item.carton ?? 0}',
                  icon: Icons.inventory,
                ),
                const SizedBox(width: 16),
                ItemDetailChip(
                  text:
                      '${loc.translate('quantity_per_carton_2')}: ${item.quantityPerCarton ?? 0}',
                  icon: Icons.format_list_numbered,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ItemDetailChip(
                  text:
                      '${loc.translate('total_quantity')}: ${item.quantity ?? 0}',
                  icon: Icons.numbers,
                ),
                const SizedBox(width: 8),
                ItemDetailChip(
                  text: '${_formatAmount(item.unitPrice)} ¥',
                  icon: Icons.attach_money,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ItemDetailChip(
                  text: '${loc.translate('weight')}: ${item.totalWeight ?? 0}',
                  icon: Icons.scale,
                ),
                const SizedBox(width: 16),
                ItemDetailChip(
                  text: '${loc.translate('cbn')}: ${item.cbnTotal ?? 0}',
                  icon: Icons.straighten,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                ItemDetailChip(
                  text:
                      '${loc.translate('sales_rate')}: ${item.salesRate ?? 0}',
                  icon: Icons.trending_up,
                  fullWidth: true,
                ),
                const SizedBox(height: 8),
                ItemDetailChip(
                  text:
                      '${loc.translate('total')}: ${_formatAmount((item.quantity ?? 0) * (item.unitPrice ?? 0))} ¥',
                  icon: Icons.calculate,
                  fullWidth: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.purple[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${loc.translate('supplier')}: ${item.supplierName ?? loc.translate('not_available')}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.purple[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (item.supplierPhone != null &&
                            (item.supplierPhone as String).isNotEmpty)
                          Text(
                            '${loc.translate('purchase_history_phone')}: ${item.supplierPhone}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.purple[700],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
