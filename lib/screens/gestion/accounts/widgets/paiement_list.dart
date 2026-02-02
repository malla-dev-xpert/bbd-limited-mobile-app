import 'package:bbd_limited/models/versement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/utils/amount_format.dart';
import 'package:bbd_limited/core/services/access_control_service.dart';
import 'package:bbd_limited/core/services/auth_services.dart';

class PaiementListItem extends StatelessWidget {
  final Versement versement;
  final Function() onEdit;
  final Function() onDelete;
  final Function() onTap;
  final Function()? onTransfer;

  const PaiementListItem({
    super.key,
    required this.versement,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
    this.onTransfer,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = versement.deviseCode ?? 'USD';

    final montantRestant = versement.montantRestant ?? 0.0;
    final isNegative = montantRestant < 0;
    final statusColor = isNegative ? Colors.red[400] : Colors.green[400];

    // Déterminer l'icône en fonction du type de compte
    final IconData partnerIcon =
        versement.partnerAccountType?.toLowerCase() == 'client'
            ? Icons.person
            : Icons.business;

    final user = AuthService.currentUser;
    final canDelete =
        user != null && AccessControlService().canDeletePayment(user);

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          if (onTransfer != null)
            SlidableAction(
              onPressed: (context) => onTransfer!(),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              icon: Icons.swap_horiz,
              label: 'Transférer',
            ),
          SlidableAction(
            onPressed: (context) => onEdit(),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Modifier',
          ),
          if (canDelete)
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(versement.createdAt!),
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              versement.partnerName ?? '',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                  formatAmountWithSymbol(
                      versement.montantVerser ?? 0, currencySymbol),
                  style: const TextStyle(
                    color: Color(0xFF7F78AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formatAmountWithSymbol(
                      versement.montantRestant ?? 0, currencySymbol),
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
