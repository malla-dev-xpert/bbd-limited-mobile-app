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
        leading: Icon(
          Icons.view_quilt_sharp,
          size: 30,
          color: const Color(0xFF1A1E49),
        ),
        title: Text(container.reference!),
        subtitle: Text("Nombre de colis: ${container.packages?.length ?? 0}"),
        trailing: Text(
          container.isAvailable == true ? 'Disponible' : 'Indisponible',
          style: TextStyle(
            color: container.isAvailable == true ? Colors.green : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
