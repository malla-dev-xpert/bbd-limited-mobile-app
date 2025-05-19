import 'package:bbd_limited/core/enums/status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/models/expedition.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ion.dart';
import 'package:iconify_flutter/icons/ph.dart';

class ExpeditionListItem extends StatelessWidget {
  final Expedition expedition;
  final Function() onEdit;
  final Function() onDelete;
  final Function() onTap;

  const ExpeditionListItem({
    super.key,
    required this.expedition,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
        leading: Iconify(
          expedition.expeditionType == 'Avion'
              ? Ph.airplane_tilt_fill
              : Ion.boat_sharp,
          color:
              expedition.status == Status.PENDING
                  ? Colors.amber
                  : expedition.status == Status.DELIVERED
                  ? Colors.green
                  : Colors.blue[400],
        ),
        title: Text(
          expedition.ref ?? 'Sans référence',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("De: ${expedition.startCountry ?? 'N/A'}"),
            Text("Vers: ${expedition.destinationCountry ?? 'N/A'}"),
            Text("Client: ${expedition.clientName ?? 'Client inconnu'}"),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            expedition.expeditionType == 'Avion'
                ? "Poids: ${expedition.weight ?? 0}kg"
                : "CBN: ${expedition.cbn ?? 0}m³",
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
