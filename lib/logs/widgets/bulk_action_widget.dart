import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/logs/models/business_entity_data.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/enums/log_entity_type.dart';

/// Widget pour afficher les actions groupées (BULK)
/// Affiche un résumé global sans détails unitaires si non fournis
class BulkActionWidget extends StatelessWidget {
  final BusinessEntityData businessData;
  final AppLocalizations localizations;
  final LogEntityType entityType;
  final int entityCount;

  const BulkActionWidget({
    super.key,
    required this.businessData,
    required this.localizations,
    required this.entityType,
    required this.entityCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Résumé global
        _buildSummaryCard(context),
        const SizedBox(height: 24),
        // Détails si disponibles
        if (!businessData.isEmpty) _buildDetailsSection(context),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepPurple[50]!,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple[200]!, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.layers_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.translate('bulk_action'),
                  style: AppTextSize.titleStyle(context,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple[900],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  localizations.translate('entities_affected').replaceAll(
                        '{count}',
                        entityCount.toString(),
                      ),
                  style: AppTextSize.bodyStyle(context,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    final data = businessData.mainData;

    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

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
          Text(
            localizations.translate('summary'),
            style: AppTextSize.titleStyle(context,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          ...data.entries.map((entry) => _buildInfoRow(
                context,
                _translateKey(entry.key),
                _formatValue(entry.key, entry.value),
              )),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextSize.bodyStyle(context,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextSize.bodyStyle(context,
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
      'count': localizations.translate('count'),
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

    if (value is num) {
      if (key.toLowerCase().contains('price') ||
          key.toLowerCase().contains('amount') ||
          key.toLowerCase().contains('montant') ||
          key.toLowerCase().contains('rate')) {
        return value.toStringAsFixed(2);
      }
      return value.toString();
    }

    return value.toString();
  }
}
