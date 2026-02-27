import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/models/carrier.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class CarrierListItem extends StatelessWidget {
  final Carrier carrier;
  final Function(Carrier) onDelete;
  final Function(Carrier) onEdit;

  const CarrierListItem({
    Key? key,
    required this.carrier,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Slidable(
      key: ValueKey(carrier.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(carrier),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: loc.translate('edit'),
          ),
          SlidableAction(
            onPressed: (_) => onDelete(carrier),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: loc.translate('delete'),
          ),
        ],
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF1A1E49),
          child: Icon(Icons.local_shipping, color: Colors.white),
        ),
        title: Text(
          carrier.name ?? loc.translate('na'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(carrier.contact ?? ''),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
