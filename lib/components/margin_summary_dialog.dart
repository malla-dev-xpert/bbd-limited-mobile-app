import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/margin_calculation_service.dart';
import 'package:bbd_limited/models/invoice_options.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:intl/intl.dart';

/// Dialog de récapitulatif des marges avant impression
class MarginSummaryDialog extends StatelessWidget {
  final double subtotal;
  final List<Items> items;
  final InvoiceOptions options;
  final String currencySymbol;
  final VoidCallback onValidate;
  final VoidCallback onCancel;

  const MarginSummaryDialog({
    Key? key,
    required this.subtotal,
    required this.items,
    required this.options,
    required this.currencySymbol,
    required this.onValidate,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: currencySymbol,
    );

    // Calculer le résultat avec les marges sélectives
    final result = MarginCalculationService.calculateWithSelectiveMargins(
      subtotal: subtotal,
      items: items,
      options: options,
      selectiveItemMargins: options.selectiveItemMargins,
      selectiveFeeMargins: options.selectiveFeeMargins,
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1E49),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.summarize, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      localizations.translate('margin_summary_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onCancel,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sous-total original
                    _buildSummaryRow(
                      localizations.translate('original_total'),
                      currencyFormat.format(subtotal),
                      isHeader: true,
                    ),
                    const SizedBox(height: 16),

                    // Articles avec marge
                    if (result.itemMargins.isNotEmpty) ...[
                      Text(
                        localizations.translate('margin_summary_items'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1E49),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...result.itemMargins.values.map((margin) {
                        final item = items.firstWhere(
                          (item) => item.id == margin.itemId,
                          orElse: () => items.first,
                        );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.description ??
                                    localizations.translate('unnamed_item'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildDetailRow(
                                '${localizations.translate('original_total')}:',
                                currencyFormat
                                    .format(margin.originalTotalPrice),
                              ),
                              _buildDetailRow(
                                '${localizations.translate('margin_amount')}:',
                                '+${currencyFormat.format(margin.marginAmount)}',
                                color: Colors.green[700],
                              ),
                              _buildDetailRow(
                                '${localizations.translate('adjusted_total')}:',
                                currencyFormat
                                    .format(margin.adjustedTotalPrice),
                                isBold: true,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                    ],

                    // Frais avec marge
                    if (result.feeMargins.isNotEmpty) ...[
                      Text(
                        localizations.translate('margin_summary_fees'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1E49),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...result.feeMargins.values.map((margin) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                margin.feeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildDetailRow(
                                '${localizations.translate('original_amount')}:',
                                currencyFormat.format(margin.originalAmount),
                              ),
                              _buildDetailRow(
                                '${localizations.translate('margin_amount')}:',
                                '+${currencyFormat.format(margin.marginAmount)}',
                                color: Colors.green[700],
                              ),
                              _buildDetailRow(
                                '${localizations.translate('adjusted_amount')}:',
                                currencyFormat.format(margin.adjustedAmount),
                                isBold: true,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                    ],

                    // Total des marges
                    if (result.totalItemMargins > 0 ||
                        result.totalFeeMargins > 0) ...[
                      _buildSummaryRow(
                        localizations.translate('margin_summary_total_margins'),
                        currencyFormat.format(
                            result.totalItemMargins + result.totalFeeMargins),
                        color: Colors.blue[700],
                        isBold: true,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Total final
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1E49),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localizations
                                .translate('margin_summary_final_total'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            currencyFormat.format(result.finalTotal),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: Text(localizations.translate('cancel')),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onValidate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1E49),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(localizations.translate('validate_print')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
    bool isHeader = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isHeader ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHeader ? Colors.grey[300]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHeader ? 16 : 14,
              fontWeight:
                  isBold || isHeader ? FontWeight.bold : FontWeight.normal,
              color: color ??
                  (isHeader ? const Color(0xFF1A1E49) : Colors.black87),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHeader ? 18 : 14,
              fontWeight:
                  isBold || isHeader ? FontWeight.bold : FontWeight.normal,
              color: color ??
                  (isHeader ? const Color(0xFF1A1E49) : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
