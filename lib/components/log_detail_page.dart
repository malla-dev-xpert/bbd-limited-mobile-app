import 'package:flutter/material.dart';
import 'package:bbd_limited/models/log_detail.dart';
import 'package:bbd_limited/core/services/log_service.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/utils/activity_log_translator.dart';
import 'package:bbd_limited/logs/resolvers/log_details_resolver.dart';
import 'package:bbd_limited/logs/widgets/smart_log_details_widget.dart';
import 'package:bbd_limited/logs/widgets/log_action_badge.dart';
import 'package:bbd_limited/logs/widgets/log_summary_card.dart';
import 'package:bbd_limited/core/enums/log_action.dart';
import 'package:bbd_limited/core/enums/log_entity_type.dart';

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

    // Résoudre le log pour déterminer comment l'afficher
    final resolution = LogDetailsResolver.resolve(detail);

    // Générer la phrase métier
    final businessPhrase =
        LogDetailsResolver.generateBusinessPhrase(resolution);

    // Obtenir l'action et le type d'entité
    final action = resolution.action;
    final entityType = resolution.entityType;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🟦 A. Header du log (toujours visible)
          _buildHeaderCard(action, entityType, detail, businessPhrase),
          const SizedBox(height: 24),
          // 🟨 B. Résumé métier (si disponible, mais pas pour les créations)
          if (action != LogAction.CREATE &&
              !resolution.businessData.isEmpty &&
              resolution.businessData.mainData.isNotEmpty) ...[
            LogSummaryCard(
              businessData: resolution.businessData,
              localizations: localizations,
            ),
            const SizedBox(height: 24),
          ],
          // 🟥 C. Détails de l'opération (UPDATE/DELETE/CREATE)
          if (!resolution.businessData.isEmpty) ...[
            SmartLogDetailsWidget(
              resolution: resolution,
              localizations: localizations,
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 🟦 Header du log - Card principale épinglée en haut
  Widget _buildHeaderCard(
    LogAction action,
    LogEntityType entityType,
    LogDetail detail,
    String businessPhrase,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge action
          LogActionBadge(action: action),
          const SizedBox(height: 16),
          // Type d'entité lisible
          Text(
            entityType.displayName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Auteur + date
          Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Effectué par : ${detail.userName ?? 'Inconnu'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Le : ${ActivityLogTranslator.formatDateTime(detail.createdAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
