import 'package:flutter/material.dart';
import 'package:bbd_limited/logs/models/business_entity_data.dart';
import 'package:bbd_limited/logs/mappers/entity_details_mapper.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/utils/activity_log_translator.dart';
import 'package:intl/intl.dart';

/// Widget générique pour afficher les différences before/after
/// Utilisé pour les actions UPDATE
/// Design: Split view Avant/Après avec mise en évidence des changements
class GenericUpdateDiffWidget extends StatelessWidget {
  final BusinessEntityData businessData;
  final AppLocalizations localizations;

  const GenericUpdateDiffWidget({
    super.key,
    required this.businessData,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    if (!businessData.hasBothBeforeAfter) {
      // Si pas de before/after, afficher les données principales
      return _buildSimpleData(businessData.mainData);
    }

    final before = businessData.beforeData!;
    final after = businessData.afterData!;
    final differences = EntityDetailsMapper.computeDifferences(before, after);

    if (differences.isEmpty) {
      return _buildNoChangesMessage();
    }

    // Obtenir toutes les clés uniques pour l'affichage
    final allKeys = <String>{};
    allKeys.addAll(before.keys);
    allKeys.addAll(after.keys);

    // Filtrer les clés pour ne garder que celles pertinentes
    final displayKeys = allKeys.where((key) => !_shouldExcludeKey(key)).toList()
      ..sort((a, b) {
        // Prioriser les champs modifiés
        final aChanged = differences.containsKey(a);
        final bChanged = differences.containsKey(b);
        if (aChanged != bChanged) return aChanged ? -1 : 1;
        return a.compareTo(b);
      });

    // Utiliser LayoutBuilder pour détecter la largeur de l'écran
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          // Desktop/Tablet: Split view côte à côte
          return _buildSplitView(displayKeys, before, after, differences);
        } else {
          // Mobile: Vue empilée
          return _buildStackedView(displayKeys, before, after, differences);
        }
      },
    );
  }

  /// Split view: Avant et Après côte à côte (Desktop/Tablet)
  Widget _buildSplitView(
    List<String> keys,
    Map<String, dynamic> before,
    Map<String, dynamic> after,
    Map<String, Map<String, dynamic>> differences,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'AVANT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'APRÈS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenu split
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colonne AVANT
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border(
                      right: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: keys.map((key) {
                      final isChanged = differences.containsKey(key);
                      final value = before[key];
                      return _buildFieldRow(
                        key,
                        value,
                        isChanged: isChanged,
                        isBefore: true,
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Colonne APRÈS
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: keys.map((key) {
                      final isChanged = differences.containsKey(key);
                      final value = after[key];
                      return _buildFieldRow(
                        key,
                        value,
                        isChanged: isChanged,
                        isBefore: false,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Stacked view: Avant puis Après (Mobile)
  Widget _buildStackedView(
    List<String> keys,
    Map<String, dynamic> before,
    Map<String, dynamic> after,
    Map<String, Map<String, dynamic>> differences,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section AVANT
        _buildStackedSection(
          title: 'AVANT',
          keys: keys,
          data: before,
          differences: differences,
          color: Colors.red[50]!,
          borderColor: Colors.red[200]!,
        ),
        const SizedBox(height: 20),
        // Section APRÈS
        _buildStackedSection(
          title: 'APRÈS',
          keys: keys,
          data: after,
          differences: differences,
          color: Colors.green[50]!,
          borderColor: Colors.green[200]!,
        ),
      ],
    );
  }

  Widget _buildStackedSection({
    required String title,
    required List<String> keys,
    required Map<String, dynamic> data,
    required Map<String, Map<String, dynamic>> differences,
    required Color color,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: title == 'AVANT' ? Colors.red[700] : Colors.green[700],
            ),
          ),
          const SizedBox(height: 12),
          ...keys.map((key) {
            final isChanged = differences.containsKey(key);
            final value = data[key];
            return _buildFieldRow(
              key,
              value,
              isChanged: isChanged,
              isBefore: title == 'AVANT',
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFieldRow(
    String key,
    dynamic value, {
    required bool isChanged,
    required bool isBefore,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isChanged)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(
                child: Text(
                  _translateKey(key),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isChanged ? FontWeight.bold : FontWeight.w600,
                    color: isChanged ? Colors.orange[900] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isChanged
                  ? (isBefore ? Colors.red[100] : Colors.green[100])
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isChanged
                    ? (isBefore ? Colors.red[300]! : Colors.green[300]!)
                    : Colors.grey[300]!,
                width: isChanged ? 1.5 : 1,
              ),
            ),
            child: Text(
              _formatValue(key, value),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isChanged ? FontWeight.bold : FontWeight.w500,
                color: isChanged
                    ? (isBefore ? Colors.red[900] : Colors.green[900])
                    : Colors.black87,
                decoration:
                    isChanged && isBefore ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Vérifie si une clé doit être exclue (IDs uniquement)
  bool _shouldExcludeKey(String key) {
    final keyLower = key.toLowerCase();
    return keyLower == 'id' ||
        keyLower.endsWith('id') ||
        keyLower.endsWith('ids');
  }

  Widget _buildSimpleData(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: localizations.translate('details'),
      data: data,
      color: Colors.blue[50]!,
      borderColor: Colors.blue[200]!,
    );
  }

  Widget _buildNoChangesMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localizations.translate('no_changes_detected'),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Map<String, dynamic> data,
    required Color color,
    required Color borderColor,
  }) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
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

    // Traductions communes avec support des variantes
    final translations = {
      'name': localizations.translate('name'),
      'firstname': localizations.translate('first_name'),
      'first_name': localizations.translate('first_name'),
      'lastname': localizations.translate('last_name'),
      'last_name': localizations.translate('last_name'),
      'description': localizations.translate('description'),
      'status': localizations.translate('status'),
      'accounttype': localizations.translate('account_type'),
      'account_type': localizations.translate('account_type'),
      'balance': localizations.translate('balance'),
      'totaldebt': localizations.translate('total_debt'),
      'total_debt': localizations.translate('total_debt'),
      'phonenumber': localizations.translate('phone_number'),
      'phone_number': localizations.translate('phone_number'),
      'email': localizations.translate('email'),
      'adresse': localizations.translate('address'),
      'address': localizations.translate('address'),
      'country': localizations.translate('country'),
      'createdat': localizations.translate('created_at'),
      'created_at': localizations.translate('created_at'),
      'editedat': localizations.translate('edited_at'),
      'edited_at': localizations.translate('edited_at'),
      'updatedat': localizations.translate('updated_at'),
      'updated_at': localizations.translate('updated_at'),
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

    // Formater camelCase en texte lisible
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

    // Gérer les strings vides
    if (value is String && value.trim().isEmpty) {
      return localizations.translate('empty');
    }

    // Formater les dates
    if (key.toLowerCase().contains('date') ||
        key.toLowerCase().contains('at') ||
        key.toLowerCase() == 'createdat' ||
        key.toLowerCase() == 'created_at' ||
        key.toLowerCase() == 'editedat' ||
        key.toLowerCase() == 'edited_at' ||
        key.toLowerCase() == 'updatedat' ||
        key.toLowerCase() == 'updated_at') {
      if (value is String) {
        // Gérer les formats LocalDateTime sans timezone
        String dateStr = value;

        // Vérifier si c'est un format LocalDateTime sans timezone
        // Format attendu: "2026-01-05T14:04:53.986001" ou "2026-01-05 14:04:53"
        final hasZ = dateStr.contains('Z');
        final hasPlus = dateStr.contains('+');
        // Vérifier s'il y a un '-' après la position 10 (timezone offset)
        final hasTimezoneOffset =
            dateStr.length > 10 && dateStr.substring(10).contains('-');
        final hasTimezone = hasZ || hasPlus || hasTimezoneOffset;

        if (!hasTimezone) {
          // Normaliser le format (remplacer espace par T si nécessaire)
          dateStr = dateStr.replaceAll(' ', 'T');
          // Ajouter Z si pas de timezone (format LocalDateTime)
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

    // Formater les nombres/montants
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
