import 'package:bbd_limited/models/versement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class PaiementListItem extends StatelessWidget {
  final Versement versement;
  final Function() onEdit;
  final Function() onDelete;
  final Function() onTap;

  const PaiementListItem({
    super.key,
    required this.versement,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
    );
    final isNegative = versement.montantRestant! < 0;
    final statusColor = isNegative ? Colors.red[400] : Colors.green[400];

    // Déterminer l'icône en fonction du type de compte
    final IconData partnerIcon =
        versement.partnerAccountType?.toLowerCase() == 'client'
            ? Icons.person
            : Icons.business;

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onEdit(),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Modifier',
          ),
          SlidableAction(
            onPressed: (context) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Supprimer',
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(partnerIcon, color: Color(0xFF7F78AF)),
        title: Text(
          versement.reference!,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(versement.createdAt!),
              style: TextStyle(fontSize: 12),
            ),
            Text(
              versement.partnerName ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(versement.montantVerser),
                  style: const TextStyle(
                    color: Color(0xFF7F78AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  currencyFormat.format(versement.montantRestant),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
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
