import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class SupplierListItem extends StatelessWidget {
  final Partner supplier;
  final Function(Partner) onEdit;
  final Function(Partner) onDelete;
  final Function(Partner)? onSupplierUpdated;

  const SupplierListItem({
    Key? key,
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
    this.onSupplierUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final balance = supplier.balance ?? 0.0;
    final isNegative = balance <= 0;
    final statusColor = isNegative ? Colors.red[400] : Colors.green[400];

    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'CNY',
    );

    return Slidable(
      key: ValueKey(supplier.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(supplier),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: AppLocalizations.of(context).translate('edit'),
          ),
          SlidableAction(
            onPressed: (_) => onDelete(supplier),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: AppLocalizations.of(context).translate('delete'),
          ),
        ],
      ),
      child: ListTile(
        title: Text("${supplier.firstName} ${supplier.lastName}"),
        subtitle: Text(supplier.phoneNumber),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  supplier.accountType,
                  style: const TextStyle(color: Colors.blue),
                ),
                Text(
                  currencyFormat.format(balance),
                  style: TextStyle(color: statusColor),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              isNegative ? Icons.arrow_downward : Icons.arrow_upward,
              color: statusColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

