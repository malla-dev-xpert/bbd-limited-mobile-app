import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/models/activity_log.dart';
import 'package:bbd_limited/utils/activity_log_translator.dart';
import 'package:bbd_limited/components/log_detail_page.dart';
import 'package:bbd_limited/core/enums/log_action.dart';
import 'package:bbd_limited/logs/widgets/log_action_badge.dart';

/// Widget pour afficher un item de log dans la timeline
/// Design moderne avec badge d'action et timeline verticale
class ActivityLogItem extends StatelessWidget {
  final ActivityLog log;

  const ActivityLogItem({
    super.key,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    final action = LogAction.fromString(log.actionCode);
    final actionText = ActivityLogTranslator.translateAction(log);
    final dateTimeText = ActivityLogTranslator.formatDateTime(log.createdAt);
    final userName = log.user.displayName;
    final isBulk = log.isBulkAction;
    final entityCount = log.entityCount;

    return InkWell(
      onTap: () {
        LogDetailPage.show(context, log.id);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline verticale avec point
            Builder(
              builder: (context) {
                final actionColor =
                    ActivityLogTranslator.getActionColor(log.actionCode);
                return Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: actionColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: actionColor.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 60,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 16),
            // Contenu principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge action (point focal)
                  LogActionBadge(
                    action: action,
                    fontSize: AppTextSize.caption(context),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Phrase métier (lisible)
                  Text(
                    actionText,
                    style: AppTextSize.bodyStyle(context,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87)
                        .copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  // Divider
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey[200],
                  ),
                  const SizedBox(height: 8),
                  // Informations secondaires (utilisateur + date)
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            userName,
                            style: AppTextSize.bodyStyle(context,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateTimeText,
                            style: AppTextSize.bodyStyle(context,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      // Badge pour les actions groupées
                      if (isBulk)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.layers_outlined,
                                size: 12,
                                color: Colors.deepPurple[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$entityCount',
                                style: AppTextSize.captionStyle(context,
                                        color: Colors.deepPurple[700])
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
