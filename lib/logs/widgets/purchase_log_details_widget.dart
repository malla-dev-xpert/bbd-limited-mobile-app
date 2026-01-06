import 'package:flutter/material.dart';
import 'package:bbd_limited/logs/models/business_entity_data.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/utils/activity_log_translator.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:intl/intl.dart';

/// Widget spécialisé pour afficher les détails d'un achat
/// Affiche : items achetés avec leur quantité et prix
class PurchaseLogDetailsWidget extends StatefulWidget {
  final BusinessEntityData businessData;
  final AppLocalizations localizations;
  final String? entityLabel; // Label du log contenant "Achat #A-1"

  const PurchaseLogDetailsWidget({
    super.key,
    required this.businessData,
    required this.localizations,
    this.entityLabel,
  });

  @override
  State<PurchaseLogDetailsWidget> createState() =>
      _PurchaseLogDetailsWidgetState();
}

class _PurchaseLogDetailsWidgetState extends State<PurchaseLogDetailsWidget> {
  Achat? _achat;
  bool _isLoadingAchat = false;

  @override
  void initState() {
    super.initState();
    _loadAchatIfNeeded();
  }

  /// Extrait l'ID de l'achat depuis entityLabel au format "Achat #A-1"
  /// Retourne uniquement l'ID (le chiffre après #A-)
  int? _extractAchatId(String? entityLabel) {
    if (entityLabel == null || entityLabel.isEmpty) return null;

    // Pattern pour extraire l'ID depuis "Achat #A-1" ou "#A-1" ou "A-1"
    // On cherche #A- suivi d'un nombre
    final regex = RegExp(r'#A-(\d+)');
    final match = regex.firstMatch(entityLabel);

    if (match != null && match.groupCount >= 1) {
      final idString = match.group(1);
      if (idString != null) {
        return int.tryParse(idString);
      }
    }

    return null;
  }

  /// Charge l'achat complet si on a un ID et que c'est une création
  Future<void> _loadAchatIfNeeded() async {
    // Pour CREATE, on essaie de récupérer l'achat complet
    final beforeData = widget.businessData.beforeData;
    final afterData = widget.businessData.afterData;

    // Si c'est une création (pas de beforeData) et qu'on a un ID
    final isCreate = beforeData == null && afterData != null;
    final achatId = _extractAchatId(widget.entityLabel);

    if (isCreate && achatId != null) {
      setState(() {
        _isLoadingAchat = true;
      });

      try {
        final achatService = AchatServices();
        final achat = await achatService.getById(achatId);
        if (mounted) {
          setState(() {
            _achat = achat;
            _isLoadingAchat = false;
          });
          // Debug: vérifier que les items sont bien récupérés
          if (achat != null) {
            print('✅ Achat récupéré: ${achat.id}');
            print('✅ Items count: ${achat.items?.length ?? 0}');
            if (achat.items != null && achat.items!.isNotEmpty) {
              print(
                  '✅ Premier item: ${achat.items!.first.description}, qty: ${achat.items!.first.quantity}, price: ${achat.items!.first.unitPrice}');
            }
          }
        }
      } catch (e) {
        print('❌ Erreur lors du chargement de l\'achat: $e');
        if (mounted) {
          setState(() {
            _isLoadingAchat = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extraire les données pertinentes
    final data = widget.businessData.mainData;
    final beforeData = widget.businessData.beforeData;
    final afterData = widget.businessData.afterData;

    // Pour CREATE : afficher les données principales avec les items
    if (beforeData == null && afterData != null) {
      return _buildSimpleView(afterData);
    }

    // Pour UPDATE : afficher before/after (on peut utiliser le widget générique)
    if (beforeData != null && afterData != null) {
      return _buildSimpleView(afterData);
    }

    // Pour DELETE : afficher before uniquement
    if (beforeData != null && afterData == null) {
      return _buildSimpleView(beforeData);
    }

    // Fallback
    return _buildSimpleView(data);
  }

  /// Affiche les données pour CREATE avec les items
  Widget _buildSimpleView(Map<String, dynamic> data) {
    final date = _extractDate(data);
    final clientName = _extractClientName(data);
    final montantTotal = _achat?.montantTotal ?? _extractAmount(data);

    // Utiliser les items de l'achat récupéré si disponible
    final items = _achat?.items ?? [];

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
          if (_isLoadingAchat)
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
          if (clientName != null)
            _buildInfoRow(
              widget.localizations.translate('client_name'),
              clientName,
            ),
          if (montantTotal != null)
            _buildInfoRow(
              widget.localizations.translate('total_amount'),
              _formatAmount(montantTotal),
            ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _translate('items', 'Articles'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _buildItemRow(item)),
          ],
        ],
      ),
    );
  }

  /// Affiche une ligne d'item avec description, quantité et prix
  Widget _buildItemRow(Items item) {
    final quantity = item.quantity ?? 0;
    final unitPrice = item.unitPrice ?? 0.0;
    final totalPrice = item.totalPrice ?? (quantity * unitPrice);
    final description = item.description ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_translate('quantity', 'Quantité')}: $quantity',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${_translate('unit_price', 'Prix unitaire')}: ${_formatAmount(unitPrice)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${_translate('total', 'Total')}: ${_formatAmount(totalPrice)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
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

  /// Extrait le nom du client depuis les données
  String? _extractClientName(Map<String, dynamic> data) {
    return data['client']?.toString() ??
        data['clientName']?.toString() ??
        data['partnerName']?.toString() ??
        data['customerName']?.toString();
  }

  /// Extrait le montant total depuis les données
  double? _extractAmount(Map<String, dynamic> data) {
    final amount = data['montantTotal'] ??
        data['montant_total'] ??
        data['totalAmount'] ??
        data['amount'];

    if (amount == null) return null;
    if (amount is num) return amount.toDouble();
    if (amount is String) return double.tryParse(amount);
    return null;
  }

  /// Formate un montant
  String _formatAmount(double? amount) {
    if (amount == null) return 'N/A';
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Formate une date
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return ActivityLogTranslator.formatDateTime(date);
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
