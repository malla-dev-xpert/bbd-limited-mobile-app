import 'package:flutter/material.dart';
import 'package:bbd_limited/logs/resolvers/log_details_resolver.dart';
import 'package:bbd_limited/logs/widgets/generic_update_diff_widget.dart';
import 'package:bbd_limited/logs/widgets/generic_delete_widget.dart';
import 'package:bbd_limited/logs/widgets/generic_entity_details_widget.dart';
import 'package:bbd_limited/logs/widgets/deposit_log_details_widget.dart';
import 'package:bbd_limited/logs/widgets/bulk_action_widget.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/enums/log_entity_type.dart';
import 'package:bbd_limited/core/enums/log_action.dart';

/// Widget intelligent qui décide automatiquement quel widget afficher
/// selon le type d'action et d'entité
class SmartLogDetailsWidget extends StatelessWidget {
  final LogDetailsResolution resolution;
  final AppLocalizations localizations;

  const SmartLogDetailsWidget({
    super.key,
    required this.resolution,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    // Pour BULK : afficher le widget d'action groupée
    if (resolution.action == LogAction.BULK || resolution.isBulkAction) {
      return BulkActionWidget(
        businessData: resolution.businessData,
        localizations: localizations,
        entityType: resolution.entityType,
        entityCount: resolution.entityCount,
      );
    }

    // Pour LOGIN : ne pas afficher de détails métier (juste l'action)
    if (resolution.action == LogAction.LOGIN) {
      return const SizedBox.shrink();
    }

    // Si pas de données métier, ne rien afficher
    if (resolution.businessData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Pour CREATE : afficher uniquement les données créées (pas de comparaison)
    if (resolution.action == LogAction.CREATE) {
      // Même si before/after existe, on n'affiche pas la comparaison pour CREATE
      return GenericEntityDetailsWidget(
        businessData: resolution.businessData,
        localizations: localizations,
      );
    }

    // Pour DELETE : afficher le widget de suppression
    if (resolution.isDelete) {
      return GenericDeleteWidget(
        businessData: resolution.businessData,
        localizations: localizations,
      );
    }

    // Pour UPDATE et VALIDATE avec before/after : afficher le widget de comparaison
    if (resolution.shouldShowBeforeAfter) {
      return GenericUpdateDiffWidget(
        businessData: resolution.businessData,
        localizations: localizations,
      );
    }

    // Pour les versements : utiliser le widget spécialisé
    if (resolution.entityType == LogEntityType.DEPOSIT) {
      return DepositLogDetailsWidget(
        businessData: resolution.businessData,
        localizations: localizations,
      );
    }

    return GenericEntityDetailsWidget(
      businessData: resolution.businessData,
      localizations: localizations,
    );
  }
}
