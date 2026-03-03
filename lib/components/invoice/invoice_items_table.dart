import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:intl/intl.dart';

/// Modèle pour un article de facture
class InvoiceItem {
  final String? productPicture;
  final String productName;
  final double totalCBM;
  final double totalWeight;
  final int carton;
  final double unitPerCarton;
  final double totalQuantity;
  final double price;
  final double amount;

  InvoiceItem({
    this.productPicture,
    required this.productName,
    this.totalCBM = 0.0,
    this.totalWeight = 0.0,
    required this.carton,
    required this.unitPerCarton,
    required this.totalQuantity,
    required this.price,
    required this.amount,
  });
}

/// Widget réutilisable pour le tableau des articles de facture
/// Aligné sur le design fourni avec colonnes : Product Name, Total CBM, Total Weight, Carton, Unit / Carton, Total Quantity, Price, Amount
class InvoiceItemsTable extends StatelessWidget {
  final List<InvoiceItem> items;
  final NumberFormat currencyFormat;
  final bool showPagination;
  final int currentPage;
  final int totalPages;
  final Function(int)? onPageChanged;

  const InvoiceItemsTable({
    Key? key,
    required this.items,
    required this.currencyFormat,
    this.showPagination = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête du tableau
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD), // Bleu clair comme dans l'image
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.0), // Product Name
              1: FlexColumnWidth(0.8), // Total CBM
              2: FlexColumnWidth(0.8), // Total Weight
              3: FlexColumnWidth(0.6), // Carton
              4: FlexColumnWidth(1.0), // Unit / Carton
              5: FlexColumnWidth(1.0), // Total Quantity
              6: FlexColumnWidth(0.9), // Price
              7: FlexColumnWidth(1.0), // Amount
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                ),
                children: [
                  _buildHeaderCell(context, 'Product Name'),
                  _buildHeaderCell(context, 'Total CBM'),
                  _buildHeaderCell(context, 'Total Weight'),
                  _buildHeaderCell(context, 'Carton'),
                  _buildHeaderCell(context, 'Unit / Carton'),
                  _buildHeaderCell(context, 'Total Quantity'),
                  _buildHeaderCell(context, 'Price'),
                  _buildHeaderCell(context, 'Amount'),
                ],
              ),
            ],
          ),
        ),

        // Corps du tableau
        Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Colors.grey[300]!),
              right: BorderSide(color: Colors.grey[300]!),
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.0),
              1: FlexColumnWidth(0.8),
              2: FlexColumnWidth(0.8),
              3: FlexColumnWidth(0.6),
              4: FlexColumnWidth(1.0),
              5: FlexColumnWidth(1.0),
              6: FlexColumnWidth(0.9),
              7: FlexColumnWidth(1.0),
            },
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isEven = index % 2 == 0;

              return TableRow(
                decoration: BoxDecoration(
                  color: isEven ? Colors.white : Colors.grey[50],
                ),
                children: [
                  _buildDataCell(context, item.productName),
                  _buildDataCell(context, item.totalCBM.toStringAsFixed(2)),
                  _buildDataCell(context, item.totalWeight.toStringAsFixed(2)),
                  _buildDataCell(context, item.carton.toString()),
                  _buildDataCell(context, item.unitPerCarton.toStringAsFixed(2)),
                  _buildDataCell(context, item.totalQuantity.toStringAsFixed(2)),
                  _buildDataCell(context, currencyFormat.format(item.price)),
                  _buildDataCell(context, currencyFormat.format(item.amount)),
                ],
              );
            }).toList(),
          ),
        ),

        // Pagination si activée
        if (showPagination && totalPages > 1) ...[
          const SizedBox(height: 16),
          _buildPagination(context),
        ],
      ],
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(
        text,
        style: AppTextSize.captionStyle(context,
                color: const Color(0xFF1A1E49))
            .copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }

  Widget _buildDataCell(BuildContext context, dynamic content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: content is Widget
          ? Center(child: content)
          : Text(
              content.toString(),
              style: AppTextSize.captionStyle(context, color: Colors.black87),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
    );
  }

  Widget _buildPagination(BuildContext context) {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyy.MM.dd HH:mm:ss').format(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          timestamp,
          style: AppTextSize.captionStyle(context, color: Colors.grey[600]),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              onPressed: currentPage > 1
                  ? () => onPageChanged?.call(currentPage - 1)
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            Text(
              '$currentPage/$totalPages',
              style: AppTextSize.bodyStyle(context,
                  fontWeight: FontWeight.w600, color: const Color(0xFF1A1E49)),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: currentPage < totalPages
                  ? () => onPageChanged?.call(currentPage + 1)
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }
}
