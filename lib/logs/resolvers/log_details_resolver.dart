import 'package:bbd_limited/models/log_detail.dart';
import 'package:bbd_limited/core/enums/log_action.dart';
import 'package:bbd_limited/core/enums/log_entity_type.dart';
import 'package:bbd_limited/logs/mappers/entity_details_mapper.dart';
import 'package:bbd_limited/logs/models/business_entity_data.dart';

/// Résultat du resolver indiquant quel widget afficher
class LogDetailsResolution {
  final LogAction action;
  final LogEntityType entityType;
  final BusinessEntityData businessData;
  final bool isBulkAction;
  final int entityCount;

  LogDetailsResolution({
    required this.action,
    required this.entityType,
    required this.businessData,
    required this.isBulkAction,
    required this.entityCount,
  });

  /// Retourne true si un widget spécialisé existe pour ce type d'entité
  bool get hasSpecializedWidget {
    switch (entityType) {
      case LogEntityType.PURCHASE:
      case LogEntityType.DEPOSIT:
      case LogEntityType.PAYMENT:
        return true;
      default:
        return false;
    }
  }

  /// Retourne true si l'affichage before/after est nécessaire
  bool get shouldShowBeforeAfter {
    return action.requiresBeforeAfter && businessData.hasBeforeAfter;
  }

  /// Retourne true si c'est une suppression
  bool get isDelete => action.isDelete;

  /// Retourne true si c'est une modification
  bool get isUpdate => action.isUpdate;
}

/// Resolver principal qui analyse un LogDetail et détermine
/// comment l'afficher de manière métier
class LogDetailsResolver {
  /// Résout un LogDetail et retourne les informations nécessaires pour l'affichage
  static LogDetailsResolution resolve(LogDetail logDetail) {
    // Parser les enums depuis les strings
    final action = LogAction.fromString(logDetail.action);
    final entityType = LogEntityType.fromString(logDetail.entityType);

    // Extraire les données métier
    final businessData = _extractBusinessData(logDetail, action);

    // Déterminer si c'est une action groupée
    // Soit l'action est BULK, soit il y a plusieurs entityIds
    final isBulkAction = action == LogAction.BULK ||
        (logDetail.entityIds != null && logDetail.entityIds!.length > 1);
    final entityCount = isBulkAction
        ? (logDetail.entityIds != null && logDetail.entityIds!.isNotEmpty
            ? logDetail.entityIds!.length
            : (action == LogAction.BULK ? 0 : 1))
        : (logDetail.entityId != null ? 1 : 0);

    return LogDetailsResolution(
      action: action,
      entityType: entityType,
      businessData: businessData,
      isBulkAction: isBulkAction,
      entityCount: entityCount,
    );
  }

  /// Extrait les données métier depuis entityDetails selon l'action
  /// Priorité : initialState/finalState (nouveau format) > before/after dans entityDetails (ancien format)
  static BusinessEntityData _extractBusinessData(
    LogDetail logDetail,
    LogAction action,
  ) {
    // PRIORITÉ 1 : Utiliser initialState/finalState si disponibles (nouveau format backend)
    if (logDetail.initialState != null || logDetail.finalState != null) {
      final before = logDetail.initialState != null
          ? EntityDetailsMapper.extractBeforeFromInitialState(
              logDetail.initialState)
          : null;
      final after = logDetail.finalState != null
          ? EntityDetailsMapper.extractAfterFromFinalState(logDetail.finalState)
          : null;

      // Pour UPDATE : besoin de before et after
      if (action.isUpdate) {
        return BusinessEntityData(
          data: after ?? before ?? {},
          beforeData: before,
          afterData: after,
        );
      }

      // Pour DELETE : besoin de before uniquement
      if (action.isDelete) {
        return BusinessEntityData(
          data: before ?? {},
          beforeData: before,
        );
      }

      // Pour CREATE : besoin de after uniquement
      if (action == LogAction.CREATE) {
        return BusinessEntityData(
          data: after ?? {},
          afterData: after,
        );
      }

      // Pour autres actions : utiliser les données disponibles
      return BusinessEntityData(
        data: after ?? before ?? {},
        beforeData: before,
        afterData: after,
      );
    }

    // PRIORITÉ 2 : Utiliser entityDetails (ancien format ou fallback)
    final entityDetails = logDetail.entityDetails;

    // Si pas de entityDetails, retourner des données vides
    if (entityDetails == null || entityDetails.isEmpty) {
      return BusinessEntityData(data: {});
    }

    // Pour UPDATE : extraire before et after depuis entityDetails
    if (action.isUpdate) {
      final before = EntityDetailsMapper.extractBeforeData(entityDetails);
      final after = EntityDetailsMapper.extractAfterData(entityDetails);

      // Si pas de before/after explicites, utiliser entityDetails comme after
      // et supposer que c'est l'état final
      if (before == null && after == null) {
        final mainData = EntityDetailsMapper.extractMainData(entityDetails);
        return BusinessEntityData(
          data: mainData,
          afterData: mainData,
        );
      }

      return BusinessEntityData(
        data: after ?? {},
        beforeData: before,
        afterData: after,
      );
    }

    // Pour DELETE : extraire before uniquement
    if (action.isDelete) {
      final before = EntityDetailsMapper.extractBeforeData(entityDetails);

      // Si pas de before explicite, utiliser entityDetails comme before
      if (before == null) {
        final mainData = EntityDetailsMapper.extractMainData(entityDetails);
        return BusinessEntityData(
          data: mainData,
          beforeData: mainData,
        );
      }

      return BusinessEntityData(
        data: before,
        beforeData: before,
      );
    }

    // Pour CREATE et autres actions : extraire les données principales
    final mainData = EntityDetailsMapper.extractMainData(entityDetails);
    return BusinessEntityData(
      data: mainData,
      afterData: mainData, // Pour CREATE, after = données créées
    );
  }

  /// Génère une phrase métier lisible pour un log
  static String generateBusinessPhrase(LogDetailsResolution resolution) {
    final action = resolution.action;
    final entityType = resolution.entityType;
    final isBulk = resolution.isBulkAction;
    final count = resolution.entityCount;

    String verb;
    switch (action) {
      case LogAction.CREATE:
        verb = 'a créé';
        break;
      case LogAction.UPDATE:
        verb = 'a modifié';
        break;
      case LogAction.DELETE:
        verb = 'a supprimé';
        break;
      case LogAction.VALIDATE:
        verb = 'a validé';
        break;
      case LogAction.CANCEL:
        verb = 'a annulé';
        break;
      case LogAction.DELIVERY:
        verb = 'a livré';
        break;
      case LogAction.PAYMENT:
        verb = 'a effectué un paiement pour';
        break;
      case LogAction.EMBARKATION:
        verb = 'a embarqué';
        break;
      case LogAction.WITHDRAWAL:
        verb = 'a retiré';
        break;
      case LogAction.DEPOSIT:
        verb = 'a effectué un versement pour';
        break;
      case LogAction.CONVERSION:
        verb = 'a converti';
        break;
      case LogAction.BULK:
        verb = 'a effectué une action groupée sur';
        break;
      case LogAction.LOGIN:
        verb = 's\'est connecté';
        break;
      case LogAction.UNKNOWN:
        verb = 'a effectué une action sur';
        break;
    }

    final entityName =
        isBulk ? entityType.displayNamePlural : entityType.displayName;

    if (isBulk) {
      return '$verb $count $entityName';
    } else {
      return '$verb $entityName';
    }
  }
}
