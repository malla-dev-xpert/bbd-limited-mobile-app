import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'invoice_header.dart';
import 'invoice_items_table.dart';
import 'invoice_totals.dart';

/// Widget principal de facture qui combine tous les composants
/// Utilise le design unifié basé sur l'image fournie
class InvoiceWidget extends StatelessWidget {
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String? customerName;
  final String? customerPhone;
  final String? customerRegisterNo;
  final String? commissionnaireName;
  final String? commissionnairePhone;
  final String currency;
  final double exchangeRate;
  final int? totalPurchaseOrder;
  final Uint8List? logoBytes;
  final List<InvoiceItem> items;
  final double subtotal;
  final double total;
  final Map<String, double>? additionalCharges;
  final Map<String, double>? discounts;
  final bool showPagination;
  final int currentPage;
  final int totalPages;
  final Function(int)? onPageChanged;
  final bool isVersement; // true pour versement, false pour achat

  const InvoiceWidget({
    Key? key,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.customerName,
    this.customerPhone,
    this.customerRegisterNo,
    this.commissionnaireName,
    this.commissionnairePhone,
    required this.currency,
    this.exchangeRate = 1.0,
    this.totalPurchaseOrder,
    this.logoBytes,
    required this.items,
    required this.subtotal,
    required this.total,
    this.additionalCharges,
    this.discounts,
    this.showPagination = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPageChanged,
    this.isVersement = false, // Par défaut, c'est un achat
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: currency,
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            InvoiceHeader(
              invoiceNumber: invoiceNumber,
              invoiceDate: invoiceDate,
              customerName: customerName,
              customerPhone: customerPhone,
              customerRegisterNo: customerRegisterNo,
              commissionnaireName: commissionnaireName,
              commissionnairePhone: commissionnairePhone,
              currency: currency,
              exchangeRate: exchangeRate,
              totalPurchaseOrder: totalPurchaseOrder,
              logoBytes: logoBytes,
              isVersement: isVersement,
            ),

            const SizedBox(height: 32),

            // Tableau des articles
            InvoiceItemsTable(
              items: items,
              currencyFormat: currencyFormat,
              showPagination: showPagination,
              currentPage: currentPage,
              totalPages: totalPages,
              onPageChanged: onPageChanged,
            ),

            const SizedBox(height: 24),

            // Totaux
            InvoiceTotals(
              subtotal: subtotal,
              total: total,
              currencyFormat: currencyFormat,
              additionalCharges: additionalCharges,
              discounts: discounts,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fonction utilitaire pour convertir une liste d'Items en InvoiceItem
List<InvoiceItem> convertItemsToInvoiceItems(List<Items> items) {
  return items.map((item) {
    final carton = item.carton ?? 0;
    final unitPerCarton = (item.quantityPerCarton ?? 0).toDouble();
    final totalQuantity = (item.quantity ?? 0).toDouble();
    final price = item.unitPrice ?? 0.0;
    final amount = item.totalPrice ?? 0.0;

    return InvoiceItem(
      productName: item.description ?? '',
      carton: carton,
      unitPerCarton: unitPerCarton,
      totalQuantity: totalQuantity,
      price: price,
      amount: amount,
      totalCBM: 0.0, // Par défaut, peut être calculé si disponible
      totalWeight: 0.0, // Par défaut, peut être calculé si disponible
    );
  }).toList();
}

/// Fonction utilitaire pour convertir une liste d'Achat en InvoiceItem
List<InvoiceItem> convertAchatsToInvoiceItems(List<Achat> achats) {
  final List<InvoiceItem> invoiceItems = [];

  for (final achat in achats) {
    if (achat.items != null) {
      invoiceItems.addAll(convertItemsToInvoiceItems(achat.items!));
    }
  }

  return invoiceItems;
}
