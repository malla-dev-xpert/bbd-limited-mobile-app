import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/components/item_detail_chip.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ReusableItemCard extends StatelessWidget {
  final Items item;
  final Achat? achat;
  final List<Widget>? actions;
  final bool showSupplierInfo;
  final bool showPurchaseInfo;
  final bool isLoading;
  final Future<void> Function(Items item, Achat? achat)? onConfirm;
  final VoidCallback? onTap;

  final bool showAdminInfo;
  final bool showPaymentStatus;
  final bool showReceptionInfo;
  final Widget? extraDetails;

  const ReusableItemCard({
    Key? key,
    required this.item,
    this.achat,
    this.actions,
    this.showSupplierInfo = false,
    this.showPurchaseInfo = false,
    this.isLoading = false,
    this.showAdminInfo = false,
    this.showPaymentStatus = false,
    this.showReceptionInfo = false,
    this.onConfirm,
    this.onTap,
    this.extraDetails,
  }) : super(key: key);

  String _formatAmount(double? amount) {
    if (amount == null) return "0,00";
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]} ',
        )
        .replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isConfirmed = item.status == Status.RECEIVED;

    Widget cardContent = Container(
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description & status
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
                              fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                            children: [
                              TextSpan(
                                text: '${loc.translate('invoice_number')}: ',
                              ),
                              TextSpan(
                                text: item.invoiceNumber ?? 'N/A',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (showPaymentStatus)
                    item.paid == true
                        ? Image.asset(
                            'assets/images/paid.png',
                            width: 44,
                            height: 44,
                          )
                        : Image.asset(
                            'assets/images/not-paid.png',
                            width: 44,
                            height: 44,
                          )
                  else
                    Image.asset(
                      isConfirmed
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

              // Item Details (Chips)
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
                  const SizedBox(width: 16),
                  ItemDetailChip(
                    text:
                        '${loc.translate('unit_price')}: ${_formatAmount(item.unitPrice)} ¥',
                    icon: Icons.currency_yen,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ItemDetailChip(
                    text:
                        '${loc.translate('weight')}: ${item.totalWeight ?? 0}',
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
                        '${loc.translate('total')}: ${_formatAmount(item.totalPrice ?? (item.quantity ?? 0) * (item.unitPrice ?? 0))} ¥',
                    icon: Icons.calculate,
                    fullWidth: true,
                  ),
                  if (showPaymentStatus) ...[
                    const SizedBox(height: 8),
                    ItemDetailChip(
                      text:
                          '${loc.translate('total_amount_paid')}: ${_formatAmount(item.amountPaid)} ¥',
                      icon: Icons.payments,
                      fullWidth: true,
                    ),
                    const SizedBox(height: 8),
                    ItemDetailChip(
                      text:
                          '${loc.translate('remaining_amount')}: ${_formatAmount((item.totalPrice ?? 0) - (item.amountPaid ?? 0))} ¥',
                      icon: Icons.account_balance_wallet,
                      fullWidth: true,
                    ),
                  ],
                  if (showAdminInfo) ...[
                    const SizedBox(height: 8),
                    ItemDetailChip(
                      text:
                          '${loc.translate('paid_by')}: ${item.paidByUserName ?? 'N/A'}',
                      icon: Icons.person,
                      fullWidth: true,
                    ),
                    const SizedBox(height: 8),
                    ItemDetailChip(
                      text:
                          '${loc.translate('paid_date')}: ${item.paiementDate != null ? DateFormat('dd/MM/yyyy').format(item.paiementDate!) : 'N/A'}',
                      icon: Icons.date_range,
                      fullWidth: true,
                    ),
                  ],
                  if (showReceptionInfo && item.status == Status.RECEIVED) ...[
                    const SizedBox(height: 8),
                    ItemDetailChip(
                      text:
                          '${loc.translate('received_by')}: ${item.receivedByUserName ?? 'N/A'}',
                      icon: Icons.person,
                      fullWidth: true,
                    ),
                    const SizedBox(height: 8),
                    ItemDetailChip(
                      text:
                          '${loc.translate('received_at')}: ${item.receivedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(item.receivedAt!) : 'N/A'}',
                      icon: Icons.event_available,
                      fullWidth: true,
                    ),
                  ],
                  if (extraDetails != null) ...[
                    const SizedBox(height: 8),
                    extraDetails!,
                  ],
                ],
              ),

              // Supplier Info
              if (showSupplierInfo) ...[
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

              // Purchase/Client Info
              if (showPurchaseInfo) ...[
                if (achat != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.receipt, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${loc.translate('client')}: ${achat!.client ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${loc.translate('purchase_history_date')}: ${DateFormat('dd/MM/yyyy').format(achat!.createdAt ?? DateTime.now())}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (achat!.isDebt == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7F78AF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              loc.translate('purchase_history_debt'),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF7F78AF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ] else if (item.clientName != null &&
                    item.clientName!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${loc.translate('client')}: ${item.clientName!.trim()}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (item.clientPhone != null &&
                                  item.clientPhone!.trim().isNotEmpty)
                                Text(
                                  '${loc.translate('purchase_history_phone')}: ${item.clientPhone!.trim()}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue[700],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              // Confirmation button
              if (!isConfirmed && onConfirm != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pending_actions,
                          size: 20, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.translate('purchase_history_item_pending'),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.orange[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed:
                            isLoading ? null : () => onConfirm!(item, achat),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(
                          isLoading
                              ? loc.translate('loading_short')
                              : loc.translate('confirm_short'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1E49),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (actions != null && actions!.isNotEmpty) {
      return Slidable(
        key: ValueKey('item_${item.id}'),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.35,
          children: actions!,
        ),
        child: cardContent,
      );
    }

    return cardContent;
  }
}
