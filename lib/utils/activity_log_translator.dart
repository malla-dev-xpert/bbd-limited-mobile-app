import 'package:flutter/material.dart';
import 'package:bbd_limited/models/activity_log.dart';
import 'package:bbd_limited/core/enums/log_action.dart';
import 'package:bbd_limited/core/enums/log_entity_type.dart';
import 'package:intl/intl.dart';

class ActivityLogTranslator {
  /// Traduit un code d'action en phrase lisible en français
  /// Utilise les enums LogAction et LogEntityType pour une meilleure cohérence
  static String translateAction(ActivityLog log) {
    // Parser les enums depuis les strings
    final action = LogAction.fromString(log.actionCode);
    final entityType = LogEntityType.fromString(log.entityType);
    final isBulk = log.isBulkAction;
    final count = log.entityCount;

    // Cas spéciaux pour les paiements
    if (action == LogAction.PAYMENT) {
      if (entityType == LogEntityType.SUPPLIER) {
        if (isBulk) {
          return 'a payé $count fournisseurs';
        } else {
          return 'a payé un fournisseur';
        }
      } else if (entityType == LogEntityType.CUSTOMER) {
        if (isBulk) {
          return 'a reçu un paiement de $count clients';
        } else {
          return 'a reçu un paiement d\'un client';
        }
      } else if (entityType == LogEntityType.PAYMENT) {
        if (isBulk) {
          return 'a effectué $count paiements';
        } else {
          return 'a effectué un paiement';
        }
      } else {
        // Paiement pour une autre entité
        final entityName =
            isBulk ? entityType.displayNamePlural : entityType.displayName;
        if (isBulk) {
          return 'a effectué un paiement pour $count $entityName';
        } else {
          return 'a effectué un paiement pour $entityName';
        }
      }
    }

    // Déterminer le verbe d'action
    String actionVerb;
    switch (action) {
      case LogAction.CREATE:
        actionVerb = 'a créé';
        break;
      case LogAction.UPDATE:
        actionVerb = 'a modifié';
        break;
      case LogAction.DELETE:
        actionVerb = 'a supprimé';
        break;
      case LogAction.VALIDATE:
        actionVerb = 'a validé';
        break;
      case LogAction.CANCEL:
        actionVerb = 'a annulé';
        break;
      case LogAction.DELIVERY:
        actionVerb = 'a livré';
        break;
      case LogAction.PAYMENT:
        // Ce cas est déjà géré dans le if précédent, mais nécessaire pour l'exhaustivité
        actionVerb = 'a effectué un paiement pour';
        break;
      case LogAction.EMBARKATION:
        actionVerb = 'a embarqué';
        break;
      case LogAction.WITHDRAWAL:
        actionVerb = 'a retiré';
        break;
      case LogAction.DEPOSIT:
        actionVerb = 'a effectué un versement pour';
        break;
      case LogAction.CONVERSION:
        actionVerb = 'a converti';
        break;
      case LogAction.BULK:
        actionVerb = 'a effectué une action groupée sur';
        break;
      case LogAction.LOGIN:
        actionVerb = 's\'est connecté';
        break;
      case LogAction.UNKNOWN:
        actionVerb = 'a effectué une action sur';
        break;
    }

    // Construire la phrase
    final entityName =
        isBulk ? entityType.displayNamePlural : entityType.displayName;

    if (isBulk) {
      return '$actionVerb $count $entityName';
    } else {
      return '$actionVerb $entityName';
    }
  }

  /// Traduit le type d'entité en français
  /// Utilise l'enum LogEntityType pour une meilleure cohérence
  static String translateEntityType(String entityType) {
    final type = LogEntityType.fromString(entityType);
    return type.displayName;
  }

  /// Formate la date et l'heure en français
  static String formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');
    return '${dateFormat.format(dateTime)} à ${timeFormat.format(dateTime)}';
  }

  /// Retourne la couleur selon le type d'action
  /// Utilise l'enum LogAction pour une meilleure cohérence
  static Color getActionColor(String actionCode) {
    final action = LogAction.fromString(actionCode);
    switch (action) {
      case LogAction.CREATE:
        return Colors.green;
      case LogAction.UPDATE:
        return Colors.blue;
      case LogAction.DELETE:
        return Colors.red;
      case LogAction.VALIDATE:
        return Colors.teal;
      case LogAction.CANCEL:
        return Colors.orange;
      case LogAction.DELIVERY:
        return Colors.purple;
      case LogAction.PAYMENT:
      case LogAction.DEPOSIT:
      case LogAction.WITHDRAWAL:
        return Colors.indigo;
      case LogAction.EMBARKATION:
        return Colors.cyan;
      case LogAction.CONVERSION:
        return Colors.amber;
      case LogAction.BULK:
        return Colors.deepPurple;
      case LogAction.LOGIN:
        return Colors.blueGrey;
      case LogAction.UNKNOWN:
        return Colors.grey;
    }
  }

  /// Retourne l'icône selon le type d'action
  /// Utilise l'enum LogAction pour une meilleure cohérence
  static IconData getActionIcon(String actionCode) {
    final action = LogAction.fromString(actionCode);
    switch (action) {
      case LogAction.CREATE:
        return Icons.add_circle_outline;
      case LogAction.UPDATE:
        return Icons.edit_outlined;
      case LogAction.DELETE:
        return Icons.delete_outline;
      case LogAction.VALIDATE:
        return Icons.check_circle_outline;
      case LogAction.CANCEL:
        return Icons.cancel_outlined;
      case LogAction.DELIVERY:
        return Icons.local_shipping_outlined;
      case LogAction.PAYMENT:
        return Icons.payment_outlined;
      case LogAction.EMBARKATION:
        return Icons.flight_takeoff_outlined;
      case LogAction.WITHDRAWAL:
        return Icons.remove_circle_outline;
      case LogAction.DEPOSIT:
        return Icons.account_balance_wallet_outlined;
      case LogAction.CONVERSION:
        return Icons.swap_horiz_outlined;
      case LogAction.BULK:
        return Icons.layers_outlined;
      case LogAction.LOGIN:
        return Icons.login;
      case LogAction.UNKNOWN:
        return Icons.history;
    }
  }
}
