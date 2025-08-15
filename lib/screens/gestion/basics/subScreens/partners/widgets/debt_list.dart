import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class DebtListWidget extends StatelessWidget {
  final List<Achat>? debts;
  final Future<void> Function() onRefresh;
  final void Function(BuildContext, Achat) onDebtTap;

  const DebtListWidget({
    Key? key,
    required this.debts,
    required this.onRefresh,
    required this.onDebtTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (debts == null || debts!.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.2,
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context).translate('no_debts_found'),
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100, left: 10, right: 10),
        itemCount: debts?.length ?? 0,
        itemBuilder: (context, index) {
          final achat = debts![index];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onDebtTap(context, achat),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${AppLocalizations.of(context).translate('identifier')}: ${achat.id ?? "N/A"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(achat.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (achat.status == Status.COMPLETED
                              ? AppLocalizations.of(context).translate('completed')
                              : achat.status == Status.PENDING
                                  ? AppLocalizations.of(context).translate('pending')
                                  : (achat.status != null
                                      ? achat.status.toString().split('.').last
                                      : "N/A")),
                          style: TextStyle(
                            color: _getStatusColor(achat.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey[700]!,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (achat.client != null && achat.client!.isNotEmpty)
                              ? achat.client!
                              : (achat.isDebt == true && achat.clientId != null)
                                  ? '${AppLocalizations.of(context).translate('client_label')} #${achat.clientId}'
                                  : "N/A",
                          style: TextStyle(
                            color: Colors.grey[700]!,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (achat.clientPhone != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: Colors.grey[700]!,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          achat.clientPhone!,
                          style: TextStyle(
                            color: Colors.grey[700]!,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (achat.createdAt != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[700]!,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${AppLocalizations.of(context).translate('purchased_on')} ${DateFormat('dd/MM/yyyy').format(achat.createdAt!)}',
                          style: TextStyle(
                            color: Colors.grey[700]!,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('total_amount'),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${achat.montantTotal?.toStringAsFixed(2) ?? "0.00"} ¥',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1E49),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(status) {
    final statusStr = status != null ? status.toString().split('.').last : "";
    if (statusStr == "COMPLETED") {
      return Colors.green;
    } else if (statusStr == "PENDING") {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }
}
