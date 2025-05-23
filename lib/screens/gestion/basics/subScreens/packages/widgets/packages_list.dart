import 'package:bbd_limited/models/package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/core/enums/status.dart';

class PackageListItem extends StatelessWidget {
  final Packages packages;
  final Function() onEdit;
  final Function() onDelete;
  final Function() onTap;

  const PackageListItem({
    super.key,
    required this.packages,
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
        leading: Icon(Icons.inventory, color: _getStatusColor(packages.status)),
        title: Text(packages.reference!),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dimensions: ${packages.dimensions} /m³"),
            Text("${packages.items?.length} articles"),
          ],
        ),
        trailing: Text(
          "Poids: ${packages.weight}kg",
          style: const TextStyle(
            color: Color(0xFF7F78AF),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(Status? status) {
    switch (status) {
      case Status.PENDING:
        return Colors.orange;
      case Status.RECEIVED || Status.IN_CONTAINER:
        return Colors.green;
      case Status.DELIVERED:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
