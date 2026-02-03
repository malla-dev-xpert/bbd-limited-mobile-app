import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

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

  String _getStatusText(BuildContext context) {
    switch (container.status) {
      case Status.INPROGRESS:
        return AppLocalizations.of(context)!.translate('container_in_progress');
      case Status.RECEIVED:
        return AppLocalizations.of(context)!.translate('container_arrived');
      case Status.PENDING:
        return AppLocalizations.of(context)!.translate('container_waiting');
      default:
        return container.status.toString();
    }
  }

  // Vérifie si tous les items sont pour le même client (clientId vient de l'achat dont l'item appartient)
  bool _allItemsSameClient() {
    final items = container.items;
    if (items != null && items.isNotEmpty) {
      final clientIds = items.map((i) => i.clientId).whereType<int>().toSet();
      if (clientIds.isNotEmpty) return clientIds.length == 1;
    }
    // Fallback: colis si pas d'items ou pas de clientId sur les items
    if (container.packages == null || container.packages!.isEmpty) return true;
    final firstClientId = container.packages!.first.clientId;
    return container.packages!.every((p) => p.clientId == firstClientId);
  }

  String _formatHarbor(String? name) {
    if (name == null || name.isEmpty) return '—';
    return name;
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
              label: AppLocalizations.of(context)!.translate('container_edit'),
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
              label:
                  AppLocalizations.of(context)!.translate('container_delete'),
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          // Layout vertical sur mobile
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(isTablet ? 8 : 4),
                                    decoration: BoxDecoration(
                                      color: _allItemsSameClient() ||
                                              container.isTeam == true
                                          ? Colors.blue[50]
                                          : Colors.deepPurple[50],
                                      borderRadius: BorderRadius.circular(
                                          isTablet ? 16 : 10),
                                    ),
                                    child: Icon(
                                      _allItemsSameClient() ||
                                              container.isTeam == true
                                          ? Icons.person
                                          : Icons.people,
                                      size: isTablet ? 24 : 16,
                                      color: Colors.deepPurple[800],
                                    ),
                                  ),
                                  SizedBox(width: isTablet ? 8 : 4),
                                  Expanded(
                                    child: Text(
                                      container.reference!,
                                      style: TextStyle(
                                        fontSize: isTablet ? 22 : 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1A1E49),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
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
                                      _getStatusText(context),
                                      style: TextStyle(
                                        color: _getStatusColor(),
                                        fontWeight: FontWeight.w600,
                                        fontSize: isTablet ? 18 : 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Layout horizontal pour tablettes
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(isTablet ? 8 : 4),
                                      decoration: BoxDecoration(
                                        color: _allItemsSameClient() ||
                                                container.isTeam == true
                                            ? Colors.blue[50]
                                            : Colors.deepPurple[50],
                                        borderRadius: BorderRadius.circular(
                                            isTablet ? 16 : 10),
                                      ),
                                      child: Icon(
                                        _allItemsSameClient() ||
                                                container.isTeam == true
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
                                      _getStatusText(context),
                                      style: TextStyle(
                                        color: _getStatusColor(),
                                        fontWeight: FontWeight.w600,
                                        fontSize: isTablet ? 18 : 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                      },
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
                              "${container.items?.where((c) => c.status != Status.DELETE || c.status != Status.DELETE_ON_CONTAINER).length} ${AppLocalizations.of(context)!.translate('container_packages_count')}",
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
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
                              "${container.size}",
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (container.departureHarborName != null ||
                        container.departureHarborId != null ||
                        container.arrivalHarborName != null ||
                        container.arrivalHarborId != null) ...[
                      SizedBox(height: isTablet ? 10 : 6),
                      Row(
                        children: [
                          Icon(
                            Icons.sailing,
                            size: isTablet ? 20 : 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: isTablet ? 6 : 4),
                          Expanded(
                            child: Text(
                              _formatHarbor(container.departureHarborName),
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 8 : 4),
                            child: Icon(
                              Icons.arrow_forward,
                              size: isTablet ? 18 : 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          Icon(
                            Icons.pin_drop,
                            size: isTablet ? 20 : 14,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: isTablet ? 6 : 4),
                          Expanded(
                            child: Text(
                              _formatHarbor(container.arrivalHarborName),
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                                : AppLocalizations.of(context)!
                                    .translate('container_bbd_limited'),
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
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
