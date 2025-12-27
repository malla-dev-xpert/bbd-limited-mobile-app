import 'package:flutter/material.dart';
import 'package:bbd_limited/models/activity_log.dart';
import 'package:intl/intl.dart';

class ActivityLogTranslator {
  /// Traduit un code d'action en phrase lisible en français
  static String translateAction(ActivityLog log) {
    final actionCode = log.actionCode.toUpperCase();
    final entityTypeUpper = log.entityType.toUpperCase();
    final isBulk = log.isBulkAction;
    final count = log.entityCount;

    // Cas spéciaux pour éviter les redondances
    if (actionCode.contains('PAIEMENT_FOURNISSEUR') ||
        actionCode.contains('PAYMENT_SUPPLIER')) {
      if (isBulk) {
        return 'a payé $count fournisseurs';
      } else {
        return 'a payé un fournisseur';
      }
    }

    if (actionCode.contains('PAIEMENT_CLIENT') ||
        actionCode.contains('PAYMENT_CUSTOMER')) {
      if (isBulk) {
        return 'a reçu un paiement de $count clients';
      } else {
        return 'a reçu un paiement d\'un client';
      }
    }

    // Cas général pour les paiements
    if (actionCode.contains('PAIEMENT') || actionCode.contains('PAYMENT')) {
      // Si l'entité est déjà un paiement, simplifier
      if (entityTypeUpper.contains('PAYMENT') ||
          entityTypeUpper.contains('PAIEMENT')) {
        if (isBulk) {
          return 'a effectué $count paiements';
        } else {
          return 'a effectué un paiement';
        }
      }
      // Sinon, utiliser le type d'entité
      final entityType = _translateEntityType(log.entityType);
      if (isBulk) {
        return 'a effectué un paiement pour $count $entityType';
      } else {
        return 'a effectué un paiement pour $entityType';
      }
    }

    // Déterminer le verbe d'action pour les autres cas
    String actionVerb;
    if (actionCode.contains('CREATION') ||
        actionCode.contains('CREATE') ||
        actionCode.contains('NEW_')) {
      actionVerb = 'a créé';
    } else if (actionCode.contains('MODIFICATION') ||
        actionCode.contains('UPDATE') ||
        actionCode.contains('EDIT')) {
      actionVerb = 'a modifié';
    } else if (actionCode.contains('SUPPRESSION') ||
        actionCode.contains('DELETE') ||
        actionCode.contains('REMOVE')) {
      actionVerb = 'a supprimé';
    } else if (actionCode.contains('LIVRAISON') ||
        actionCode.contains('DELIVERY')) {
      actionVerb = 'a livré';
    } else if (actionCode.contains('VALIDATION') ||
        actionCode.contains('VALIDATE')) {
      actionVerb = 'a validé';
    } else if (actionCode.contains('ANNULATION') ||
        actionCode.contains('CANCEL')) {
      actionVerb = 'a annulé';
    } else {
      actionVerb = 'a effectué une action sur';
    }

    // Construire la phrase
    final entityType = _translateEntityType(log.entityType);

    // Éviter les redondances : si l'action contient déjà le type d'entité
    // Ex: "NEW_VERSEMENT" + "Versement" → "a créé un versement" (pas de redondance)
    // Mais si l'action est générique et l'entité aussi, simplifier
    if (isBulk) {
      return '$actionVerb $count $entityType';
    } else {
      return '$actionVerb $entityType';
    }
  }

  /// Traduit le type d'entité en français
  static String _translateEntityType(String entityType) {
    final type = entityType.toUpperCase();

    switch (type) {
      case 'CATEGORIE':
      case 'CATEGORY':
        return 'une catégorie';
      case 'ARTICLE':
      case 'ITEM':
      case 'ITEMS':
        return 'un article';
      case 'PORT':
      case 'HARBOR':
        return 'un port';
      case 'COLIS':
      case 'PACKAGE':
        return 'un colis';
      case 'UTILISATEUR':
      case 'USER':
        return 'un utilisateur';
      case 'PARTENAIRE':
      case 'PARTNER':
        return 'un partenaire';
      case 'FOURNISSEUR':
      case 'SUPPLIER':
        return 'un fournisseur';
      case 'CLIENT':
      case 'CUSTOMER':
        return 'un client';
      case 'CONTENEUR':
      case 'CONTAINER':
        return 'un conteneur';
      case 'ENTREPOT':
      case 'WAREHOUSE':
        return 'un entrepôt';
      case 'DEVISE':
      case 'CURRENCY':
        return 'une devise';
      case 'PAIEMENT':
      case 'PAYMENT':
      case 'PAYMENTS':
        return 'un paiement';
      case 'VERSEMENT':
      case 'DEPOSIT':
        return 'un versement';
      case 'ACHAT':
      case 'PURCHASE':
        return 'un achat';
      default:
        return 'une entité';
    }
  }

  /// Formate la date et l'heure en français
  static String formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');
    return '${dateFormat.format(dateTime)} à ${timeFormat.format(dateTime)}';
  }

  /// Retourne la couleur selon le type d'action
  static Color getActionColor(String actionCode) {
    final code = actionCode.toUpperCase();

    if (code.contains('CREATION') || code.contains('CREATE')) {
      return Colors.green;
    } else if (code.contains('MODIFICATION') ||
        code.contains('UPDATE') ||
        code.contains('EDIT')) {
      return Colors.blue;
    } else if (code.contains('SUPPRESSION') ||
        code.contains('DELETE') ||
        code.contains('REMOVE')) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  /// Retourne l'icône selon le type d'action
  static IconData getActionIcon(String actionCode) {
    final code = actionCode.toUpperCase();

    if (code.contains('CREATION') || code.contains('CREATE')) {
      return Icons.add_circle_outline;
    } else if (code.contains('MODIFICATION') ||
        code.contains('UPDATE') ||
        code.contains('EDIT')) {
      return Icons.edit_outlined;
    } else if (code.contains('SUPPRESSION') ||
        code.contains('DELETE') ||
        code.contains('REMOVE')) {
      return Icons.delete_outline;
    } else if (code.contains('LIVRAISON') || code.contains('DELIVERY')) {
      return Icons.local_shipping_outlined;
    } else if (code.contains('PAIEMENT') || code.contains('PAYMENT')) {
      return Icons.payment_outlined;
    } else {
      return Icons.history;
    }
  }
}
