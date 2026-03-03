import 'package:bbd_limited/core/constants/design_system.dart';
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
  final bool isSelected;
  final bool isSelectionMode;

  const ContainerListItem({
    super.key,
    required this.container,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
    this.isSelected = false,
    this.isSelectionMode = false,
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
        return AppLocalizations.of(context).translate('container_in_progress');
      case Status.RECEIVED:
        return AppLocalizations.of(context).translate('container_arrived');
      case Status.PENDING:
        return AppLocalizations.of(context).translate('container_waiting');
      default:
        return container.status.toString();
    }
  }

  /// Titre affiché : N° conteneur en 1ère position, puis référence.
  String _displayTitle() {
    final num = container.containerNumber?.trim();
    final ref = container.reference?.trim();
    if (num != null && num.isNotEmpty && ref != null && ref.isNotEmpty) {
      return '$num · $ref';
    }
    if (num != null && num.isNotEmpty) return num;
    return ref ?? '';
  }

  bool _allItemsSameClient() {
    final items = container.items;
    if (items != null && items.isNotEmpty) {
      final keys = <String>{};
      for (final i in items) {
        if (i.clientId != null) {
          keys.add('id_${i.clientId}');
        } else if (i.clientName != null && i.clientName!.trim().isNotEmpty) {
          keys.add('name_${i.clientName!.trim()}');
        }
      }
      if (keys.length >= 2) return false;
      return true;
    }
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
    final isTablet = DeviceBreakpoints.isTablet(context);
    final loc = AppLocalizations.of(context);
    final statusColor = _getStatusColor();
    final statusText = _getStatusText(context);
    final isTeam = _allItemsSameClient() || container.isTeam == true;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? AppSpacing.md : AppSpacing.sm,
      ),
      child: Slidable(
        enabled: !isSelectionMode && container.status != Status.INPROGRESS,
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: isTablet ? 0.25 : 0.4,
          children: [
            SlidableAction(
              onPressed: (container.status != Status.INPROGRESS &&
                      container.status != Status.RECEIVED)
                  ? (context) => onEdit()
                  : null,
              backgroundColor: const Color(0xFF42A5F5),
              foregroundColor: Colors.white,
              icon: Icons.edit_outlined,
              label: loc.translate('container_edit'),
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (container.status != Status.INPROGRESS)
                  ? (context) => onDelete()
                  : null,
              backgroundColor: const Color(0xFFEF5350),
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: loc.translate('container_delete'),
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1A1E49).withOpacity(0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: const Color(0xFF1A1E49), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding:
                    EdgeInsets.all(isTablet ? AppSpacing.xl : AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Icon + Title + Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isTeam
                                ? Colors.blue[50]
                                : Colors.deepPurple[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isTeam
                                ? Icons.person_outline
                                : Icons.supervised_user_circle_rounded,
                            size: 20,
                            color: isTeam
                                ? Colors.blue[700]
                                : Colors.deepPurple[700],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _displayTitle(),
                            style: AppTextSize.titleStyle(context,
                                color: const Color(0xFF1A1E49),
                                fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // _buildStatusChip(context, statusColor, statusText),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Shipping Path: Source --- [Icon] ---> Destination
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc
                                      .translate('departure_harbor')
                                      .toUpperCase(),
                                  style: AppTextSize.captionStyle(context,
                                          color: Colors.grey[500])
                                      .copyWith(
                                          letterSpacing: 1.1,
                                          fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatHarbor(container.departureHarborName),
                                  style: AppTextSize.bodyStyle(context,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              children: [
                                Icon(Icons.directions_boat_filled,
                                    color: const Color(0xFF1A1E49)
                                        .withOpacity(0.7),
                                    size: 20),
                                const SizedBox(height: 4),
                                Icon(Icons.arrow_forward,
                                    color: Colors.grey[300], size: 14),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  loc.translate('arrival_harbor').toUpperCase(),
                                  style: AppTextSize.captionStyle(context,
                                          color: Colors.grey[500])
                                      .copyWith(
                                          letterSpacing: 1.1,
                                          fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatHarbor(container.arrivalHarborName),
                                  style: AppTextSize.bodyStyle(context,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Info Grid: Items Count + Size
                    Row(
                      children: [
                        _buildInfoItem(
                          context,
                          icon: Icons.inventory_2_outlined,
                          label:
                              "${container.items?.where((c) => c.status != Status.DELETE && c.status != Status.DELETE_ON_CONTAINER).length ?? 0}",
                          sublabel: loc.translate('container_packages_count'),
                        ),
                        Container(
                          height: 30,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.grey[200],
                        ),
                        _buildInfoItem(
                          context,
                          icon: Icons.straighten_outlined,
                          label: "${container.size ?? '—'}",
                          sublabel: loc.translate('container_size_feet'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Footer: Responsible Party
                    Row(
                      children: [
                        Icon(Icons.assignment_ind_outlined,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            container.supplier_id != null
                                ? '${container.supplierName ?? ""} ${container.supplierPhone?.isNotEmpty ?? false ? '| ' + container.supplierPhone! : ''}'
                                : loc.translate('container_bbd_limited'),
                            style: AppTextSize.bodyStyle(context,
                                color: Colors.grey[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildStatusChip(BuildContext context, Color color, String text) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  //     decoration: BoxDecoration(
  //       color: color.withOpacity(0.12),
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Text(
  //       text,
  //       style: AppTextSize.captionStyle(context, color: color)
  //           .copyWith(fontWeight: FontWeight.w700),
  //     ),
  //   );
  // }

  Widget _buildInfoItem(BuildContext context,
      {required IconData icon,
      required String label,
      required String sublabel}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1A1E49).withOpacity(0.6)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextSize.bodyStyle(context,
                  fontWeight: FontWeight.w800, color: const Color(0xFF1A1E49)),
            ),
            Text(
              sublabel,
              style: AppTextSize.captionStyle(context, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
}
