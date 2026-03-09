import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:bbd_limited/core/print/pdf_header.dart';
import 'package:bbd_limited/core/print/print_styles.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/models/cashWithdrawal.dart';
import 'package:bbd_limited/core/print/print_localizations.dart';
import 'package:bbd_limited/models/invoice_options.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/core/services/item_services.dart';

class PartnerPrintService {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'zh_CN', // Locale chinois
    symbol: '¥ ',
    decimalDigits: 2,
  );

  static Future<Uint8List> buildClientReportPdfBytes(
    Partner partner, {
    DateTimeRange? dateRange,
    required PrintLocalizations printLocalizations,
    InvoiceOptions? invoiceOptions,
  }) async {
    final pdf = pw.Document();

    // Les polices sont déterminées dans chaque méthode selon la langue

    final logoBytes = await rootBundle
        .load('assets/images/logo.png')
        .then((data) => data.buffer.asUint8List());
    final headerFonts = await PdfHeader.loadFonts();

    final filteredVersements = _filterVersements(partner.versements, dateRange);
    final filteredPackages = _filterPackages(partner.packages, dateRange);

    // Collect all depenses across all versements
    final allDepenses = filteredVersements
        .expand((v) => v.cashWithdrawalDtoList ?? <CashWithdrawal>[])
        .toList();

    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.zero,
        build: (context) => [
          pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(
                    logoBytes, headerFonts, dateRange, printLocalizations),
                pw.SizedBox(height: 16),
                _buildClientInfoSection(partner, printLocalizations),
                if (filteredVersements.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  _buildPurchasedItemsSection(
                      filteredVersements, printLocalizations),
                ],
                if (filteredVersements.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  _buildVersementsSection(
                      filteredVersements, printLocalizations),
                ],
                if (allDepenses.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  _buildDepensesSection(allDepenses, printLocalizations),
                ],
                pw.SizedBox(height: 16),
                _buildSummarySection(
                  filteredVersements,
                  filteredPackages,
                  allDepenses,
                  printLocalizations,
                ),
                if (filteredPackages.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  _buildPackagesSection(filteredPackages, printLocalizations),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static final DateFormat _invoiceDateFormat = DateFormat('yyyy.MM.dd');

  /// Génère le PDF "Market Finance Invoice" (Résumé du client) dans la langue choisie.
  static Future<Uint8List> buildMarketFinanceInvoicePdfBytes(
    Partner partner, {
    required PrintLocalizations printLocalizations,
  }) async {
    final pdf = pw.Document();
    final logoBytes = await rootBundle
        .load('assets/images/logo.png')
        .then((data) => data.buffer.asUint8List());
    final headerFonts = await PdfHeader.loadFonts();
    final versements = partner.versements ?? [];
    final pl = printLocalizations;

    final supplierRows = _computeSupplierPoRows(versements);
    final totalDelivery = supplierRows.fold(0.0, (s, r) => s + r.delivery);
    final accountRows = _buildMfiAccountDetailRows(pl);
    final totalChargesCommission = accountRows.fold(0.0, (s, r) => s + r.amount);

    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.zero,
        build: (context) => [
          pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildMarketFinanceInvoiceTitle(logoBytes, headerFonts, pl),
                pw.SizedBox(height: 12),
                _buildMfiInfoBlock(partner, supplierRows.length, pl),
                pw.SizedBox(height: 16),
                _buildMfiPurchaseOrderTable(partner.id, supplierRows, pl),
                pw.SizedBox(height: 16),
                _buildMfiAccountDetailsTable(accountRows, pl),
                pw.SizedBox(height: 16),
                _buildMfiResumerDuClient(
                  totalDelivery: totalDelivery,
                  totalChargesCommission: totalChargesCommission,
                  partner: partner,
                  printLocalizations: pl,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Ligne Purchase Order par fournisseur: P.O.="-", Supplier (depuis Items), P.O.Amount, Delivery (items reçus), Deposit=0, Balance=P.O.Amount-Delivery.
  /// Les fournisseurs viennent des items (Items.supplierId / Items.supplierName), pas de Achat.
  static List<({String supplierName, double poAmount, double delivery, double balance})> _computeSupplierPoRows(List<Versement> versements) {
    final map = <String, ({String supplierName, double poAmount, double delivery})>{};
    for (final v in versements) {
      final rate = v.tauxUtilise ?? 1.0;
      for (final achat in (v.achats ?? [])) {
        for (final item in (achat.items ?? [])) {
          final supplierKey = '${item.supplierId ?? 0}_${item.supplierName ?? "Inconnu"}';
          final supplierName = (item.supplierName?.trim().isEmpty == true || item.supplierName == null) ? 'Inconnu' : item.supplierName!;
          final itemAmount = item.totalPriceCNY ?? ((item.totalPrice ?? 0) * rate);
          final isReceived = item.receivedAt != null;
          final prev = map[supplierKey];
          if (prev == null) {
            map[supplierKey] = (
              supplierName: supplierName,
              poAmount: itemAmount,
              delivery: isReceived ? itemAmount : 0.0,
            );
          } else {
            map[supplierKey] = (
              supplierName: prev.supplierName,
              poAmount: prev.poAmount + itemAmount,
              delivery: prev.delivery + (isReceived ? itemAmount : 0.0),
            );
          }
        }
      }
    }
    return map.values.map((v) => (
      supplierName: v.supplierName,
      poAmount: v.poAmount,
      delivery: v.delivery,
      balance: v.poAmount - v.delivery,
    )).toList();
  }

  static pw.Widget _buildMarketFinanceInvoiceTitle(
      Uint8List logoBytes, PdfHeaderFonts headerFonts, PrintLocalizations pl) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfHeader.build(logoBytes, headerFonts),
        pw.SizedBox(height: 16),
        pw.Text(
          pl.translate('mfi_title'),
          style: PrintStyles.mainTitleStyle(),
        ),
      ],
    );
  }

  static pw.Widget _buildMfiInfoBlock(Partner partner, int totalPurchaseOrder, PrintLocalizations pl) {
    final invoiceDate = _invoiceDateFormat.format(DateTime.now());
    final customerName = '${partner.firstName} ${partner.lastName}'.trim();

    return pw.Container(
      decoration: pw.BoxDecoration(border: PrintStyles.tableBorder),
      child: pw.Column(
        children: [
          pw.Container(
            decoration: pw.BoxDecoration(color: PrintStyles.tableHeaderBackground),
            padding: pw.EdgeInsets.symmetric(
                vertical: PrintStyles.cellPaddingV,
                horizontal: PrintStyles.cellPaddingH),
            child: pw.Row(
              children: [
                _mfiInfoCell(pl.translate('mfi_invoice_no'), '${partner.id}'),
                _mfiInfoCell(pl.translate('mfi_invoice_date'), invoiceDate),
                _mfiInfoCell(pl.translate('mfi_customer_register_no'), '${partner.id}'),
              ],
            ),
          ),
          pw.Container(
            decoration: pw.BoxDecoration(color: PdfColors.white),
            padding: pw.EdgeInsets.symmetric(
                vertical: PrintStyles.cellPaddingV,
                horizontal: PrintStyles.cellPaddingH),
            child: pw.Row(
              children: [
                _mfiInfoCell(pl.translate('mfi_customer_name'), customerName),
                _mfiInfoCell(pl.translate('mfi_currency'), 'CNY'),
                _mfiInfoCell(pl.translate('mfi_exchange_rate'), '1.00'),
                _mfiInfoCell(pl.translate('mfi_total_purchase_order'), '$totalPurchaseOrder'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _mfiInfoCell(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: PrintStyles.labelStyle()),
          pw.SizedBox(height: 2),
          pw.Text(value, style: PrintStyles.cellTextStyle()),
        ],
      ),
    );
  }

  static pw.Widget _buildMfiPurchaseOrderTable(
    int regNo,
    List<({String supplierName, double poAmount, double delivery, double balance})> supplierRows,
    PrintLocalizations pl,
  ) {
    final headers = [
      pl.translate('mfi_reg_no'),
      pl.translate('mfi_po'),
      pl.translate('mfi_supplier'),
      pl.translate('mfi_po_amount'),
      pl.translate('mfi_delivery'),
      pl.translate('mfi_deposit'),
      pl.translate('mfi_balance'),
    ];
    final totalPo = supplierRows.fold(0.0, (s, r) => s + r.poAmount);
    final totalDelivery = supplierRows.fold(0.0, (s, r) => s + r.delivery);
    const totalDeposit = 0.0;
    final totalBalance = supplierRows.fold(0.0, (s, r) => s + r.balance);

    return pw.Container(
      decoration: pw.BoxDecoration(border: PrintStyles.tableBorder),
      child: pw.Column(
        children: [
          pw.Container(
            decoration: pw.BoxDecoration(color: PrintStyles.tableHeaderBackground),
            padding: pw.EdgeInsets.symmetric(
                vertical: PrintStyles.cellPaddingV,
                horizontal: PrintStyles.cellPaddingH),
            child: pw.Row(
              children: headers.map((h) => pw.Expanded(child: pw.Text(h, style: PrintStyles.tableHeaderStyle()))).toList(),
            ),
          ),
          for (int i = 0; i < supplierRows.length; i++) ...[
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border(bottom: PrintStyles.tableBorderSide),
              ),
              padding: pw.EdgeInsets.symmetric(
                  vertical: PrintStyles.cellPaddingV,
                  horizontal: PrintStyles.cellPaddingH),
              child: pw.Row(
                children: [
                  pw.Expanded(child: pw.Text('$regNo', style: PrintStyles.cellTextStyle())),
                  pw.Expanded(child: pw.Text('-', style: PrintStyles.cellTextStyle())),
                  pw.Expanded(child: pw.Text(supplierRows[i].supplierName, style: PrintStyles.cellTextStyle())),
                  pw.Expanded(child: pw.Text(NumberFormat('#,##0.00').format(supplierRows[i].poAmount), style: PrintStyles.cellTextStyle(), textAlign: pw.TextAlign.right)),
                  pw.Expanded(child: pw.Text(NumberFormat('#,##0.00').format(supplierRows[i].delivery), style: PrintStyles.cellTextStyle(), textAlign: pw.TextAlign.right)),
                  pw.Expanded(child: pw.Text('0.00', style: PrintStyles.cellTextStyle(), textAlign: pw.TextAlign.right)),
                  pw.Expanded(child: pw.Text(NumberFormat('#,##0.00').format(supplierRows[i].balance), style: PrintStyles.cellTextStyle(), textAlign: pw.TextAlign.right)),
                ],
              ),
            ),
          ],
          pw.Container(
            decoration: pw.BoxDecoration(color: PrintStyles.tableHeaderBackground),
            padding: pw.EdgeInsets.symmetric(
                vertical: PrintStyles.cellPaddingV,
                horizontal: PrintStyles.cellPaddingH),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Text(pl.translate('pdf_total'), style: PrintStyles.tableHeaderStyle())),
                pw.Expanded(child: pw.SizedBox()),
                pw.Expanded(child: pw.SizedBox()),
                pw.Expanded(child: pw.Text(NumberFormat('#,##0.00').format(totalPo), style: PrintStyles.tableHeaderStyle(), textAlign: pw.TextAlign.right)),
                pw.Expanded(child: pw.Text(NumberFormat('#,##0.00').format(totalDelivery), style: PrintStyles.tableHeaderStyle(), textAlign: pw.TextAlign.right)),
                pw.Expanded(child: pw.Text(NumberFormat('#,##0.00').format(totalDeposit), style: PrintStyles.tableHeaderStyle(), textAlign: pw.TextAlign.right)),
                pw.Expanded(child: pw.Text(NumberFormat('#,##0.00').format(totalBalance), style: PrintStyles.tableHeaderStyle(), textAlign: pw.TextAlign.right)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMfiAccountDetailsTable(
    List<({String name, String remarks, String rate, String addLess, double amount})> rows,
    PrintLocalizations pl,
  ) {
    final headers = [
      pl.translate('mfi_account_name'),
      pl.translate('mfi_remarks'),
      pl.translate('mfi_rate'),
      pl.translate('mfi_add_less'),
      pl.translate('mfi_amount'),
    ];
    final totalAmount = rows.fold(0.0, (s, r) => s + r.amount);
    final lightGreen = PrintStyles.tableHeaderBackground; // vert clair comme dans l'image

    return pw.Container(
      decoration: pw.BoxDecoration(border: PrintStyles.tableBorder),
      child: pw.Column(
        children: [
          pw.Container(
            decoration: pw.BoxDecoration(color: PrintStyles.tableHeaderBackground),
            padding: pw.EdgeInsets.symmetric(
                vertical: PrintStyles.cellPaddingV,
                horizontal: PrintStyles.cellPaddingH),
            child: pw.Row(
              children: headers.map((h) => pw.Expanded(child: pw.Text(h, style: PrintStyles.tableHeaderStyle()))).toList(),
            ),
          ),
          for (int i = 0; i < rows.length; i++) ...[
            pw.Container(
              decoration: pw.BoxDecoration(
                color: i.isEven ? lightGreen : PdfColors.white,
                border: pw.Border(bottom: PrintStyles.tableBorderSide),
              ),
              padding: pw.EdgeInsets.symmetric(
                  vertical: PrintStyles.cellPaddingV,
                  horizontal: PrintStyles.cellPaddingH),
              child: pw.Row(
                children: [
                  pw.Expanded(child: pw.Text(rows[i].name, style: PrintStyles.cellTextStyle())),
                  pw.Expanded(child: pw.Text(rows[i].remarks, style: PrintStyles.cellTextStyle())),
                  pw.Expanded(child: pw.Text(rows[i].rate, style: PrintStyles.cellTextStyle())),
                  pw.Expanded(child: pw.Text(rows[i].addLess, style: PrintStyles.cellTextStyle())),
                  pw.Expanded(child: pw.Text(NumberFormat('#,##0.00').format(rows[i].amount), style: PrintStyles.cellTextStyle(), textAlign: pw.TextAlign.right)),
                ],
              ),
            ),
          ],
          pw.Container(
            decoration: pw.BoxDecoration(color: PrintStyles.tableHeaderBackground),
            padding: pw.EdgeInsets.symmetric(
                vertical: PrintStyles.cellPaddingV,
                horizontal: PrintStyles.cellPaddingH),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Text(pl.translate('pdf_total'), style: PrintStyles.tableHeaderStyle())),
                pw.Expanded(flex: 3, child: pw.SizedBox()),
                pw.Expanded(child: pw.Text(NumberFormat('#,##0.00').format(totalAmount), style: PrintStyles.tableHeaderStyle(), textAlign: pw.TextAlign.right)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Noms des charges comme dans l'image, traduits selon la langue d'impression.
  static List<({String name, String remarks, String rate, String addLess, double amount})> _buildMfiAccountDetailRows(PrintLocalizations pl) {
    return [
      (name: pl.translate('mfi_commission_income'), remarks: '', rate: '0.00', addLess: '+', amount: 0.0),
      (name: pl.translate('mfi_sea_freight_account'), remarks: '', rate: '0.00', addLess: '+', amount: 0.0),
      (name: pl.translate('mfi_others_expense_divers'), remarks: '', rate: '0.00', addLess: '+', amount: 0.0),
      (name: pl.translate('mfi_sea_freight_account'), remarks: '', rate: '0.00', addLess: '+', amount: 0.0),
      (name: pl.translate('mfi_over_weight_charge_expenses'), remarks: '', rate: '0.00', addLess: '+', amount: 0.0),
      (name: pl.translate('mfi_others_expense_divers'), remarks: '', rate: '0.00', addLess: '+', amount: 0.0),
    ];
  }

  static pw.Widget _buildMfiResumerDuClient({
    required double totalDelivery,
    required double totalChargesCommission,
    required Partner partner,
    required PrintLocalizations printLocalizations,
  }) {
    final pl = printLocalizations;
    final a = totalDelivery;
    final b = 0.0;
    final c = a - b;
    final d = totalChargesCommission;
    final e = c + d;
    final f = 0.0;
    final g = partner.balance ?? 0.0;
    final balanceAmount = e - f + g;

    final fmt = NumberFormat('#,##0.00');
    final rows = <({String label, String value, PdfColor bgColor})>[
      (label: pl.translate('mfi_total_delivery_amount_a'), value: fmt.format(a), bgColor: PdfColors.white),
      (label: pl.translate('mfi_less_customer_paid_deposit_b'), value: fmt.format(b), bgColor: PdfColors.white),
      (label: pl.translate('mfi_payable_delivery_amount_c'), value: fmt.format(c), bgColor: PdfColors.white),
      (label: pl.translate('mfi_add_charges_commission_d'), value: fmt.format(d), bgColor: PdfColors.white),
      (label: pl.translate('mfi_invoice_amount_e'), value: fmt.format(e), bgColor: PrintStyles.invoiceAmountHighlight),
      (label: pl.translate('mfi_less_money_received_f'), value: fmt.format(f), bgColor: PrintStyles.moneyReceivedHighlight),
      (label: pl.translate('mfi_previous_mf_balance_g'), value: fmt.format(g), bgColor: PdfColors.white),
      (label: pl.translate('mfi_balance_amount'), value: fmt.format(balanceAmount), bgColor: PdfColors.white),
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(border: PrintStyles.tableBorder),
      child: pw.Column(
        children: [
          pw.Container(
            decoration: pw.BoxDecoration(color: PrintStyles.tableHeaderBackground),
            padding: pw.EdgeInsets.symmetric(
                vertical: PrintStyles.cellPaddingV,
                horizontal: PrintStyles.cellPaddingH),
            child: pw.Text(pl.translate('mfi_resumer_du_client'), style: PrintStyles.sectionTitleStyle()),
          ),
          for (final r in rows)
            pw.Container(
              decoration: pw.BoxDecoration(
                color: r.bgColor,
                border: pw.Border(bottom: PrintStyles.tableBorderSide),
              ),
              padding: pw.EdgeInsets.symmetric(
                  vertical: PrintStyles.cellPaddingV,
                  horizontal: PrintStyles.cellPaddingH),
              child: pw.Row(
                children: [
                  pw.Expanded(child: pw.Text(r.label, style: PrintStyles.cellTextStyle())),
                  pw.Container(width: 100, child: pw.Text(r.value, style: PrintStyles.cellTextStyle(), textAlign: pw.TextAlign.right)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static List<Versement> _filterVersements(
      List<Versement>? versements, DateTimeRange? range) {
    if (versements == null) return [];
    if (range == null) return versements;
    return versements.where((v) {
      final date = v.createdAt ?? DateTime(1900);
      return date.isAfter(range.start) && date.isBefore(range.end);
    }).toList();
  }

  static List<Packages> _filterPackages(
      List<Packages>? packages, DateTimeRange? range) {
    if (packages == null) return [];
    if (range == null) return packages;
    return packages.where((p) {
      final date = p.startDate ?? DateTime(1900);
      return date.isAfter(range.start) && date.isBefore(range.end);
    }).toList();
  }

  static pw.Widget _buildHeader(Uint8List logoBytes, PdfHeaderFonts headerFonts,
      DateTimeRange? dateRange, PrintLocalizations printLocalizations) {
    final font = printLocalizations.language.code == 'zh'
        ? pw.Font.courier()
        : pw.Font.helvetica();
    final fallbackFonts = [pw.Font.times(), pw.Font.courier()];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfHeader.build(logoBytes, headerFonts),
        pw.SizedBox(height: 20),

        // Titre du rapport
        pw.Text(
          printLocalizations.translate('pdf_client_status'),
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1A1E49'),
            letterSpacing: 1.2,
            font: font,
            fontFallback: fallbackFonts,
          ),
        ),
        pw.SizedBox(height: 8),

        // Période
        pw.Text(
          dateRange == null
              ? printLocalizations.translate('pdf_all_periods')
              : printLocalizations
                  .translate('pdf_from_to')
                  .replaceAll('{start}', _dateFormat.format(dateRange.start))
                  .replaceAll('{end}', _dateFormat.format(dateRange.end)),
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.black,
            font: font,
            fontFallback: fallbackFonts,
          ),
        ),
        pw.SizedBox(height: 16),
      ],
    );
  }

  static pw.Widget _buildClientInfoSection(
      Partner partner, PrintLocalizations printLocalizations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(printLocalizations.translate('pdf_client_information'),
            style: PrintStyles.sectionTitleStyle()),
        pw.SizedBox(height: 6),
        pw.Container(
          decoration: pw.BoxDecoration(border: PrintStyles.tableBorder),
          child: pw.Column(
            children: [
              // Header row
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PrintStyles.tableHeaderBackground,
                ),
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                        child: pw.Text('Champ',
                            style: PrintStyles.tableHeaderStyle())),
                    pw.Expanded(
                        child: pw.Text('Valeur',
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.right)),
                  ],
                ),
              ),
              _buildInfoGridRow(printLocalizations.translate('pdf_name'),
                  '${partner.firstName} ${partner.lastName}'),
              if (partner.phoneNumber.isNotEmpty)
                _buildInfoGridRow(printLocalizations.translate('pdf_phone'),
                    partner.phoneNumber),
              if (partner.email.isNotEmpty)
                _buildInfoGridRow(
                    printLocalizations.translate('pdf_email'), partner.email),
              if (partner.adresse.isNotEmpty)
                _buildInfoGridRow(printLocalizations.translate('pdf_address'),
                    partner.adresse),
              _buildInfoGridRow(
                  printLocalizations.translate('pdf_account_type'),
                  partner.accountType),
              _buildInfoGridRow(printLocalizations.translate('pdf_balance'),
                  partner.balance?.toStringAsFixed(2) ?? '0.00'),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoGridRow(String label, String value) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: PrintStyles.tableBorderSide),
        color: PdfColors.white,
      ),
      padding: pw.EdgeInsets.symmetric(
          vertical: PrintStyles.cellPaddingV,
          horizontal: PrintStyles.cellPaddingH),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: PrintStyles.labelStyle())),
          pw.Expanded(
              child: pw.Text(value,
                  style: PrintStyles.cellTextStyle(
                      fontSize: PrintStyles.labelFontSize),
                  textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }

  static pw.Widget _buildSummarySection(
    List<Versement> versements,
    List<Packages> packages,
    List<CashWithdrawal> depenses,
    PrintLocalizations printLocalizations,
  ) {
    // Calculer les totaux en CNY
    final totalVersementsCNY = versements.fold<double>(0, (sum, v) {
      final montantCNY =
          v.montantCNY ?? ((v.montantVerser ?? 0) * (v.tauxUtilise ?? 1.0));
      return sum + montantCNY;
    });

    final totalDepensesCNY = depenses.fold<double>(0, (sum, d) {
      final rate = d.versement.tauxUtilise ?? 1.0;
      return sum + (d.montant * rate);
    });

    final balanceCNY = totalVersementsCNY - totalDepensesCNY;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(printLocalizations.translate('pdf_summary'),
            style: PrintStyles.sectionTitleStyle()),
        pw.SizedBox(height: 6),
        pw.Container(
          decoration: pw.BoxDecoration(border: PrintStyles.tableBorder),
          child: pw.Column(
            children: [
              // Header row
              pw.Container(
                decoration:
                    pw.BoxDecoration(color: PrintStyles.tableHeaderBackground),
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                        child: pw.Text(
                            printLocalizations.translate('pdf_category'),
                            style: PrintStyles.tableHeaderStyle())),
                    pw.Container(
                        width: 120,
                        child: pw.Text(
                            printLocalizations.translate('pdf_amount'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.right)),
                  ],
                ),
              ),
              _buildSummaryRow(
                  '${printLocalizations.translate('pdf_total_versements')} (CNY)',
                  _currencyFormat.format(totalVersementsCNY),
                  PdfColors.white),
              _buildSummaryRow(
                  '${printLocalizations.translate('pdf_total_retraits')} (CNY)',
                  _currencyFormat.format(totalDepensesCNY),
                  PdfColors.white),
              _buildSummaryRow(
                  printLocalizations.translate('pdf_packages_count'),
                  '${packages.length}',
                  PdfColors.white),
              // Balance row with accent color
              _buildSummaryRow(
                  'Balance (CNY)',
                  _currencyFormat.format(balanceCNY),
                  PrintStyles.totalRowBackground,
                  bold: true),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(
      String label, String value, PdfColor bgColor,
      {bool bold = false}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: PrintStyles.tableBorderSide),
        color: bgColor,
      ),
      padding: pw.EdgeInsets.symmetric(
          vertical: PrintStyles.cellPaddingV,
          horizontal: PrintStyles.cellPaddingH),
      child: pw.Row(
        children: [
          pw.Expanded(
              child: pw.Text(label,
                  style: bold
                      ? pw.TextStyle(
                          fontSize: PrintStyles.tableFontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: PrintStyles.accentColor)
                      : PrintStyles.cellTextStyle())),
          pw.Container(
              width: 120,
              child: pw.Text(value,
                  style: bold
                      ? pw.TextStyle(
                          fontSize: PrintStyles.tableFontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: PrintStyles.accentColor)
                      : PrintStyles.cellTextStyle(),
                  textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }

  static pw.Widget _buildVersementsSection(
      List<Versement> versements, PrintLocalizations printLocalizations) {
    // Calculer le total en CNY
    final totalVersCNY = versements.fold<double>(0, (sum, v) {
      final montantCNY =
          v.montantCNY ?? ((v.montantVerser ?? 0) * (v.tauxUtilise ?? 1.0));
      return sum + montantCNY;
    });

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(printLocalizations.translate('pdf_versements'),
            style: PrintStyles.sectionTitleStyle()),
        pw.SizedBox(height: 6),
        pw.Container(
          decoration: pw.BoxDecoration(border: PrintStyles.tableBorder),
          child: pw.Column(
            children: [
              // Header row
              pw.Container(
                decoration:
                    pw.BoxDecoration(color: PrintStyles.tableHeaderBackground),
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  children: [
                    pw.Container(
                        width: 70,
                        child: pw.Text(printLocalizations.translate('pdf_date'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 4),
                    pw.Expanded(
                        child: pw.Text(
                            printLocalizations.translate('pdf_reference'),
                            style: PrintStyles.tableHeaderStyle())),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width:
                            75, // Légèrement plus large pour accommoder le code devise
                        child: pw.Text(
                            printLocalizations.translate('pdf_amount_paid'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 40,
                        child: pw.Text('Taux',
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 50,
                        child: pw.Text(printLocalizations.translate('pdf_type'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 80, // Plus large pour le double affichage CNY
                        child: pw.Text(
                            printLocalizations
                                .translate('pdf_remaining_amount'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                  ],
                ),
              ),
              // Data rows
              for (final v in versements)
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border(bottom: PrintStyles.tableBorderSide),
                  ),
                  padding: pw.EdgeInsets.symmetric(
                      vertical: PrintStyles.cellPaddingV,
                      horizontal: PrintStyles.cellPaddingH),
                  child: pw.Row(
                    children: [
                      pw.Container(
                          width: 70,
                          child: pw.Text(
                            _dateFormat.format(v.createdAt ?? DateTime.now()),
                            style: PrintStyles.cellTextStyle(),
                            textAlign: pw.TextAlign.center,
                          )),
                      pw.SizedBox(width: 4),
                      pw.Expanded(
                          child: pw.Text(
                        v.reference ?? '-',
                        style: PrintStyles.cellTextStyle(),
                        maxLines: 2,
                      )),
                      pw.SizedBox(width: 4),
                      pw.Container(
                          width: 75,
                          child: pw.Text(
                            '${NumberFormat('#,##0.00').format(v.montantVerser ?? 0)} ${v.deviseCode ?? ""}',
                            style: PrintStyles.cellTextStyle(),
                            textAlign: pw.TextAlign.center,
                          )),
                      pw.SizedBox(width: 4),
                      pw.Container(
                          width: 40,
                          child: pw.Text(
                            v.tauxUtilise?.toStringAsFixed(2) ?? '-',
                            style: PrintStyles.cellTextStyle(),
                            textAlign: pw.TextAlign.center,
                          )),
                      pw.SizedBox(width: 4),
                      pw.Container(
                          width: 50,
                          child: pw.Text(
                            v.type ?? '-',
                            style: PrintStyles.cellTextStyle(),
                            textAlign: pw.TextAlign.center,
                            maxLines: 2,
                          )),
                      pw.SizedBox(width: 4),
                      pw.Container(
                          width: 80,
                          child: pw.Column(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text(
                                '${NumberFormat('#,##0.00').format(v.montantRestant ?? 0)} ${v.deviseCode ?? ""}',
                                style: PrintStyles.cellTextStyle(),
                                textAlign: pw.TextAlign.center,
                              ),
                              if ((v.deviseCode ?? '').toUpperCase() != 'CNY')
                                pw.Text(
                                  '(${_currencyFormat.format((v.montantRestant ?? 0) * (v.tauxUtilise ?? 1.0))})',
                                  style: PrintStyles.cellTextStyle().copyWith(
                                    fontSize: 7,
                                    color: PdfColors.grey700,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                            ],
                          )),
                    ],
                  ),
                ),
              // Total row
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PrintStyles.totalRowBackground,
                  border: pw.Border(bottom: PrintStyles.tableBorderSide),
                ),
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                        child: pw.Text(
                      '${printLocalizations.translate('pdf_total')} (CNY)',
                      style: pw.TextStyle(
                          fontSize: PrintStyles.tableFontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: PrintStyles.accentColor),
                    )),
                    pw.Container(
                        width: 80,
                        child: pw.Text(
                          _currencyFormat.format(totalVersCNY),
                          style: pw.TextStyle(
                              fontSize: PrintStyles.tableFontSize,
                              fontWeight: pw.FontWeight.bold,
                              color: PrintStyles.accentColor),
                          textAlign: pw.TextAlign.center,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Section Dépenses (cash withdrawals)
  static pw.Widget _buildDepensesSection(
      List<CashWithdrawal> depenses, PrintLocalizations printLocalizations) {
    // Calculer le total en CNY
    final totalDepCNY = depenses.fold<double>(0, (sum, d) {
      final rate = d.versement.tauxUtilise ?? 1.0;
      return sum + (d.montant * rate);
    });

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(printLocalizations.translate('pdf_total_retraits'),
            style: PrintStyles.sectionTitleStyle()),
        pw.SizedBox(height: 6),
        pw.Container(
          decoration: pw.BoxDecoration(border: PrintStyles.tableBorder),
          child: pw.Column(
            children: [
              // Header row
              pw.Container(
                decoration:
                    pw.BoxDecoration(color: PrintStyles.tableHeaderBackground),
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  children: [
                    pw.Container(
                        width: 70,
                        child: pw.Text(printLocalizations.translate('pdf_date'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 4),
                    pw.Expanded(
                        child: pw.Text('Note',
                            style: PrintStyles.tableHeaderStyle())),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 40,
                        child: pw.Text('Devise',
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 80,
                        child: pw.Text(
                            printLocalizations.translate('pdf_amount'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.right)),
                  ],
                ),
              ),
              // Data rows
              for (final d in depenses)
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border(bottom: PrintStyles.tableBorderSide),
                  ),
                  padding: pw.EdgeInsets.symmetric(
                      vertical: PrintStyles.cellPaddingV,
                      horizontal: PrintStyles.cellPaddingH),
                  child: pw.Row(
                    children: [
                      pw.Container(
                          width: 70,
                          child: pw.Text(
                            d.dateRetrait != null
                                ? _dateFormat.format(d.dateRetrait!)
                                : '-',
                            style: PrintStyles.cellTextStyle(),
                            textAlign: pw.TextAlign.center,
                          )),
                      pw.SizedBox(width: 4),
                      pw.Expanded(
                          child: pw.Text(
                        d.note ?? '-',
                        style: PrintStyles.cellTextStyle(),
                        maxLines: 2,
                      )),
                      pw.SizedBox(width: 4),
                      pw.Container(
                          width: 40,
                          child: pw.Text(
                            d.devise.code,
                            style: PrintStyles.cellTextStyle(),
                            textAlign: pw.TextAlign.center,
                          )),
                      pw.SizedBox(width: 4),
                      pw.Container(
                          width: 80,
                          child: pw.Text(
                            NumberFormat('#,##0.00').format(d.montant),
                            style: PrintStyles.cellTextStyle(),
                            textAlign: pw.TextAlign.right,
                          )),
                    ],
                  ),
                ),
              // Total row
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PrintStyles.summaryRowBackground,
                  border: pw.Border(bottom: PrintStyles.tableBorderSide),
                ),
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                        child: pw.Text(
                      '${printLocalizations.translate('pdf_total')} (CNY)',
                      style: pw.TextStyle(
                          fontSize: PrintStyles.tableFontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: PrintStyles.accentColor),
                    )),
                    pw.Container(
                        width: 80,
                        child: pw.Text(
                          _currencyFormat.format(totalDepCNY),
                          style: pw.TextStyle(
                              fontSize: PrintStyles.tableFontSize,
                              fontWeight: pw.FontWeight.bold,
                              color: PrintStyles.accentColor),
                          textAlign: pw.TextAlign.right,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPackagesSection(
      List<Packages> packages, PrintLocalizations printLocalizations) {
    final font = printLocalizations.language.code == 'zh'
        ? pw.Font.courier()
        : pw.Font.helvetica();
    final fallbackFonts = [pw.Font.times(), pw.Font.courier()];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(printLocalizations.translate('pdf_packages'),
            style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1A1E49'),
                font: font,
                fontFallback: fallbackFonts)),
        pw.SizedBox(height: 8),
        for (final package in packages) ...[
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text('${package.ref}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(width: 10),
                    pw.Text(
                        '(${_dateFormat.format(package.startDate ?? DateTime.now())})'),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text(
                        '${printLocalizations.translate('pdf_from')}: ${package.startCountry}'),
                    pw.SizedBox(width: 10),
                    pw.Text(
                        '${printLocalizations.translate('pdf_to')}: ${package.destinationCountry}'),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                    '${printLocalizations.translate('pdf_status')}: ${printLocalizations.translateStatus(package.status)}'),
                pw.SizedBox(height: 8),
                if (package.items != null && package.items!.isNotEmpty) ...[
                  // En-tête du tableau avec le même style que les produits
                  pw.Container(
                    color: PdfColor.fromHex(
                        '#E3F2FD'), // Bleu clair comme dans l'image
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 6, horizontal: 4),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                                printLocalizations.translate('pdf_article'),
                                style: pw.TextStyle(
                                    color: PdfColor.fromHex('#1A1E49'),
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8),
                                maxLines: 2)),
                        pw.SizedBox(width: 3),
                        pw.Container(
                            width: 60,
                            child: pw.Text(
                                printLocalizations.translate('pdf_quantity'),
                                style: pw.TextStyle(
                                    color: PdfColor.fromHex('#1A1E49'),
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8),
                                textAlign: pw.TextAlign.center)),
                        pw.SizedBox(width: 3),
                        pw.Container(
                            width: 70,
                            child: pw.Text(
                                printLocalizations.translate('pdf_unit_price'),
                                style: pw.TextStyle(
                                    color: PdfColor.fromHex('#1A1E49'),
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8),
                                textAlign: pw.TextAlign.center)),
                        pw.SizedBox(width: 3),
                        pw.Container(
                            width: 70,
                            child: pw.Text(
                                printLocalizations
                                    .translate('pdf_exchange_rate'),
                                style: pw.TextStyle(
                                    color: PdfColor.fromHex('#1A1E49'),
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8),
                                textAlign: pw.TextAlign.center)),
                        pw.SizedBox(width: 3),
                        pw.Container(
                            width: 70,
                            child: pw.Text(
                                printLocalizations.translate('pdf_total'),
                                style: pw.TextStyle(
                                    color: PdfColor.fromHex('#1A1E49'),
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8),
                                textAlign: pw.TextAlign.center)),
                      ],
                    ),
                  ),
                  // Corps du tableau avec le même style que les produits
                  for (final item in package.items!)
                    pw.Container(
                      color: PdfColors.white,
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 4, horizontal: 4),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                              flex: 3,
                              child: pw.Text(
                                item.description ?? '-',
                                style: const pw.TextStyle(fontSize: 8),
                                maxLines: 2,
                              )),
                          pw.SizedBox(width: 3),
                          pw.Container(
                              width: 60,
                              child: pw.Text(
                                '${item.quantity}',
                                style: const pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.center,
                              )),
                          pw.SizedBox(width: 3),
                          pw.Container(
                              width: 70,
                              child: pw.Text(
                                _currencyFormat.format(item.unitPrice ?? 0),
                                style: const pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.center,
                              )),
                          pw.SizedBox(width: 3),
                          pw.Container(
                              width: 70,
                              child: pw.Text(
                                _currencyFormat.format(item.salesRate ?? 0),
                                style: const pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.center,
                              )),
                          pw.SizedBox(width: 3),
                          pw.Container(
                              width: 70,
                              child: pw.Text(
                                _currencyFormat.format(item.totalPrice ?? 0),
                                style: const pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.center,
                              )),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildPurchasedItemsSection(
      List<Versement> versements, PrintLocalizations printLocalizations) {
    // Collect all articles from all achats within versements
    final List<
        ({
          Items item,
          String versementRef,
          String originalBalance,
          String? cnyBalance
        })> allItems = [];
    for (final versement in versements) {
      final rate = versement.tauxUtilise ?? 1.0;
      final isCNY = (versement.deviseCode ?? '').toUpperCase() == 'CNY';

      final originalBalance =
          '${NumberFormat('#,##0.00').format(versement.montantRestant ?? 0)} ${versement.deviseCode ?? ""}';
      final cnyBalance = isCNY
          ? null
          : _currencyFormat.format((versement.montantRestant ?? 0) * rate);

      for (final achat in (versement.achats ?? [])) {
        for (final item in (achat.items ?? [])) {
          final versementRef = (achat.isDebt == true ||
                  achat.referenceVersement == null ||
                  achat.referenceVersement!.isEmpty)
              ? 'Dette'
              : achat.referenceVersement!;
          allItems.add((
            item: item,
            versementRef: versementRef,
            originalBalance: originalBalance,
            cnyBalance: cnyBalance,
          ));
        }
      }
    }

    if (allItems.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(printLocalizations.translate('pdf_articles_list_label'),
            style: PrintStyles.sectionTitleStyle()),
        pw.SizedBox(height: 6),
        pw.Container(
          decoration: pw.BoxDecoration(border: PrintStyles.tableBorder),
          child: pw.Column(
            children: [
              // Header row
              pw.Container(
                decoration:
                    pw.BoxDecoration(color: PrintStyles.tableHeaderBackground),
                padding: pw.EdgeInsets.symmetric(
                    vertical: PrintStyles.cellPaddingV,
                    horizontal: PrintStyles.cellPaddingH),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                            printLocalizations.translate('pdf_product_name'),
                            style: PrintStyles.tableHeaderStyle(),
                            maxLines: 2)),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 90,
                        child: pw.Text('Ref. Versement',
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 40,
                        child: pw.Text(
                            printLocalizations.translate('pdf_quantity'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 60,
                        child: pw.Text(
                            printLocalizations.translate('pdf_unit_price'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 60,
                        child: pw.Text(
                            printLocalizations.translate('pdf_total'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center)),
                    pw.SizedBox(width: 4),
                    pw.Container(
                        width: 75, // Plus large pour le double affichage
                        child: pw.Text(
                            printLocalizations
                                .translate('pdf_remaining_amount_label'),
                            style: PrintStyles.tableHeaderStyle(),
                            textAlign: pw.TextAlign.center,
                            maxLines: 2)),
                  ],
                ),
              ),
              // Data rows
              ...allItems.map((entry) => pw.Container(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      border: pw.Border(bottom: PrintStyles.tableBorderSide),
                    ),
                    padding: pw.EdgeInsets.symmetric(
                        vertical: PrintStyles.cellPaddingV,
                        horizontal: PrintStyles.cellPaddingH),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              entry.item.description ?? '-',
                              style: PrintStyles.cellTextStyle(),
                              maxLines: 2,
                            )),
                        pw.SizedBox(width: 4),
                        pw.Container(
                            width: 90,
                            child: pw.Text(
                              entry.versementRef,
                              style: PrintStyles.cellTextStyle(),
                              textAlign: pw.TextAlign.center,
                              maxLines: 2,
                            )),
                        pw.SizedBox(width: 4),
                        pw.Container(
                            width: 40,
                            child: pw.Text(
                              '${entry.item.quantity ?? 0}',
                              style: PrintStyles.cellTextStyle(),
                              textAlign: pw.TextAlign.center,
                            )),
                        pw.SizedBox(width: 4),
                        pw.Container(
                            width: 60,
                            child: pw.Text(
                              NumberFormat('#,##0.00')
                                  .format(entry.item.unitPrice ?? 0),
                              style: PrintStyles.cellTextStyle(),
                              textAlign: pw.TextAlign.center,
                            )),
                        pw.SizedBox(width: 4),
                        pw.Container(
                            width: 60,
                            child: pw.Text(
                              NumberFormat('#,##0.00')
                                  .format(entry.item.totalPrice ?? 0),
                              style: PrintStyles.cellTextStyle(),
                              textAlign: pw.TextAlign.center,
                            )),
                        pw.SizedBox(width: 4),
                        pw.Container(
                            width: 75,
                            child: pw.Column(
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                pw.Text(
                                  entry.originalBalance,
                                  style: PrintStyles.cellTextStyle(),
                                  textAlign: pw.TextAlign.center,
                                ),
                                if (entry.cnyBalance != null)
                                  pw.Text(
                                    '(${entry.cnyBalance})',
                                    style: PrintStyles.cellTextStyle().copyWith(
                                      fontSize: 7,
                                      color: PdfColors.grey700,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                              ],
                            )),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  /// Génère un PDF avec le solde de tous les clients
  static Future<Uint8List> buildCustomersBalancePdfBytes(
    List<Partner> partners, {
    DateTimeRange? dateRange,
    required PrintLocalizations printLocalizations,
  }) async {
    final pdf = pw.Document();

    final logoBytes = await rootBundle
        .load('assets/images/logo.png')
        .then((data) => data.buffer.asUint8List());
    final headerFonts = await PdfHeader.loadFonts();

    // Calculer les données selon la règle métier
    final customerData = _calculateCustomerBalances(partners, dateRange);

    // Formater la période
    String periodText = '';
    if (dateRange != null) {
      final startMonth =
          DateFormat('MMM yyyy', 'en_US').format(dateRange.start);
      final endMonth = DateFormat('MMM yyyy', 'en_US').format(dateRange.end);
      periodText = '$startMonth - $endMonth';
    } else {
      // Si pas de période, utiliser l'année en cours
      final now = DateTime.now();
      final startMonth =
          DateFormat('MMM yyyy', 'en_US').format(DateTime(now.year, 1, 1));
      final endMonth =
          DateFormat('MMM yyyy', 'en_US').format(DateTime(now.year, 12, 31));
      periodText = '$startMonth - $endMonth';
    }

    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.zero,
        build: (context) => [
          pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildCustomersBalanceHeader(
                    logoBytes, headerFonts, printLocalizations, periodText),
                pw.SizedBox(height: 24),
                _buildCustomersBalanceTable(customerData, printLocalizations),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Génère un PDF avec le solde de tous les fournisseurs
  static Future<Uint8List> buildSuppliersBalancePdfBytes(
    List<Partner> suppliers, {
    DateTimeRange? dateRange,
    required PrintLocalizations printLocalizations,
  }) async {
    final pdf = pw.Document();

    final logoBytes = await rootBundle
        .load('assets/images/logo.png')
        .then((data) => data.buffer.asUint8List());
    final headerFonts = await PdfHeader.loadFonts();

    // Calculer les données selon la règle métier
    final supplierData = await _calculateSupplierBalances(suppliers, dateRange);

    // Formater la période
    String periodText = '';
    if (dateRange != null) {
      final startMonth =
          DateFormat('MMM yyyy', 'en_US').format(dateRange.start);
      final endMonth = DateFormat('MMM yyyy', 'en_US').format(dateRange.end);
      periodText = '$startMonth - $endMonth';
    } else {
      // Si pas de période, utiliser l'année en cours
      final now = DateTime.now();
      final startMonth =
          DateFormat('MMM yyyy', 'en_US').format(DateTime(now.year, 1, 1));
      final endMonth =
          DateFormat('MMM yyyy', 'en_US').format(DateTime(now.year, 12, 31));
      periodText = '$startMonth - $endMonth';
    }

    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.zero,
        build: (context) => [
          pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSuppliersBalanceHeader(
                    logoBytes, headerFonts, printLocalizations, periodText),
                pw.SizedBox(height: 24),
                _buildSuppliersBalanceTable(supplierData, printLocalizations),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Calcule les balances des fournisseurs selon leurs items payés
  static Future<List<SupplierBalanceData>> _calculateSupplierBalances(
      List<Partner> suppliers, DateTimeRange? dateRange) async {
    final itemServices = ItemServices();
    final List<SupplierBalanceData> supplierDataList = [];

    for (final supplier in suppliers) {
      try {
        final items = await itemServices.findItemsBySupplier(supplier.id);

        // Filtrer les items selon la période si nécessaire
        List<Items> filteredItems = items;
        if (dateRange != null) {
          filteredItems = items.where((item) {
            final paymentDate = item.paiementDate;
            if (paymentDate == null) {
              // Si pas de date de paiement, inclure si l'item existe dans la période
              // On peut utiliser la date de création de l'achat ou autre
              return true; // Pour l'instant, on inclut tous les items sans date
            }
            return paymentDate.isAfter(
                    dateRange.start.subtract(const Duration(days: 1))) &&
                paymentDate
                    .isBefore(dateRange.end.add(const Duration(days: 1)));
          }).toList();
        }

        // Calculer les totaux
        double totalPaid = filteredItems.fold(
            0.0, (sum, item) => sum + (item.amountPaid ?? 0.0));
        double totalToPay = filteredItems.fold(
            0.0, (sum, item) => sum + (item.totalPrice ?? 0.0));
        double remainingToPay = totalToPay - totalPaid;

        // Ne pas inclure les fournisseurs avec aucun montant
        if (totalPaid > 0 || remainingToPay > 0) {
          supplierDataList.add(SupplierBalanceData(
            supplierName: '${supplier.firstName} ${supplier.lastName}'.trim(),
            totalPaid: totalPaid,
            remainingToPay: remainingToPay > 0 ? remainingToPay : 0.0,
          ));
        }
      } catch (e) {
        // En cas d'erreur, ignorer ce fournisseur
        print('Error loading items for supplier ${supplier.id}: $e');
      }
    }

    return supplierDataList;
  }

  /// Construit l'en-tête pour le PDF des soldes fournisseurs
  static pw.Widget _buildSuppliersBalanceHeader(
    Uint8List logoBytes,
    PdfHeaderFonts headerFonts,
    PrintLocalizations printLocalizations,
    String periodText,
  ) {
    final font = printLocalizations.language.code == 'zh'
        ? pw.Font.courier()
        : pw.Font.helvetica();
    final fallbackFonts = [pw.Font.times(), pw.Font.courier()];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // En-tête utilisant le composant unifié PdfHeader
        PdfHeader.build(logoBytes, headerFonts),
        pw.SizedBox(height: 20),

        // Titre du rapport
        pw.Text(
          printLocalizations.translate('pdf_suppliers_balance'),
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1A1E49'),
            letterSpacing: 1.2,
            font: font,
            fontFallback: fallbackFonts,
          ),
        ),
        pw.SizedBox(height: 8),

        // Période
        pw.Text(
          periodText,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1A1E49'),
            font: font,
            fontFallback: fallbackFonts,
          ),
        ),
        pw.SizedBox(height: 16),

        // Ligne séparatrice
        pw.Container(
          height: 1,
          color: PdfColor.fromHex('#1A1E49'),
        ),
      ],
    );
  }

  /// Construit le tableau des soldes fournisseurs
  static pw.Widget _buildSuppliersBalanceTable(
    List<SupplierBalanceData> supplierData,
    PrintLocalizations printLocalizations,
  ) {
    final font = printLocalizations.language.code == 'zh'
        ? pw.Font.courier()
        : pw.Font.helvetica();
    final fallbackFonts = [pw.Font.times(), pw.Font.courier()];

    // Calculer les totaux
    double totalPaid =
        supplierData.fold(0.0, (sum, data) => sum + data.totalPaid);
    double totalRemaining =
        supplierData.fold(0.0, (sum, data) => sum + data.remainingToPay);
    double difference = totalPaid - totalRemaining;

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.black,
        width: 1,
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5), // Numéro de ligne
        1: const pw.FlexColumnWidth(3), // Nom du fournisseur
        2: const pw.FlexColumnWidth(2), // Total payé
        3: const pw.FlexColumnWidth(2), // Reste à payer
      },
      children: [
        // En-tête du tableau
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#E3F2FD'), // Bleu clair
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '', // Colonne numéro vide dans l'en-tête
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1A1E49'),
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                printLocalizations.translate('pdf_supplier_name'),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1A1E49'),
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                printLocalizations.translate('pdf_total_paid'),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1A1E49'),
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                printLocalizations.translate('pdf_remaining_to_pay'),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1A1E49'),
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        // Lignes de données
        ...supplierData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final isEven = index % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : PdfColors.grey100,
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '${index + 1}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    font: font,
                    fontFallback: fallbackFonts,
                  ),
                  textAlign: pw.TextAlign.left,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  data.supplierName,
                  style: pw.TextStyle(
                    fontSize: 9,
                    font: font,
                    fontFallback: fallbackFonts,
                  ),
                  textAlign: pw.TextAlign.left,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  data.totalPaid > 0
                      ? _currencyFormat.format(data.totalPaid)
                      : '',
                  style: pw.TextStyle(
                    fontSize: 9,
                    font: font,
                    fontFallback: fallbackFonts,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  data.remainingToPay > 0
                      ? _currencyFormat.format(data.remainingToPay)
                      : '',
                  style: pw.TextStyle(
                    fontSize: 9,
                    font: font,
                    fontFallback: fallbackFonts,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          );
        }),
        // Ligne Total
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color:
                PdfColor.fromHex('#F5F5F5'), // Gris clair pour la ligne Total
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '',
                style: pw.TextStyle(
                  fontSize: 10,
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                printLocalizations.translate('pdf_total'),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                _currencyFormat.format(totalPaid),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                _currencyFormat.format(totalRemaining),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        // Ligne Différence finale (Équilibrer)
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.lightBlue,
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '',
                style: pw.TextStyle(
                  fontSize: 10,
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                printLocalizations.translate('pdf_balance_difference'),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                _currencyFormat.format(difference),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '',
                style: pw.TextStyle(
                  fontSize: 10,
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static List<CustomerBalanceData> _calculateCustomerBalances(
      List<Partner> partners, DateTimeRange? dateRange) {
    return partners.where((partner) {
      // Filtrer les clients avec balance = 0 ou null
      final balance = partner.balance ?? 0.0;
      if (balance == 0.0) return false;

      // Si une période est spécifiée, filtrer selon les versements dans cette période
      if (dateRange != null) {
        final versements = partner.versements ?? [];
        // Vérifier si le client a des versements dans la période
        final hasVersementsInPeriod = versements.any((versement) {
          final versementDate = versement.createdAt ?? DateTime(1900);
          return versementDate
                  .isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
              versementDate
                  .isBefore(dateRange.end.add(const Duration(days: 1)));
        });
        return hasVersementsInPeriod;
      }

      // Si pas de période (all data), inclure tous les clients avec balance != 0
      return true;
    }).map((partner) {
      final balance = partner.balance ?? 0.0;
      final customerName = '${partner.firstName} ${partner.lastName}'.trim();

      if (balance < 0) {
        return CustomerBalanceData(
          customerName: customerName,
          receivable: balance.abs(),
          payable: 0.0,
        );
      } else {
        return CustomerBalanceData(
          customerName: customerName,
          receivable: 0.0,
          payable: balance,
        );
      }
    }).toList();
  }

  /// Construit l'en-tête pour le PDF des soldes clients
  static pw.Widget _buildCustomersBalanceHeader(
    Uint8List logoBytes,
    PdfHeaderFonts headerFonts,
    PrintLocalizations printLocalizations,
    String periodText,
  ) {
    final font = printLocalizations.language.code == 'zh'
        ? pw.Font.courier()
        : pw.Font.helvetica();
    final fallbackFonts = [pw.Font.times(), pw.Font.courier()];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // En-tête utilisant le composant unifié PdfHeader
        PdfHeader.build(logoBytes, headerFonts),
        pw.SizedBox(height: 20),

        // Titre du rapport
        pw.Text(
          printLocalizations.translate('pdf_customers_balance'),
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1A1E49'),
            letterSpacing: 1.2,
            font: font,
            fontFallback: fallbackFonts,
          ),
        ),
        pw.SizedBox(height: 8),

        // Période
        pw.Text(
          periodText,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1A1E49'),
            font: font,
            fontFallback: fallbackFonts,
          ),
        ),
        pw.SizedBox(height: 16),

        // Ligne séparatrice
        pw.Container(
          height: 1,
          color: PdfColor.fromHex('#1A1E49'),
        ),
      ],
    );
  }

  /// Construit le tableau des soldes clients
  static pw.Widget _buildCustomersBalanceTable(
    List<CustomerBalanceData> customerData,
    PrintLocalizations printLocalizations,
  ) {
    final font = printLocalizations.language.code == 'zh'
        ? pw.Font.courier()
        : pw.Font.helvetica();
    final fallbackFonts = [pw.Font.times(), pw.Font.courier()];

    // Calculer les totaux
    double totalReceivable =
        customerData.fold(0.0, (sum, data) => sum + data.receivable);
    double totalPayable =
        customerData.fold(0.0, (sum, data) => sum + data.payable);
    double difference = totalReceivable - totalPayable;

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.black,
        width: 1,
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5), // Numéro de ligne
        1: const pw.FlexColumnWidth(3), // Nom du client
        2: const pw.FlexColumnWidth(2), // Recevable
        3: const pw.FlexColumnWidth(2), // Payable
      },
      children: [
        // En-tête du tableau
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#E3F2FD'), // Bleu clair
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '', // Colonne numéro vide dans l'en-tête
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1A1E49'),
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                printLocalizations.translate('pdf_customer_name'),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1A1E49'),
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                printLocalizations.translate('pdf_receivable_dr'),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1A1E49'),
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                printLocalizations.translate('pdf_payable_cr'),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1A1E49'),
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        // Lignes de données
        ...customerData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final isEven = index % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : PdfColors.grey100,
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '${index + 1}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    font: font,
                    fontFallback: fallbackFonts,
                  ),
                  textAlign: pw.TextAlign.left,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  data.customerName,
                  style: pw.TextStyle(
                    fontSize: 9,
                    font: font,
                    fontFallback: fallbackFonts,
                  ),
                  textAlign: pw.TextAlign.left,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  data.receivable > 0
                      ? _currencyFormat.format(data.receivable)
                      : '',
                  style: pw.TextStyle(
                    fontSize: 9,
                    font: font,
                    fontFallback: fallbackFonts,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  data.payable > 0 ? _currencyFormat.format(data.payable) : '',
                  style: pw.TextStyle(
                    fontSize: 9,
                    font: font,
                    fontFallback: fallbackFonts,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          );
        }),
        // Ligne Total
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color:
                PdfColor.fromHex('#F5F5F5'), // Gris clair pour la ligne Total
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '',
                style: pw.TextStyle(
                  fontSize: 10,
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                printLocalizations.translate('pdf_total'),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                _currencyFormat.format(totalReceivable),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                _currencyFormat.format(totalPayable),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        // Ligne Différence finale (Équilibrer)
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.lightBlue,
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '',
                style: pw.TextStyle(
                  fontSize: 10,
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                printLocalizations.translate('pdf_balance_difference'),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                _currencyFormat.format(difference),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '',
                style: pw.TextStyle(
                  fontSize: 10,
                  font: font,
                  fontFallback: fallbackFonts,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Classe pour représenter les données de balance d'un client
class CustomerBalanceData {
  final String customerName;
  final double receivable;
  final double payable;

  CustomerBalanceData({
    required this.customerName,
    required this.receivable,
    required this.payable,
  });
}

/// Classe pour représenter les données de balance d'un fournisseur
class SupplierBalanceData {
  final String supplierName;
  final double totalPaid; // Total payé (Dr)
  final double remainingToPay; // Reste à payer (Cr)

  SupplierBalanceData({
    required this.supplierName,
    required this.totalPaid,
    required this.remainingToPay,
  });
}
