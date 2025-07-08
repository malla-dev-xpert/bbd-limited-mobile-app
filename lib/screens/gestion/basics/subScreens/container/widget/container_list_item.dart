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

  Color _getStatusColor() {
    switch (container.status) {
      case Status.INPROGRESS:
        return const Color(0xFFFFA726); // Orange plus doux
      case Status.RECEIVED:
        return const Color(0xFF66BB6A); // Vert plus doux
      case Status.PENDING:
        return const Color(0xFF42A5F5); // Bleu plus doux
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (container.status) {
      case Status.INPROGRESS:
        return "En cours de livraison";
      case Status.RECEIVED:
        return "Arrivé à destination";
      case Status.PENDING:
        return "Conteneur en attente";
      default:
        return container.status.toString();
    }
  }

  // Vérifie si tous les colis sont pour le même client
  bool _allPackagesSameClient() {
    if (container.packages == null || container.packages!.isEmpty) return true;
    final firstClientId = container.packages!.first.clientId;
    return container.packages!.every((p) => p.clientId == firstClientId);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 12.0 : 8.0),
      child: Slidable(
        enabled: container.status != Status.INPROGRESS,
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (container.status != Status.INPROGRESS &&
                      container.status != Status.RECEIVED)
                  ? (context) => onEdit()
                  : null,
              backgroundColor: (container.status != Status.INPROGRESS &&
                      container.status != Status.RECEIVED)
                  ? const Color(0xFF42A5F5)
                  : Colors.grey[300]!,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Modifier',
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
            ),
            SlidableAction(
              onPressed: (container.status != Status.INPROGRESS)
                  ? (context) => onDelete()
                  : null,
              backgroundColor: (container.status != Status.INPROGRESS)
                  ? const Color(0xFFEF5350)
                  : Colors.grey[300]!,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Supprimer',
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(12)),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: isTablet ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 24.0 : 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(isTablet ? 8 : 4),
                                decoration: BoxDecoration(
                                  color: _allPackagesSameClient()
                                      ? Colors.blue[50]
                                      : Colors.deepPurple[50],
                                  borderRadius:
                                      BorderRadius.circular(isTablet ? 16 : 10),
                                ),
                                child: Icon(
                                  _allPackagesSameClient()
                                      ? Icons.person
                                      : Icons.people,
                                  size: isTablet ? 24 : 16,
                                  color: Colors.deepPurple[800],
                                ),
                              ),
                              SizedBox(width: isTablet ? 8 : 4),
                              Text(
                                container.reference!,
                                style: TextStyle(
                                  fontSize: isTablet ? 22 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1E49),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 20 : 12,
                            vertical: isTablet ? 12 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(isTablet ? 28 : 20),
                            border: Border.all(
                              color: _getStatusColor().withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: isTablet ? 12 : 8,
                                height: isTablet ? 12 : 8,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: isTablet ? 10 : 6),
                              Text(
                                _getStatusText(),
                                style: TextStyle(
                                  color: _getStatusColor(),
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTablet ? 16 : 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 12 : 6),
                    Wrap(
                      spacing: isTablet ? 32 : 16,
                      runSpacing: isTablet ? 12 : 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: isTablet ? 24 : 16,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: isTablet ? 8 : 4),
                            Text(
                              "${container.packages?.where((c) => c.status != Status.DELETE || c.status != Status.DELETE_ON_CONTAINER).length} colis",
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.straighten,
                              size: isTablet ? 24 : 16,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: isTablet ? 8 : 4),
                            Text(
                              "${container.size} pieds",
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 8 : 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_3,
                          size: isTablet ? 24 : 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: isTablet ? 8 : 4),
                        Expanded(
                          child: Text(
                            container.supplier_id != null
                                ? '${container.supplierName ?? ""} ${container.supplierPhone?.isNotEmpty ?? false ? '|' : ''} ${container.supplierPhone ?? ""}'
                                : 'BBD Limited',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
