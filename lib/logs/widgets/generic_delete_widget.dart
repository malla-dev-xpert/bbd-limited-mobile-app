import 'package:flutter/material.dart';
import 'package:bbd_limited/logs/models/business_entity_data.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/utils/activity_log_translator.dart';
import 'package:intl/intl.dart';

/// Widget pour afficher les données avant suppression
/// Utilisé pour les actions DELETE
class GenericDeleteWidget extends StatelessWidget {
  final BusinessEntityData businessData;
  final AppLocalizations localizations;

  const GenericDeleteWidget({
    super.key,
    required this.businessData,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final data = businessData.beforeData ?? businessData.mainData;

    if (data.isEmpty) {
      return _buildEmptyState();
    }

    // Filtrer les données pour l'affichage
    final filteredData = _filterAndSortForDisplay(data);

    if (filteredData.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Message d'avertissement
        _buildWarningBanner(),
        const SizedBox(height: 20),
        // Données avant suppression
        _buildDataSection(filteredData),
      ],
    );
  }

  /// Filtre et trie les données pour l'affichage
  Map<String, dynamic> _filterAndSortForDisplay(Map<String, dynamic> data) {
    final filtered = <String, dynamic>{};

    // Ordre de priorité pour l'affichage
    final priorityOrder = [
      'firstName',
      'lastName',
      'name',
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

    // Ensuite ajouter les autres champs (limité à 10 pour éviter la surcharge)
    final otherKeys = data.keys
        .where((key) =>
            !priorityOrder.contains(key) &&
            !_shouldExcludeKey(key) &&
            !filtered.containsKey(key))
        .take(10)
        .toList()
      ..sort();

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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localizations.translate('no_data_available'),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50]!,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delete_outline, color: Colors.red[700], size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.translate('element_deleted'),
                  style: TextStyle(
                    color: Colors.red[900],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'L\'entité suivante a été supprimée :',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...data.entries.map((entry) => _buildInfoRow(
                _translateKey(entry.key),
                _formatValue(entry.key, entry.value),
              )),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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
      'description': localizations.translate('description'),
      'status': localizations.translate('status'),
      'amount': localizations.translate('amount'),
      'montant': localizations.translate('amount'),
      'reference': localizations.translate('reference'),
      'date': localizations.translate('date'),
      'quantity': localizations.translate('quantity'),
      'price': localizations.translate('price'),
      'total': localizations.translate('total'),
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

    if (key.toLowerCase().contains('date') ||
        key.toLowerCase().contains('at')) {
      if (value is String) {
        final date = DateTime.tryParse(value);
        if (date != null) {
          return ActivityLogTranslator.formatDateTime(date);
        }
      }
    }

    if (value is num) {
      if (key.toLowerCase().contains('price') ||
          key.toLowerCase().contains('amount') ||
          key.toLowerCase().contains('montant') ||
          key.toLowerCase().contains('rate')) {
        return NumberFormat.currency(symbol: '', decimalDigits: 2)
            .format(value);
      }
      return value.toString();
    }

    return value.toString();
  }
}
