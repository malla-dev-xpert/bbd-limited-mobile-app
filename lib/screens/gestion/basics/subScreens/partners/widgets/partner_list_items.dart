import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/models/partner.dart';

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
      child: ListTile(
        title: Text("${partner.firstName} ${partner.lastName}"),
        subtitle: Text(partner.phoneNumber),
        trailing: Text(
          partner.accountType,
          style: TextStyle(
            color: partner.accountType == 'CLIENT' ? Colors.blue : Colors.green,
          ),
        ),
      ),
    );
  }
}
