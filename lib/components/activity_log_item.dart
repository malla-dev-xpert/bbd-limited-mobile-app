import 'package:flutter/material.dart';
import 'package:bbd_limited/models/activity_log.dart';
import 'package:bbd_limited/utils/activity_log_translator.dart';

class ActivityLogItem extends StatelessWidget {
  final ActivityLog log;

  const ActivityLogItem({
    super.key,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    final actionColor = ActivityLogTranslator.getActionColor(log.actionCode);
    final actionIcon = ActivityLogTranslator.getActionIcon(log.actionCode);
    final actionText = ActivityLogTranslator.translateAction(log);
    final dateTimeText = ActivityLogTranslator.formatDateTime(log.createdAt);
    final userName = log.user.displayName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône avec couleur
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: actionColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                actionIcon,
                color: actionColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Contenu du log
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phrase d'action
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1E49),
                          ),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: actionText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Date et heure
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateTimeText,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
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
