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
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: isTablet ? AppSpacing.md : AppSpacing.sm),
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
            color: Colors.white,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
              child: Padding(
                padding:
                    EdgeInsets.all(isTablet ? AppSpacing.xl : AppSpacing.md),
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
                                    padding: EdgeInsets.all(isTablet
                                        ? AppSpacing.sm
                                        : AppSpacing.xs),
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
                                          : Icons.group_work,
                                      size: isTablet
                                          ? AppTextSize.title(context)
                                          : AppTextSize.body(context),
                                      color: Colors.deepPurple[800],
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      _displayTitle(),
                                      style: AppTextSize.titleStyle(
                                        context,
                                        color: const Color(0xFF1A1E49),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      isTablet ? AppSpacing.lg : AppSpacing.md,
                                  vertical:
                                      isTablet ? AppSpacing.md : AppSpacing.xs,
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
                                    SizedBox(
                                        width: isTablet
                                            ? AppSpacing.sm
                                            : AppSpacing.xs),
                                    Text(
                                      _getStatusText(context),
                                      style: AppTextSize.bodyStyle(context,
                                          color: _getStatusColor(),
                                          fontWeight: FontWeight.w600),
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
                                      padding: EdgeInsets.all(isTablet
                                          ? AppSpacing.sm
                                          : AppSpacing.xs),
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
                                            : Icons.group_work,
                                        size: isTablet
                                            ? AppTextSize.title(context)
                                            : AppTextSize.body(context),
                                        color: Colors.deepPurple[800],
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.xs),
                                    Text(
                                      _displayTitle(),
                                      style: AppTextSize.subtitleStyle(context,
                                          color: const Color(0xFF1A1E49),
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              // Container(
                              //   padding: EdgeInsets.symmetric(
                              //     horizontal:
                              //         isTablet ? AppSpacing.lg : AppSpacing.md,
                              //     vertical:
                              //         isTablet ? AppSpacing.md : AppSpacing.xs,
                              //   ),
                              //   decoration: BoxDecoration(
                              //     color: _getStatusColor().withOpacity(0.1),
                              //     borderRadius:
                              //         BorderRadius.circular(isTablet ? 28 : 20),
                              //     border: Border.all(
                              //       color: _getStatusColor().withOpacity(0.3),
                              //       width: 1,
                              //     ),
                              //   ),
                              //   child: Row(
                              //     mainAxisSize: MainAxisSize.min,
                              //     children: [
                              //       Container(
                              //         width: isTablet ? 12 : 8,
                              //         height: isTablet ? 12 : 8,
                              //         decoration: BoxDecoration(
                              //           color: _getStatusColor(),
                              //           shape: BoxShape.circle,
                              //         ),
                              //       ),
                              //       SizedBox(
                              //           width: isTablet
                              //               ? AppSpacing.sm
                              //               : AppSpacing.xs),
                              //       Text(
                              //         _getStatusText(context),
                              //         style: AppTextSize.bodyStyle(context,
                              //             color: _getStatusColor(),
                              //             fontWeight: FontWeight.w600),
                              //       ),
                              //     ],
                              //   ),
                              // ),
                            ],
                          );
                        }
                      },
                    ),
                    SizedBox(height: isTablet ? AppSpacing.md : AppSpacing.xs),
                    Wrap(
                      spacing: isTablet ? AppSpacing.xxl : AppSpacing.lg,
                      runSpacing: isTablet ? AppSpacing.md : AppSpacing.xs,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: AppTextSize.title(context),
                              color: Colors.grey[800],
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              "${container.items?.where((c) => c.status != Status.DELETE || c.status != Status.DELETE_ON_CONTAINER).length} ${AppLocalizations.of(context)!.translate('container_packages_count')}",
                              style: AppTextSize.titleStyle(context,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.straighten,
                              size: AppTextSize.title(context),
                              color: Colors.grey[800],
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              "${container.size}",
                              style: AppTextSize.titleStyle(context,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (container.departureHarborName != null ||
                        container.departureHarborId != null ||
                        container.arrivalHarborName != null ||
                        container.arrivalHarborId != null) ...[
                      SizedBox(
                          height: isTablet ? AppSpacing.sm : AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.sailing,
                            size: AppTextSize.title(context),
                            color: Colors.grey[800],
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              _formatHarbor(container.departureHarborName),
                              style: AppTextSize.titleStyle(context,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                            child: Icon(
                              Icons.arrow_forward,
                              size: AppTextSize.caption(context) + 2,
                              color: Colors.grey[500],
                            ),
                          ),
                          Icon(
                            Icons.pin_drop,
                            size: AppTextSize.title(context),
                            color: Colors.grey[800],
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              _formatHarbor(container.arrivalHarborName),
                              style: AppTextSize.titleStyle(context,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.person_3,
                          size: AppTextSize.title(context),
                          color: Colors.grey[800],
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            container.supplier_id != null
                                ? '${container.supplierName ?? ""} ${container.supplierPhone?.isNotEmpty ?? false ? '|' : ''} ${container.supplierPhone ?? ""}'
                                : AppLocalizations.of(context)!
                                    .translate('container_bbd_limited'),
                            style: AppTextSize.titleStyle(context,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500),
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
