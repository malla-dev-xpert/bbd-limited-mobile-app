import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget réutilisable pour la section des totaux de facture
/// Aligné sur le design fourni avec sous-total, options et total final
class InvoiceTotals extends StatelessWidget {
  final double subtotal;
  final double total;
  final NumberFormat currencyFormat;
  final Map<String, double>? additionalCharges;
  final Map<String, double>? discounts;

  const InvoiceTotals({
    Key? key,
    required this.subtotal,
    required this.total,
    required this.currencyFormat,
    this.additionalCharges,
    this.discounts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Sous-total
          _buildTotalRow(
            'Subtotal',
            currencyFormat.format(subtotal),
            isBold: true,
          ),
          const SizedBox(height: 8),
          
          // Remises
          if (discounts != null && discounts!.isNotEmpty)
            ...discounts!.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildTotalRow(
                    entry.key,
                    '-${currencyFormat.format(entry.value)}',
                    isBold: false,
                  ),
                )),
          
          // Charges additionnelles
          if (additionalCharges != null && additionalCharges!.isNotEmpty)
            ...additionalCharges!.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildTotalRow(
                    entry.key,
                    currencyFormat.format(entry.value),
                    isBold: false,
                  ),
                )),
          
          const Divider(height: 24),
          
          // Total final
          _buildTotalRow(
            'TOTAL',
            currencyFormat.format(total),
            isBold: true,
            isLarge: true,
            color: const Color(0xFF1A1E49),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    bool isLarge = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: isLarge ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black87,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xFF1A1E49),
          ),
        ),
      ],
    );
  }
}

