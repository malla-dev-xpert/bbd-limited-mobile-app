import 'package:flutter/material.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/logs/models/business_entity_data.dart';
import 'package:bbd_limited/utils/activity_log_translator.dart';
import 'package:intl/intl.dart';

/// Card de résumé métier pour les logs
/// Affiche un résumé lisible des informations principales de l'entité
class LogSummaryCard extends StatelessWidget {
  final BusinessEntityData businessData;
  final AppLocalizations localizations;

  const LogSummaryCard({
    super.key,
    required this.businessData,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    // Utiliser les données principales (mainData) pour le résumé
    final summaryData = businessData.mainData;

    if (summaryData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filtrer et trier les données pour le résumé
    final filteredData = _filterAndSortForSummary(summaryData);

    if (filteredData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50]!,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                localizations.translate('summary'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...filteredData.entries.map((entry) => _buildSummaryRow(
                _translateKey(entry.key),
                _formatValue(entry.key, entry.value),
              )),
        ],
      ),
    );
  }

  /// Filtre et trie les données pour le résumé (priorité aux champs importants)
  Map<String, dynamic> _filterAndSortForSummary(Map<String, dynamic> data) {
    final filtered = <String, dynamic>{};

    // Ordre de priorité pour le résumé
    final priorityOrder = [
      'firstName',
      'lastName',
      'name',
      'clientName',
      'customerName',
      'supplierName',
      'reference',
      'status',
      'accountType',
      'balance',
      'totalDebt',
      'amount',
      'montant',
      'email',
      'phoneNumber',
      'phone',
      'adresse',
      'address',
      'country',
    ];

    // D'abord ajouter les champs prioritaires
    for (final key in priorityOrder) {
      if (data.containsKey(key) && !_shouldExcludeKey(key)) {
        final value = data[key];
        if (value != null &&
            !(value is String && value.toString().trim().isEmpty)) {
          filtered[key] = value;
        }
      }
    }

    // Ensuite ajouter les autres champs (limité à 5 pour le résumé)
    final otherKeys = data.keys
        .where((key) =>
            !priorityOrder.contains(key) &&
            !_shouldExcludeKey(key) &&
            !filtered.containsKey(key))
        .take(5)
        .toList();

    for (final key in otherKeys) {
      final value = data[key];
      if (value != null &&
          !(value is String && value.toString().trim().isEmpty)) {
        filtered[key] = value;
      }
    }

    return filtered;
  }

  bool _shouldExcludeKey(String key) {
    final keyLower = key.toLowerCase();
    return keyLower == 'id' ||
        keyLower.endsWith('id') ||
        keyLower.endsWith('ids') ||
        keyLower.contains('created') ||
        keyLower.contains('updated') ||
        keyLower.contains('edited');
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _translateKey(String key) {
    final keyLower = key.toLowerCase();

    final translations = {
      'name': localizations.translate('name'),
      'firstname': localizations.translate('first_name'),
      'first_name': localizations.translate('first_name'),
      'lastname': localizations.translate('last_name'),
      'last_name': localizations.translate('last_name'),
      'clientname': 'Client',
      'client_name': 'Client',
      'customername': 'Client',
      'customer_name': 'Client',
      'suppliername': 'Fournisseur',
      'supplier_name': 'Fournisseur',
      'description': localizations.translate('description'),
      'status': localizations.translate('status'),
      'accounttype': localizations.translate('account_type'),
      'account_type': localizations.translate('account_type'),
      'balance': localizations.translate('balance'),
      'totaldebt': localizations.translate('total_debt'),
      'total_debt': localizations.translate('total_debt'),
      'phonenumber': localizations.translate('phone_number'),
      'phone_number': localizations.translate('phone_number'),
      'phone': localizations.translate('phone'),
      'email': localizations.translate('email'),
      'adresse': localizations.translate('address'),
      'address': localizations.translate('address'),
      'country': localizations.translate('country'),
      'amount': localizations.translate('amount'),
      'montant': localizations.translate('amount'),
      'reference': localizations.translate('reference'),
    };

    if (translations.containsKey(keyLower)) {
      return translations[keyLower]!;
    }

    return _formatKeyToReadable(key);
  }

  String _formatKeyToReadable(String key) {
    String result = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)!.toLowerCase()}',
    );
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }
    return result.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _formatValue(String key, dynamic value) {
    if (value == null) {
      return localizations.translate('na');
    }

    if (value is String && value.trim().isEmpty) {
      return localizations.translate('empty');
    }

    // Formater les dates
    if (key.toLowerCase().contains('date') ||
        key.toLowerCase().contains('at')) {
      if (value is String) {
        String dateStr = value;
        final hasZ = dateStr.contains('Z');
        final hasPlus = dateStr.contains('+');
        final hasTimezoneOffset =
            dateStr.length > 10 && dateStr.substring(10).contains('-');
        final hasTimezone = hasZ || hasPlus || hasTimezoneOffset;

        if (!hasTimezone) {
          dateStr = dateStr.replaceAll(' ', 'T');
          if (!dateStr.contains('Z') && !dateStr.contains('+')) {
            dateStr = '${dateStr}Z';
          }
        }

        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          return ActivityLogTranslator.formatDateTime(date);
        }
      }
      if (value is DateTime) {
        return ActivityLogTranslator.formatDateTime(value);
      }
    }

    // Formater les montants
    if (value is num) {
      if (key.toLowerCase().contains('price') ||
          key.toLowerCase().contains('amount') ||
          key.toLowerCase().contains('montant') ||
          key.toLowerCase().contains('balance') ||
          key.toLowerCase().contains('debt') ||
          key.toLowerCase().contains('rate')) {
        return NumberFormat.currency(symbol: '', decimalDigits: 2)
            .format(value);
      }
      return value.toString();
    }

    // Formater les booléens
    if (value is bool) {
      return value
          ? localizations.translate('yes')
          : localizations.translate('no');
    }

    return value.toString();
  }
}
