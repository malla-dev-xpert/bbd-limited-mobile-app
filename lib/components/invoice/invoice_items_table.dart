import 'package:flutter/material.dart';
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
/// Aligné sur le design fourni avec colonnes : Product Picture, Product Name, Total CBM, Total Weight, Carton, Unit / Carton, Total Quantity, Price, Amount
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
              0: FlexColumnWidth(0.8), // Product Picture
              1: FlexColumnWidth(2.5), // Product Name
              2: FlexColumnWidth(1.0), // Total CBM
              3: FlexColumnWidth(1.0), // Total Weight
              4: FlexColumnWidth(0.8), // Carton
              5: FlexColumnWidth(1.2), // Unit / Carton
              6: FlexColumnWidth(1.2), // Total Quantity
              7: FlexColumnWidth(1.0), // Price
              8: FlexColumnWidth(1.2), // Amount
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                ),
                children: [
                  _buildHeaderCell('Product Picture'),
                  _buildHeaderCell('Product Name'),
                  _buildHeaderCell('Total CBM'),
                  _buildHeaderCell('Total Weight'),
                  _buildHeaderCell('Carton'),
                  _buildHeaderCell('Unit / Carton'),
                  _buildHeaderCell('Total Quantity'),
                  _buildHeaderCell('Price'),
                  _buildHeaderCell('Amount'),
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
              0: FlexColumnWidth(0.8),
              1: FlexColumnWidth(2.5),
              2: FlexColumnWidth(1.0),
              3: FlexColumnWidth(1.0),
              4: FlexColumnWidth(0.8),
              5: FlexColumnWidth(1.2),
              6: FlexColumnWidth(1.2),
              7: FlexColumnWidth(1.0),
              8: FlexColumnWidth(1.2),
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
                  _buildDataCell(
                    item.productPicture != null
                        ? Image.network(item.productPicture!, width: 40, height: 40)
                        : const SizedBox.shrink(),
                  ),
                  _buildDataCell(item.productName),
                  _buildDataCell(item.totalCBM.toStringAsFixed(2)),
                  _buildDataCell(item.totalWeight.toStringAsFixed(2)),
                  _buildDataCell(item.carton.toString()),
                  _buildDataCell(item.unitPerCarton.toStringAsFixed(2)),
                  _buildDataCell(item.totalQuantity.toStringAsFixed(2)),
                  _buildDataCell(currencyFormat.format(item.price)),
                  _buildDataCell(currencyFormat.format(item.amount)),
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

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1E49),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(dynamic content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: content is Widget
          ? Center(child: content)
          : Text(
              content.toString(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1E49),
              ),
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

