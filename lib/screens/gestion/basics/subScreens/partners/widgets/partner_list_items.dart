import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/partner_detail_screen.dart';

class PartnerListItem extends StatelessWidget {
  final Partner partner;
  final Function(Partner) onEdit;
  final Function(Partner) onDelete;

  const PartnerListItem({
    Key? key,
    required this.partner,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final balance = partner.balance ?? 0.0;
    final isNegative = balance <= 0;
    final statusColor = isNegative ? Colors.red[400] : Colors.green[400];

    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'CNY',
    );

    return Slidable(
      key: ValueKey(partner.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(partner),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Modifier',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(partner),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Supprimer',
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PartnerDetailScreen(partner: partner),
            ),
          );
        },
        child: ListTile(
          title: Text("${partner.firstName} ${partner.lastName}"),
          subtitle: Text(partner.phoneNumber),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    partner.accountType,
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
      ),
    );
  }
}
