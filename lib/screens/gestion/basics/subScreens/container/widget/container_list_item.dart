import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ContainerListItem extends StatelessWidget {
  final Containers container;
  final Function() onEdit;
  final Function() onDelete;
  final Function() onTap;

  const ContainerListItem({
    super.key,
    required this.container,
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
            onPressed: container.status != Status.INPROGRESS
                ? (context) => onEdit()
                : null,
            backgroundColor: container.status != Status.INPROGRESS
                ? Colors.blue
                : Colors.grey[300]!,
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
        leading: const Icon(
          Icons.view_quilt_sharp,
          size: 30,
          color: Color(0xFF1A1E49),
        ),
        title: Text(container.reference!),
        subtitle: Text(
          "Nombre de colis: ${container.packages?.where((c) => c.status != Status.DELETE || c.status != Status.DELETE_ON_CONTAINER).length}",
        ),
        trailing: Text(
          container.status == Status.INPROGRESS
              ? "En cours de livraison"
              : container.status == Status.RECEIVED
                  ? "Arrivé à destination"
                  : container.status == Status.PENDING
                      ? "Conteneur en attente"
                      : container.status.toString(),
          style: TextStyle(
            color: container.isAvailable == true ? Colors.green : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
