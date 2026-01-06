import 'package:flutter/material.dart';
import 'package:bbd_limited/logs/models/business_entity_data.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/utils/activity_log_translator.dart';
import 'package:bbd_limited/core/services/devises_service.dart';
import 'package:bbd_limited/models/devises.dart';
import 'package:intl/intl.dart';

/// Widget spécialisé pour afficher les détails d'une devise
/// Affiche : nom, code, rate
class CurrencyLogDetailsWidget extends StatefulWidget {
  final BusinessEntityData businessData;
  final AppLocalizations localizations;
  final String? entityLabel; // Label du log contenant le nom de la devise

  const CurrencyLogDetailsWidget({
    super.key,
    required this.businessData,
    required this.localizations,
    this.entityLabel,
  });

  @override
  State<CurrencyLogDetailsWidget> createState() =>
      _CurrencyLogDetailsWidgetState();
}

class _CurrencyLogDetailsWidgetState extends State<CurrencyLogDetailsWidget> {
  Devise? _devise;
  bool _isLoadingDevise = false;

  @override
  void initState() {
    super.initState();
    _loadDeviseIfNeeded();
  }

  /// Extrait le nom de la devise depuis les données
  /// Cherche dans "name", "Name", "deviseName", etc.
  /// Exclut "Devise" au début si présent
  String? _extractDeviseName(Map<String, dynamic>? data) {
    if (data == null) return null;

    // Chercher dans plusieurs clés possibles
    final deviseName = data['name']?.toString() ??
        data['Name']?.toString() ??
        data['deviseName']?.toString() ??
        data['devise_name']?.toString() ??
        data['currencyName']?.toString() ??
        data['currency']?.toString();

    if (deviseName == null || deviseName.isEmpty) return null;

    // Retirer "Devise" au début si présent (insensible à la casse)
    final cleaned = deviseName.trim();
    final lowerCleaned = cleaned.toLowerCase();
    if (lowerCleaned.startsWith('devise ')) {
      return cleaned.substring(7).trim();
    }

    return cleaned;
  }

  /// Extrait le nom de la devise depuis entityLabel
  String? _extractDeviseNameFromLabel(String? entityLabel) {
    if (entityLabel == null || entityLabel.isEmpty) return null;

    // Si entityLabel contient "Devise", extraire le nom après
    final lowerLabel = entityLabel.toLowerCase();
    if (lowerLabel.contains('devise')) {
      // Chercher le nom après "Devise"
      final parts =
          entityLabel.split(RegExp(r'devise\s+', caseSensitive: false));
      if (parts.length > 1) {
        return parts[1].trim();
      }
    }

    return null;
  }

  /// Charge la devise complète si on a un nom et que c'est une création
  Future<void> _loadDeviseIfNeeded() async {
    // Pour CREATE, on essaie de récupérer la devise complète
    final beforeData = widget.businessData.beforeData;
    final afterData = widget.businessData.afterData;

    // Si c'est une création (pas de beforeData) et qu'on a un nom de devise
    final isCreate = beforeData == null && afterData != null;

    // Essayer plusieurs sources pour trouver le nom de la devise
    String? deviseName = _extractDeviseName(afterData) ??
        _extractDeviseName(widget.businessData.mainData) ??
        _extractDeviseNameFromLabel(widget.entityLabel);

    if (isCreate && deviseName != null && deviseName.isNotEmpty) {
      setState(() {
        _isLoadingDevise = true;
      });

      try {
        final deviseService = DeviseServices();
        final devise = await deviseService.getByName(deviseName);
        if (mounted) {
          setState(() {
            _devise = devise;
            _isLoadingDevise = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingDevise = false;
          });
        }
      }
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    // Extraire les données pertinentes
    final data = widget.businessData.mainData;
    final beforeData = widget.businessData.beforeData;
    final afterData = widget.businessData.afterData;

    // Pour CREATE : afficher les données principales avec code et rate
    if (beforeData == null && afterData != null) {
      return _buildSimpleView(afterData);
    }

    // Pour UPDATE : afficher before/after
    if (beforeData != null && afterData != null) {
      return _buildUpdateView(beforeData, afterData);
    }

    // Pour DELETE : afficher before uniquement
    if (beforeData != null && afterData == null) {
      return _buildDeleteView(beforeData);
    }

    // Fallback
    return _buildSimpleView(data);
  }

  /// Affiche les données pour CREATE avec code et rate
  Widget _buildSimpleView(Map<String, dynamic> data) {
    final date = _extractDate(data);
    final name = _extractDeviseName(data) ?? _extractName(data);

    // Utiliser les données de la devise récupérée si disponible
    final code = _devise?.code ?? _extractCode(data);
    final rate = _devise?.rate ?? _extractRate(data);

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
          Text(
            widget.localizations.translate('details'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingDevise)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chargement des détails...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          if (date != null)
            _buildInfoRow(
              widget.localizations.translate('date'),
              _formatDate(date),
            ),
          if (name != null)
            _buildInfoRow(
              _translate('devise_name', 'Nom'),
              name,
            ),
          if (code != null)
            _buildInfoRow(
              _translate('devise_code', 'Code'),
              code,
            ),
          if (rate != null)
            _buildInfoRow(
              _translate('exchange_rate', 'Taux de change'),
              _formatRate(rate),
            ),
        ],
      ),
    );
  }

  /// Affiche les données pour UPDATE avec comparaison
  Widget _buildUpdateView(
    Map<String, dynamic> before,
    Map<String, dynamic> after,
  ) {
    // Pour UPDATE, on peut utiliser le widget générique ou créer une vue spécialisée
    return _buildSimpleView(after);
  }

  /// Affiche les données pour DELETE
  Widget _buildDeleteView(Map<String, dynamic> before) {
    return _buildSimpleView(before);
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

  /// Extrait la date depuis les données
  DateTime? _extractDate(Map<String, dynamic> data) {
    final dateValue = data['createdAt'] ?? data['created_at'] ?? data['date'];

    if (dateValue == null) return null;
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      final parsed = DateTime.tryParse(dateValue);
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// Extrait le nom depuis les données (sans traitement spécial)
  String? _extractName(Map<String, dynamic> data) {
    return data['name']?.toString() ?? data['Name']?.toString();
  }

  /// Extrait le code depuis les données
  String? _extractCode(Map<String, dynamic> data) {
    return data['code']?.toString() ??
        data['Code']?.toString() ??
        data['deviseCode']?.toString() ??
        data['currencyCode']?.toString();
  }

  /// Extrait le rate depuis les données
  double? _extractRate(Map<String, dynamic> data) {
    final rate = data['rate'] ??
        data['Rate'] ??
        data['exchangeRate'] ??
        data['tauxUtilise'];

    if (rate == null) return null;
    if (rate is num) return rate.toDouble();
    if (rate is String) return double.tryParse(rate);
    return null;
  }

  /// Formate une date
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return ActivityLogTranslator.formatDateTime(date);
  }

  /// Formate un taux de change
  String _formatRate(double? rate) {
    if (rate == null) return 'N/A';
    return NumberFormat('#,##0.00').format(rate);
  }

  /// Traduit une clé avec un fallback
  String _translate(String key, String fallback) {
    try {
      final translated = widget.localizations.translate(key);
      return translated.isNotEmpty ? translated : fallback;
    } catch (e) {
      return fallback;
    }
  }
}
