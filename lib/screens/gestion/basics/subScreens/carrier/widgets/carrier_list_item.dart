import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/models/carrier.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class CarrierListItem extends StatelessWidget {
  final Carrier carrier;
  final Function(Carrier) onDelete;

  const CarrierListItem({
    Key? key,
    required this.carrier,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(carrier.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(carrier),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: AppLocalizations.of(context).translate('delete'),
          ),
        ],
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF1A1E49),
          child: Icon(Icons.local_shipping, color: Colors.white),
        ),
        title: Text(
          carrier.name ?? AppLocalizations.of(context).translate('na'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(carrier.contact ?? ''),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
