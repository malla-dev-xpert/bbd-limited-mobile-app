import 'package:flutter/material.dart';
import 'package:bbd_limited/models/log_detail.dart';
import 'package:bbd_limited/models/activity_log.dart';
import 'package:bbd_limited/core/services/log_service.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/utils/activity_log_translator.dart';
import 'package:intl/intl.dart';

class LogDetailPage extends StatefulWidget {
  final int logId;

  const LogDetailPage({
    super.key,
    required this.logId,
  });

  static Future<void> show(BuildContext context, int logId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogDetailPage(logId: logId),
      ),
    );
  }

  @override
  State<LogDetailPage> createState() => _LogDetailPageState();
}

class _LogDetailPageState extends State<LogDetailPage> {
  final LogService _logService = LogService();
  LogDetail? _logDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLogDetails();
  }

  Future<void> _loadLogDetails() async {
    try {
      final detail = await _logService.getLogDetails(widget.logId);
      if (mounted) {
        setState(() {
          _logDetail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1E49)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          localizations.translate('activity_history_details'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1E49),
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A1E49),
              ),
            )
          : _errorMessage != null
              ? _buildErrorState(localizations)
              : _logDetail != null
                  ? _buildContent(localizations)
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildErrorState(AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? localizations.translate('error'),
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadLogDetails,
              child: Text(localizations.translate('try_again')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations localizations) {
    if (_logDetail == null) return const SizedBox.shrink();

    final detail = _logDetail!;
    final actionColor = ActivityLogTranslator.getActionColor(detail.action);
    final actionIcon = ActivityLogTranslator.getActionIcon(detail.action);
    final actionText = _buildActionText(detail);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action summary card
          _buildActionCard(actionColor, actionIcon, actionText, detail),
          const SizedBox(height: 32),
          // User information
          _buildSection(
            localizations.translate('activity_history_user'),
            [
              _buildInfoRow(
                localizations.translate('name'),
                detail.userName ?? localizations.translate('unknown'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Date and time
          _buildSection(
            localizations.translate('activity_history_date'),
            [
              _buildInfoRow(
                localizations.translate('date_time'),
                ActivityLogTranslator.formatDateTime(detail.createdAt),
              ),
            ],
          ),
          // Operation details
          if (detail.entityDetails != null &&
              detail.entityDetails!.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildEntityDetails(detail.entityDetails!, localizations),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    Color color,
    IconData icon,
    String actionText,
    LogDetail detail,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ActivityLogTranslator.formatDateTime(detail.createdAt),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1E49),
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityDetails(
    Map<String, dynamic> details,
    AppLocalizations localizations,
  ) {
    // Liste des clés à exclure (IDs, status, etc.)
    final excludedKeys = {
      'id',
      'entityId',
      'entityIds',
      'status',
      'userId',
      'supplierId',
      'partnerId',
      'clientId',
      'warehouseId',
      'containerId',
      'harborId',
      'deviseId',
      'categoryId',
      'carrierId',
      'countryId',
      'count', // Pour les actions groupées
    };

    // Détails spécifiques selon le type d'entité
    final List<Widget> detailWidgets = [];

    details.forEach((key, value) {
      // Vérifier que la clé n'est pas exclue
      if (excludedKeys.contains(key.toLowerCase())) {
        return;
      }

      // Vérifier que la valeur n'est pas null, vide, ou une chaîne vide
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      if (value is List && value.isEmpty) return;
      if (value is Map && value.isEmpty) return;

      final displayKey = _translateDetailKey(key, localizations);
      final displayValue = _formatDetailValue(key, value, localizations);

      // Ne pas afficher si la valeur formatée est vide ou "N/A"
      if (displayValue.trim().isEmpty ||
          displayValue == localizations.translate('na')) {
        return;
      }

      detailWidgets.add(_buildInfoRow(displayKey, displayValue));
    });

    if (detailWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      localizations.translate('activity_history_operation_details'),
      detailWidgets,
    );
  }

  String _buildActionText(LogDetail detail) {
    // Créer un ActivityLog temporaire pour utiliser le traducteur
    final tempLog = ActivityLog(
      id: detail.id,
      actionCode: detail.action,
      entityType: detail.entityType,
      entityId: detail.entityId,
      entityIds: detail.entityIds,
      createdAt: detail.createdAt,
      user: ActivityLogUser(
        id: detail.userId ?? 0,
        username: detail.userName,
      ),
    );

    final actionText = ActivityLogTranslator.translateAction(tempLog);
    return '${detail.userName ?? "Utilisateur inconnu"} $actionText';
  }

  String _translateDetailKey(String key, AppLocalizations localizations) {
    final keyLower = key.toLowerCase();

    // Traduire les clés communes avec des noms explicites
    final translations = {
      // Informations générales
      'id': 'ID',
      'name': localizations.translate('name'),
      'description': localizations.translate('description'),
      'status': localizations.translate('status'),
      'type': localizations.translate('type'),
      'reference': localizations.translate('reference'),
      'ref': localizations.translate('reference'),

      // Dates
      'createdat': localizations.translate('date'),
      'created_at': localizations.translate('date'),
      'editedat': localizations.translate('edited_at'),
      'edited_at': localizations.translate('edited_at'),

      // Montants et prix
      'amount': localizations.translate('amount'),
      'montant': localizations.translate('amount'),
      'montantverser': localizations.translate('amount_deposited'),
      'montantVerser': localizations.translate('amount_deposited'),
      'montantrestant': localizations.translate('remaining_amount'),
      'montantRestant': localizations.translate('remaining_amount'),
      'montantconverti': localizations.translate('converted_amount'),
      'montantConverti': localizations.translate('converted_amount'),
      'montantconverticny': localizations.translate('converted_amount_cny'),
      'montantConvertiCNY': localizations.translate('converted_amount_cny'),
      'quantity': localizations.translate('quantity'),
      'unitprice': localizations.translate('unit_price'),
      'unitPrice': localizations.translate('unit_price'),
      'totalprice': localizations.translate('total_price'),
      'totalPrice': localizations.translate('total_price'),
      'rate': localizations.translate('rate'),
      'salesrate': localizations.translate('sales_rate'),
      'salesRate': localizations.translate('sales_rate'),

      // Personnes et contacts
      'firstname': localizations.translate('first_name'),
      'firstName': localizations.translate('first_name'),
      'lastname': localizations.translate('last_name'),
      'lastName': localizations.translate('last_name'),
      'partnername': localizations.translate('partner_name'),
      'partnerName': localizations.translate('partner_name'),
      'suppliername': localizations.translate('supplier_name'),
      'supplierName': localizations.translate('supplier_name'),
      'clientname': localizations.translate('client_name'),
      'clientName': localizations.translate('client_name'),
      'phonenumber': localizations.translate('phone'),
      'phoneNumber': localizations.translate('phone'),
      'commissionnairename': localizations.translate('commissionnaire_name'),
      'commissionnaireName': localizations.translate('commissionnaire_name'),
      'commissionnairephone': localizations.translate('commissionnaire_phone'),
      'commissionnairePhone': localizations.translate('commissionnaire_phone'),
      'email': localizations.translate('email'),

      // Informations financières
      'balance': localizations.translate('balance'),
      'accounttype': localizations.translate('account_type'),
      'accountType': localizations.translate('account_type'),
      'amountpaid': localizations.translate('amount_paid'),
      'amountPaid': localizations.translate('amount_paid'),
      'paiementdate': localizations.translate('payment_date'),
      'paiementDate': localizations.translate('payment_date'),
      'paid': localizations.translate('paid'),

      // Informations sur les colis et conteneurs
      'weight': localizations.translate('weight'),
      'size': localizations.translate('size'),
      'destinationcountry': localizations.translate('destination_country'),
      'destinationCountry': localizations.translate('destination_country'),
      'startcountry': localizations.translate('start_country'),
      'startCountry': localizations.translate('start_country'),
      'location': localizations.translate('location'),
      'adresse': localizations.translate('address'),
      'address': localizations.translate('address'),
      'storagetype': localizations.translate('storage_type'),
      'storageType': localizations.translate('storage_type'),

      // Informations sur les ports
      'harborname': localizations.translate('harbor_name'),
      'harborName': localizations.translate('harbor_name'),

      // Informations sur les devises
      'code': localizations.translate('code'),
      'isocode': localizations.translate('iso_code'),
      'isoCode': localizations.translate('iso_code'),

      // Informations sur les articles
      'invoicenumber': localizations.translate('invoice_number'),
      'invoiceNumber': localizations.translate('invoice_number'),

      // Notes et autres
      'note': localizations.translate('note'),
      'notes': localizations.translate('notes'),
    };

    // Vérifier d'abord la clé exacte
    if (translations.containsKey(key)) {
      return translations[key]!;
    }

    // Vérifier la clé en minuscules
    if (translations.containsKey(keyLower)) {
      return translations[keyLower]!;
    }

    // Si pas de traduction, formater la clé en camelCase vers texte lisible
    return _formatKeyToReadable(key);
  }

  /// Formate une clé technique en texte lisible
  String _formatKeyToReadable(String key) {
    // Remplacer les majuscules par des espaces et mettre en minuscules
    String result = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)!.toLowerCase()}',
    );

    // Mettre la première lettre en majuscule
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }

    // Nettoyer les espaces multiples
    result = result.trim().replaceAll(RegExp(r'\s+'), ' ');

    return result;
  }

  String _formatDetailValue(
    String key,
    dynamic value,
    AppLocalizations localizations,
  ) {
    if (value == null) return '';

    // Formater les dates
    if (key.toLowerCase().contains('date') ||
        key.toLowerCase().contains('at')) {
      if (value is String) {
        final date = DateTime.tryParse(value);
        if (date != null) {
          return ActivityLogTranslator.formatDateTime(date);
        }
      }
    }

    // Formater les nombres
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
