import 'package:flutter/material.dart';
import 'package:bbd_limited/logs/models/business_entity_data.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/utils/activity_log_translator.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:intl/intl.dart';

/// Widget spécialisé pour afficher les détails d'un versement
/// Affiche : date, commissionnaire (nom et téléphone), client, devise, taux utilisé, note
class DepositLogDetailsWidget extends StatefulWidget {
  final BusinessEntityData businessData;
  final AppLocalizations localizations;
  final String? reference; // Référence du versement depuis entityLabel du log

  const DepositLogDetailsWidget({
    super.key,
    required this.businessData,
    required this.localizations,
    this.reference,
  });

  @override
  State<DepositLogDetailsWidget> createState() =>
      _DepositLogDetailsWidgetState();
}

class _DepositLogDetailsWidgetState extends State<DepositLogDetailsWidget> {
  Versement? _versement;
  bool _isLoadingVersement = false;

  @override
  void initState() {
    super.initState();
    _loadVersementIfNeeded();
  }

  /// Extrait uniquement la référence au format BBDPAY-XX depuis entityLabel
  /// Ignore tout ce qui suit après la référence
  String? _extractReference(String? entityLabel) {
    if (entityLabel == null || entityLabel.isEmpty) return null;

    // Pattern pour extraire BBDPAY-XX (où XX est un nombre)
    final regex = RegExp(r'BBDPAY-\d+');
    final match = regex.firstMatch(entityLabel);

    if (match != null) {
      return match.group(0);
    }

    return null;
  }

  /// Charge le versement complet si on a une référence et que c'est une création
  Future<void> _loadVersementIfNeeded() async {
    // Pour CREATE, on essaie de récupérer le versement complet
    final beforeData = widget.businessData.beforeData;
    final afterData = widget.businessData.afterData;

    // Si c'est une création (pas de beforeData) et qu'on a une référence
    final isCreate = beforeData == null && afterData != null;
    final reference = _extractReference(widget.reference);

    if (isCreate && reference != null && reference.isNotEmpty) {
      setState(() {
        _isLoadingVersement = true;
      });

      try {
        final versementService = VersementServices();
        final versement = await versementService.getByReference(reference);
        if (mounted) {
          setState(() {
            _versement = versement;
            _isLoadingVersement = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingVersement = false;
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

    // Détecter si c'est un transfert (présence de oldPartnerId et newPartnerId)
    final isTransfer =
        _isTransfer(data) || _isTransfer(beforeData) || _isTransfer(afterData);

    if (isTransfer) {
      // Afficher la vue spéciale pour les transferts
      return _buildTransferView(data, beforeData, afterData);
    }

    // Pour CREATE : afficher les données principales
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

  /// Affiche les données pour CREATE
  Widget _buildSimpleView(Map<String, dynamic> data) {
    // Utiliser les données du versement récupéré si disponible, sinon utiliser les données du log
    final date = _extractDate(data);
    final montantVerser = _versement?.montantVerser ?? _extractAmount(data);
    final commissionnaireName =
        _versement?.commissionnaireName ?? _extractCommissionnaireName(data);
    final commissionnairePhone =
        _versement?.commissionnairePhone ?? _extractCommissionnairePhone(data);
    final clientName = _extractClientName(data);
    final deviseCode = _versement?.deviseCode ?? _extractDeviseCode(data);
    final tauxUtilise = _extractTauxUtilise(data);
    final note = _extractNote(data);

    // Vérifier s'il y a au moins une donnée à afficher
    if (date == null &&
        montantVerser == null &&
        commissionnaireName == null &&
        commissionnairePhone == null &&
        clientName == null &&
        deviseCode == null &&
        tauxUtilise == null &&
        note == null) {
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
          Text(
            widget.localizations.translate('details'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingVersement)
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
          if (montantVerser != null)
            _buildInfoRow(
              widget.localizations.translate('amount_deposited'),
              montantVerser.toString(),
            ),
          if (deviseCode != null)
            _buildInfoRow(
              widget.localizations.translate('currency'),
              deviseCode,
            ),
          if (commissionnaireName != null && commissionnaireName.isNotEmpty)
            _buildInfoRow(
              widget.localizations.translate('commissionnaire_name'),
              commissionnaireName,
            ),
          if (commissionnairePhone != null && commissionnairePhone.isNotEmpty)
            _buildInfoRow(
              widget.localizations.translate('commissionnaire_phone'),
              commissionnairePhone,
            ),
          if (clientName != null)
            _buildInfoRow(
              widget.localizations.translate('client_name'),
              clientName,
            ),
          if (tauxUtilise != null)
            _buildInfoRow(
              widget.localizations.translate('exchange_rate'),
              _formatRate(tauxUtilise),
            ),
          if (note != null && note.isNotEmpty)
            _buildInfoRow(
              widget.localizations.translate('note'),
              note,
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
    // Extraire toutes les données before
    final dateBefore = _extractDate(before);
    final montantVerserBefore = _extractAmount(before);
    final commissionnaireNameBefore = _extractCommissionnaireName(before);
    final commissionnairePhoneBefore = _extractCommissionnairePhone(before);
    final clientNameBefore = _extractClientName(before);
    final deviseCodeBefore = _extractDeviseCode(before);
    final tauxUtiliseBefore = _extractTauxUtilise(before);
    final noteBefore = _extractNote(before);

    // Extraire toutes les données after
    final dateAfter = _extractDate(after);
    final montantVerserAfter = _extractAmount(after);
    final commissionnaireNameAfter = _extractCommissionnaireName(after);
    final commissionnairePhoneAfter = _extractCommissionnairePhone(after);
    final clientNameAfter = _extractClientName(after);
    final deviseCodeAfter = _extractDeviseCode(after);
    final tauxUtiliseAfter = _extractTauxUtilise(after);
    final noteAfter = _extractNote(after);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section "Avant la modification"
        _buildSection(
          title: widget.localizations.translate('before_modification'),
          color: Colors.red[50]!,
          borderColor: Colors.red[200]!,
          children: [
            if (dateBefore != null)
              _buildInfoRow(
                widget.localizations.translate('date'),
                _formatDate(dateBefore),
              ),
            if (montantVerserBefore != null)
              _buildInfoRow(
                widget.localizations.translate('amount_deposited'),
                _formatAmount(montantVerserBefore, deviseCodeBefore),
              ),
            if (commissionnaireNameBefore != null)
              _buildInfoRow(
                widget.localizations.translate('commissionnaire_name'),
                commissionnaireNameBefore,
              ),
            if (commissionnairePhoneBefore != null)
              _buildInfoRow(
                widget.localizations.translate('commissionnaire_phone'),
                commissionnairePhoneBefore,
              ),
            if (clientNameBefore != null)
              _buildInfoRow(
                widget.localizations.translate('client_name'),
                clientNameBefore,
              ),
            if (deviseCodeBefore != null)
              _buildInfoRow(
                widget.localizations.translate('currency'),
                deviseCodeBefore,
              ),
            if (tauxUtiliseBefore != null)
              _buildInfoRow(
                widget.localizations.translate('exchange_rate'),
                _formatRate(tauxUtiliseBefore),
              ),
            if (noteBefore != null && noteBefore.isNotEmpty)
              _buildInfoRow(
                widget.localizations.translate('note'),
                noteBefore,
              ),
          ],
        ),
        const SizedBox(height: 24),
        // Section "Après la modification"
        _buildSection(
          title: widget.localizations.translate('after_modification'),
          color: Colors.green[50]!,
          borderColor: Colors.green[200]!,
          children: [
            if (dateAfter != null)
              _buildInfoRow(
                widget.localizations.translate('date'),
                _formatDate(dateAfter),
              ),
            if (montantVerserAfter != null)
              _buildInfoRow(
                widget.localizations.translate('amount_deposited'),
                _formatAmount(montantVerserAfter, deviseCodeAfter),
              ),
            if (commissionnaireNameAfter != null)
              _buildInfoRow(
                widget.localizations.translate('commissionnaire_name'),
                commissionnaireNameAfter,
              ),
            if (commissionnairePhoneAfter != null)
              _buildInfoRow(
                widget.localizations.translate('commissionnaire_phone'),
                commissionnairePhoneAfter,
              ),
            if (clientNameAfter != null)
              _buildInfoRow(
                widget.localizations.translate('client_name'),
                clientNameAfter,
              ),
            if (deviseCodeAfter != null)
              _buildInfoRow(
                widget.localizations.translate('currency'),
                deviseCodeAfter,
              ),
            if (tauxUtiliseAfter != null)
              _buildInfoRow(
                widget.localizations.translate('exchange_rate'),
                _formatRate(tauxUtiliseAfter),
              ),
            if (noteAfter != null && noteAfter.isNotEmpty)
              _buildInfoRow(
                widget.localizations.translate('note'),
                noteAfter,
              ),
          ],
        ),
        const SizedBox(height: 24),
        // Section "Changements"
        _buildChangesSection(
          dateBefore,
          montantVerserBefore,
          commissionnaireNameBefore,
          commissionnairePhoneBefore,
          clientNameBefore,
          deviseCodeBefore,
          tauxUtiliseBefore,
          noteBefore,
          dateAfter,
          montantVerserAfter,
          commissionnaireNameAfter,
          commissionnairePhoneAfter,
          clientNameAfter,
          deviseCodeAfter,
          tauxUtiliseAfter,
          noteAfter,
        ),
      ],
    );
  }

  /// Affiche les données pour DELETE
  Widget _buildDeleteView(Map<String, dynamic> before) {
    final date = _extractDate(before);
    final montantVerser = _extractAmount(before);
    final commissionnaireName = _extractCommissionnaireName(before);
    final commissionnairePhone = _extractCommissionnairePhone(before);
    final clientName = _extractClientName(before);
    final deviseCode = _extractDeviseCode(before);
    final tauxUtilise = _extractTauxUtilise(before);
    final note = _extractNote(before);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Message d'avertissement
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50]!,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.red[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.localizations.translate('element_deleted'),
                  style: TextStyle(
                    color: Colors.red[900],
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Données avant suppression
        _buildSection(
          title: widget.localizations.translate('data_before_deletion'),
          color: Colors.grey[50]!,
          borderColor: Colors.grey[300]!,
          children: [
            if (date != null)
              _buildInfoRow(
                widget.localizations.translate('date'),
                _formatDate(date),
              ),
            if (montantVerser != null)
              _buildInfoRow(
                widget.localizations.translate('amount_deposited'),
                _formatAmount(montantVerser, deviseCode),
              ),
            if (commissionnaireName != null)
              _buildInfoRow(
                widget.localizations.translate('commissionnaire_name'),
                commissionnaireName,
              ),
            if (commissionnairePhone != null)
              _buildInfoRow(
                widget.localizations.translate('commissionnaire_phone'),
                commissionnairePhone,
              ),
            if (clientName != null)
              _buildInfoRow(
                widget.localizations.translate('client_name'),
                clientName,
              ),
            if (deviseCode != null)
              _buildInfoRow(
                widget.localizations.translate('currency'),
                deviseCode,
              ),
            if (tauxUtilise != null)
              _buildInfoRow(
                widget.localizations.translate('exchange_rate'),
                _formatRate(tauxUtilise),
              ),
            if (note != null && note.isNotEmpty)
              _buildInfoRow(
                widget.localizations.translate('note'),
                note,
              ),
          ],
        ),
      ],
    );
  }

  /// Section avec titre et contenu
  Widget _buildSection({
    required String title,
    required Color color,
    required Color borderColor,
    required List<Widget> children,
  }) {
    if (children.isEmpty) {
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
          ...children,
        ],
      ),
    );
  }

  /// Section des changements pour UPDATE
  Widget _buildChangesSection(
    DateTime? dateBefore,
    double? montantVerserBefore,
    String? commissionnaireNameBefore,
    String? commissionnairePhoneBefore,
    String? clientNameBefore,
    String? deviseBefore,
    double? tauxBefore,
    String? noteBefore,
    DateTime? dateAfter,
    double? montantVerserAfter,
    String? commissionnaireNameAfter,
    String? commissionnairePhoneAfter,
    String? clientNameAfter,
    String? deviseAfter,
    double? tauxAfter,
    String? noteAfter,
  ) {
    final datesEqual = _areDatesEqual(dateBefore, dateAfter);
    final hasChanges = datesEqual == false ||
        (montantVerserBefore != montantVerserAfter) ||
        (commissionnaireNameBefore != commissionnaireNameAfter) ||
        (commissionnairePhoneBefore != commissionnairePhoneAfter) ||
        (clientNameBefore != clientNameAfter) ||
        (deviseBefore != deviseAfter) ||
        (tauxBefore != tauxAfter) ||
        (noteBefore != noteAfter);

    if (!hasChanges) {
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
                widget.localizations.translate('no_changes_detected'),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50]!,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                widget.localizations.translate('changes'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_areDatesEqual(dateBefore, dateAfter) != true)
            _buildChangeRow(
              widget.localizations.translate('date'),
              dateBefore != null
                  ? _formatDate(dateBefore)
                  : widget.localizations.translate('na'),
              dateAfter != null
                  ? _formatDate(dateAfter)
                  : widget.localizations.translate('na'),
            ),
          if (montantVerserBefore != montantVerserAfter)
            _buildChangeRow(
              widget.localizations.translate('amount_deposited'),
              _formatAmount(montantVerserBefore, deviseBefore),
              _formatAmount(montantVerserAfter, deviseAfter),
            ),
          if (commissionnaireNameBefore != commissionnaireNameAfter)
            _buildChangeRow(
              widget.localizations.translate('commissionnaire_name'),
              commissionnaireNameBefore ?? widget.localizations.translate('na'),
              commissionnaireNameAfter ?? widget.localizations.translate('na'),
            ),
          if (commissionnairePhoneBefore != commissionnairePhoneAfter)
            _buildChangeRow(
              widget.localizations.translate('commissionnaire_phone'),
              commissionnairePhoneBefore ??
                  widget.localizations.translate('na'),
              commissionnairePhoneAfter ?? widget.localizations.translate('na'),
            ),
          if (clientNameBefore != clientNameAfter)
            _buildChangeRow(
              widget.localizations.translate('client_name'),
              clientNameBefore ?? widget.localizations.translate('na'),
              clientNameAfter ?? widget.localizations.translate('na'),
            ),
          if (deviseBefore != deviseAfter)
            _buildChangeRow(
              widget.localizations.translate('currency'),
              deviseBefore ?? widget.localizations.translate('na'),
              deviseAfter ?? widget.localizations.translate('na'),
            ),
          if (tauxBefore != tauxAfter)
            _buildChangeRow(
              widget.localizations.translate('exchange_rate'),
              tauxBefore != null
                  ? _formatRate(tauxBefore)
                  : widget.localizations.translate('na'),
              tauxAfter != null
                  ? _formatRate(tauxAfter)
                  : widget.localizations.translate('na'),
            ),
          if (noteBefore != noteAfter)
            _buildChangeRow(
              widget.localizations.translate('note'),
              noteBefore ?? widget.localizations.translate('na'),
              noteAfter ?? widget.localizations.translate('na'),
            ),
        ],
      ),
    );
  }

  /// Ligne de changement pour UPDATE
  Widget _buildChangeRow(String label, String beforeValue, String afterValue) {
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
            child: Row(
              children: [
                // Avant
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      beforeValue,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[900],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.arrow_forward, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 12),
                // Après
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      afterValue,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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

  /// Extrait le nom du commissionnaire depuis les données
  String? _extractCommissionnaireName(Map<String, dynamic> data) {
    return data['commissionnaireName']?.toString() ??
        data['commissionnaire_name']?.toString() ??
        data['commissionnaire']?.toString();
  }

  /// Extrait le téléphone du commissionnaire depuis les données
  String? _extractCommissionnairePhone(Map<String, dynamic> data) {
    return data['commissionnairePhone']?.toString() ??
        data['commissionnaire_phone']?.toString() ??
        data['commissionnairePhoneNumber']?.toString();
  }

  /// Extrait le nom du client depuis les données
  String? _extractClientName(Map<String, dynamic> data) {
    return data['partnerName']?.toString() ??
        data['partner_name']?.toString() ??
        data['clientName']?.toString() ??
        data['client_name']?.toString() ??
        data['customerName']?.toString();
  }

  /// Extrait la note depuis les données
  String? _extractNote(Map<String, dynamic> data) {
    final note = data['note']?.toString() ?? data['notes']?.toString();
    return note?.trim().isEmpty == true ? null : note;
  }

  /// Extrait le montant versé depuis les données
  double? _extractAmount(Map<String, dynamic> data) {
    // Essayer différentes clés possibles
    final amount = data['montantVerser'] ??
        data['montantverser'] ??
        data['montant_verser'] ??
        data['amountDeposited'] ??
        data['amount'];

    if (amount == null) return null;
    if (amount is num) return amount.toDouble();
    if (amount is String) return double.tryParse(amount);
    return null;
  }

  /// Formate un montant avec la devise
  String _formatAmount(double? amount, String? deviseCode) {
    if (amount == null) return 'N/A';

    final formatter = NumberFormat.currency(
      symbol: deviseCode ?? '',
      decimalDigits: 2,
    );

    return formatter.format(amount);
  }

  /// Extrait le code de la devise depuis les données
  String? _extractDeviseCode(Map<String, dynamic> data) {
    return data['deviseCode']?.toString() ??
        data['devise_code']?.toString() ??
        data['currencyCode']?.toString() ??
        data['currency']?.toString();
  }

  /// Extrait le taux utilisé depuis les données
  double? _extractTauxUtilise(Map<String, dynamic> data) {
    final taux = data['tauxUtilise'] ??
        data['tauxutilise'] ??
        data['taux_utilise'] ??
        data['rateUsed'] ??
        data['rate'] ??
        data['exchangeRate'];

    if (taux == null) return null;
    if (taux is num) return taux.toDouble();
    if (taux is String) return double.tryParse(taux);
    return null;
  }

  /// Formate une date
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return ActivityLogTranslator.formatDateTime(date);
  }

  /// Compare deux dates (retourne null si aucune différence)
  bool? _areDatesEqual(DateTime? date1, DateTime? date2) {
    if (date1 == null && date2 == null) return true;
    if (date1 == null || date2 == null) return false;
    return date1.isAtSameMomentAs(date2);
  }

  /// Formate un taux de change
  String _formatRate(double? rate) {
    if (rate == null) return 'N/A';
    return NumberFormat('#,##0.00').format(rate);
  }

  /// Vérifie si les données représentent un transfert
  bool _isTransfer(Map<String, dynamic>? data) {
    if (data == null) return false;
    return data.containsKey('oldPartnerId') && data.containsKey('newPartnerId');
  }

  /// Affiche la vue spéciale pour les transferts
  Widget _buildTransferView(
    Map<String, dynamic> data,
    Map<String, dynamic>? beforeData,
    Map<String, dynamic>? afterData,
  ) {
    // Utiliser afterData si disponible, sinon data
    final transferData = afterData ?? data;

    final userName = _extractUserName(transferData);
    final oldPartnerName = _extractOldPartnerName(transferData);
    final newPartnerName = _extractNewPartnerName(transferData);
    final date = _extractDate(transferData);
    final montantVerser = _extractAmount(transferData);
    final deviseCode = _extractDeviseCode(transferData);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple[50]!,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple[200]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de transfert
          Row(
            children: [
              Icon(Icons.swap_horiz, color: Colors.purple[700], size: 24),
              const SizedBox(width: 12),
              Text(
                widget.localizations.translate('transfer'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Informations de transfert
          if (date != null)
            _buildInfoRow(
              widget.localizations.translate('date'),
              _formatDate(date),
            ),
          if (userName != null)
            _buildInfoRow(
              widget.localizations.translate('user'),
              userName,
            ),
          if (oldPartnerName != null)
            _buildInfoRow(
              widget.localizations.translate('from_client'),
              oldPartnerName,
            ),
          if (newPartnerName != null)
            _buildInfoRow(
              widget.localizations.translate('to_client'),
              newPartnerName,
            ),
          if (montantVerser != null)
            _buildInfoRow(
              widget.localizations.translate('amount_deposited'),
              _formatAmount(montantVerser, deviseCode),
            ),
          if (deviseCode != null)
            _buildInfoRow(
              widget.localizations.translate('currency'),
              deviseCode,
            ),
        ],
      ),
    );
  }

  /// Extrait le nom de l'utilisateur depuis les données
  String? _extractUserName(Map<String, dynamic> data) {
    return data['userName']?.toString() ??
        data['user_name']?.toString() ??
        data['user']?.toString();
  }

  /// Extrait le nom de l'ancien partenaire depuis les données
  String? _extractOldPartnerName(Map<String, dynamic> data) {
    return data['oldPartnerName']?.toString() ??
        data['old_partner_name']?.toString() ??
        data['oldPartner']?.toString();
  }

  /// Extrait le nom du nouveau partenaire depuis les données
  String? _extractNewPartnerName(Map<String, dynamic> data) {
    return data['newPartnerName']?.toString() ??
        data['new_partner_name']?.toString() ??
        data['newPartner']?.toString();
  }
}
