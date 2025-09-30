import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/utils/versement_print_service.dart';
import 'package:printing/printing.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/models/invoice_options.dart';
import 'package:bbd_limited/components/invoice_options_config.dart';
import 'package:intl/intl.dart';

class AchatDetailsSheet extends StatefulWidget {
  final Achat achat;

  const AchatDetailsSheet({super.key, required this.achat});

  @override
  State<AchatDetailsSheet> createState() => _AchatDetailsSheetState();
}

class _AchatDetailsSheetState extends State<AchatDetailsSheet> {
  bool isLoading = false;
  final Set<String> confirmedArticles = {};
  final AchatServices achatServices = AchatServices();

  // Ajout pour la recherche
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Options de facturation configurables
  InvoiceOptions _invoiceOptions = const InvoiceOptions();
  late NumberFormat currencyFormat;

  @override
  void initState() {
    super.initState();
    currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'CNY',
    );
  }

  void _updateInvoiceOptions(InvoiceOptions newOptions) {
    setState(() {
      _invoiceOptions = newOptions;
    });
  }

  bool get _hasActiveInvoiceOptions {
    return _invoiceOptions.enableLineMargin ||
        _invoiceOptions.enableGlobalMargin ||
        _invoiceOptions.enableDiscount ||
        _invoiceOptions.enableStorageFees;
  }

  String _formatAmount(double? amount) {
    if (amount == null) return "0,00";
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]} ',
        )
        .replaceAll('.', ',');
  }

  Future<void> confirmArticle(String itemId) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final user = await AuthService().getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context, "Utilisateur non connecté");
        return;
      }
      final result = await achatServices.confirmDelivery(
        itemIds: [int.parse(itemId)],
        userId: user.id,
      );

      if (result.isSuccess) {
        setState(() {
          confirmedArticles.add(itemId);
          // Met à jour le statut de l'article dans la liste locale
          final idx = widget.achat.items
                  ?.indexWhere((i) => i.id?.toString() == itemId) ??
              -1;
          if (idx != -1) {
            widget.achat.items![idx].status = Status.RECEIVED;
          }
        });
        showSuccessTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_item_received_success'));
      } else {
        showErrorTopSnackBar(
            context,
            result.errorMessage ??
                AppLocalizations.of(context)
                    .translate('purchase_history_confirmation_error'));
      }
    } catch (e) {
      showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('purchase_history_error_during_confirmation'));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showEditArticleDialog(Items item) async {
    final descriptionController = TextEditingController(text: item.description);
    final quantityController =
        TextEditingController(text: item.quantity?.toString() ?? '');
    final unitPriceController =
        TextEditingController(text: item.unitPrice?.toString() ?? '');
    final salesRateController =
        TextEditingController(text: item.salesRate?.toString() ?? '');
    Partner? selectedSupplier;
    List<Partner> suppliers = [];
    bool loadingSuppliers = true;
    String? errorMsg;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            if (loadingSuppliers) {
              PartnerServices().findSuppliers().then((list) {
                setStateModal(() {
                  suppliers = list;
                  if (suppliers.isNotEmpty) {
                    selectedSupplier = suppliers.firstWhere(
                      (s) => s.id == item.supplierId,
                      orElse: () => suppliers[0],
                    );
                  } else {
                    selectedSupplier = null;
                  }
                  loadingSuppliers = false;
                });
              }).catchError((e) {
                setStateModal(() {
                  errorMsg = AppLocalizations.of(context)
                      .translate('error_loading_suppliers');
                  loadingSuppliers = false;
                });
              });
            }
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: loadingSuppliers
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()))
                  : errorMsg != null
                      ? Text(errorMsg!)
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context).translate(
                                    'purchase_history_edit_item_title'),
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 30),
                              buildTextField(
                                controller: descriptionController,
                                label: AppLocalizations.of(context).translate(
                                    'purchase_history_edit_description'),
                                icon: Icons.description,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      controller: quantityController,
                                      label: AppLocalizations.of(context)
                                          .translate(
                                              'purchase_history_edit_quantity'),
                                      icon: Icons.numbers,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  Expanded(
                                    child: buildTextField(
                                      controller: unitPriceController,
                                      label: AppLocalizations.of(context)
                                          .translate(
                                              'purchase_history_edit_unit_price'),
                                      icon: Icons.attach_money,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              buildTextField(
                                controller: salesRateController,
                                label: AppLocalizations.of(context).translate(
                                    'purchase_history_edit_purchase_rate'),
                                icon: Icons.percent,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                              ),
                              const SizedBox(height: 12),
                              DropDownCustom<Partner>(
                                items: suppliers,
                                selectedItem: selectedSupplier,
                                onChanged: (val) =>
                                    setStateModal(() => selectedSupplier = val),
                                itemToString: (p) => ((p.firstName +
                                        (p.lastName.isNotEmpty
                                            ? ' ' + p.lastName
                                            : ''))
                                    .trim()),
                                hintText: AppLocalizations.of(context)
                                    .translate(
                                        'purchase_history_edit_supplier'),
                                prefixIcon: Icons.person,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(AppLocalizations.of(context)
                                          .translate(
                                              'purchase_history_edit_cancel')),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: confirmationButton(
                                      icon: Icons.save,
                                      label: AppLocalizations.of(context)
                                          .translate(
                                              'purchase_history_edit_save'),
                                      isLoading: isLoading,
                                      subLabel: '',
                                      onPressed: () async {
                                        final user =
                                            await AuthService().getUserInfo();
                                        if (user == null) {
                                          showErrorTopSnackBar(
                                              context,
                                              AppLocalizations.of(context)
                                                  .translate(
                                                      'user_not_connected'));
                                          return;
                                        }
                                        try {
                                          final updatedItem = Items(
                                            id: item.id,
                                            description:
                                                descriptionController.text,
                                            quantity: int.tryParse(
                                                quantityController.text),
                                            unitPrice: double.tryParse(
                                                unitPriceController.text),
                                            totalPrice: (int.tryParse(
                                                        quantityController
                                                            .text) ??
                                                    0) *
                                                (double.tryParse(
                                                        unitPriceController
                                                            .text) ??
                                                    0),
                                            supplierId: selectedSupplier?.id,
                                            supplierName: ((selectedSupplier
                                                                ?.firstName ??
                                                            '') +
                                                        ((selectedSupplier
                                                                        ?.lastName ??
                                                                    '')
                                                                .isNotEmpty
                                                            ? ' ' +
                                                                (selectedSupplier
                                                                        ?.lastName ??
                                                                    '')
                                                            : ''))
                                                    .trim()
                                                    .isNotEmpty
                                                ? ((selectedSupplier
                                                            ?.firstName ??
                                                        '') +
                                                    ((selectedSupplier
                                                                    ?.lastName ??
                                                                '')
                                                            .isNotEmpty
                                                        ? ' ' +
                                                            (selectedSupplier
                                                                    ?.lastName ??
                                                                '')
                                                        : ''))
                                                : null,
                                            supplierPhone:
                                                selectedSupplier?.phoneNumber,
                                            packageId: item.packageId,
                                            salesRate: double.tryParse(
                                                salesRateController.text),
                                            status: item.status,
                                          );
                                          final itemServices = ItemServices();
                                          final result =
                                              await itemServices.updateItem(
                                            itemId: item.id!,
                                            userId: user.id,
                                            clientId:
                                                widget.achat.clientId ?? 0,
                                            item: updatedItem,
                                          );
                                          if (result == 'SUCCESS') {
                                            setState(() {
                                              final idx = widget.achat.items
                                                      ?.indexWhere((i) =>
                                                          i.id == item.id) ??
                                                  -1;
                                              if (idx != -1) {
                                                widget.achat.items![idx] =
                                                    updatedItem;
                                              }
                                            });
                                            showSuccessTopSnackBar(
                                                context,
                                                AppLocalizations.of(context)
                                                    .translate(
                                                        'purchase_history_item_modified_success'));
                                            Navigator.pop(context);
                                          } else if (result ==
                                              'ITEM_NOT_FOUND') {
                                            showErrorTopSnackBar(
                                                context,
                                                AppLocalizations.of(context)
                                                    .translate(
                                                        'purchase_history_item_not_found'));
                                          } else if (result ==
                                              'USER_NOT_FOUND') {
                                            showErrorTopSnackBar(
                                                context,
                                                AppLocalizations.of(context)
                                                    .translate(
                                                        'purchase_history_user_not_found'));
                                          } else if (result ==
                                              'CLIENT_MISMATCH') {
                                            showErrorTopSnackBar(
                                                context,
                                                AppLocalizations.of(context)
                                                    .translate(
                                                        'purchase_history_client_mismatch'));
                                          } else if (result ==
                                              'SUPPLIER_NOT_FOUND') {
                                            showErrorTopSnackBar(
                                                context,
                                                AppLocalizations.of(context)
                                                    .translate(
                                                        'purchase_history_supplier_not_found'));
                                          } else {
                                            showErrorTopSnackBar(
                                                context,
                                                AppLocalizations.of(context)
                                                    .translate(
                                                        'purchase_history_error_occurred')
                                                    .replaceAll(
                                                        '{error}', result));
                                          }
                                        } catch (e) {
                                          showErrorTopSnackBar(
                                              context,
                                              AppLocalizations.of(context)
                                                  .translate(
                                                      'purchase_history_error_occurred')
                                                  .replaceAll(
                                                      '{error}', e.toString()));
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteArticle(Items item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange)),
            const SizedBox(width: 12),
            Text(
                AppLocalizations.of(context)
                    .translate('purchase_history_delete_confirm_title'),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(AppLocalizations.of(context)
            .translate('purchase_history_delete_confirm_message')
            .replaceAll('{description}', item.description ?? '')),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)
                .translate('purchase_history_delete_confirm_cancel')),
          ),
          TextButton(
            onPressed: () {
              _deleteArticle(item);
              Navigator.pop(context);
            },
            child: Text(
                AppLocalizations.of(context)
                    .translate('purchase_history_delete_confirm_delete'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteArticle(Items item) async {
    setState(() {
      isLoading = true;
    });
    try {
      final user = await AuthService().getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context, "Utilisateur non connecté");
        setState(() {
          isLoading = false;
        });
        return;
      }
      final itemServices = ItemServices();
      final result = await itemServices.deleteItem(
        item.id!,
        user.id,
        widget.achat.clientId ?? 0,
      );
      if (result == "DELETED") {
        setState(() {
          widget.achat.items?.remove(item);
        });
        showSuccessTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_item_deleted_success'));
        Navigator.of(context).pop(true);
      } else if (result == "ITEM_NOT_FOUND") {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_item_not_found'));
      } else if (result == "CLIENT_NOT_FOUND_OR_MISMATCH") {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_client_mismatch'));
      } else if (result == "USER_NOT_FOUND") {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_user_not_found'));
      } else {
        showErrorTopSnackBar(
            context,
            result?.toString() ??
                AppLocalizations.of(context)
                    .translate('purchase_history_unknown_error'));
      }
    } catch (e) {
      showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('purchase_history_error_during_deletion')
              .replaceAll('{error}', e.toString()));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handlePrintAchat(Achat achat) {
    bool includeSupplierInfo = false;
    bool isProforma = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // En-tête
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate('purchase_history_print_options'),
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width < 400
                                        ? 16
                                        : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Section options d'impression
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).translate(
                                  'purchase_history_invoice_options'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Option inclure infos fournisseur
                            Row(
                              children: [
                                Checkbox(
                                  value: includeSupplierInfo,
                                  onChanged: (value) {
                                    setState(() {
                                      includeSupplierInfo = value ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context).translate(
                                        'purchase_history_include_supplier'),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),

                            // Option proforma
                            Row(
                              children: [
                                Checkbox(
                                  value: isProforma,
                                  onChanged: (value) {
                                    setState(() {
                                      isProforma = value ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context).translate(
                                        'purchase_history_generate_proforma'),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Configuration des options de facturation
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.settings,
                                    size: 20, color: Color(0xFF1A1E49)),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)
                                      .translate('billing_options'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Résumé des options actives
                            if (_hasActiveInvoiceOptions) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            color: Colors.blue[700], size: 16),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            AppLocalizations.of(context)
                                                .translate(
                                                    'currently_applied_options'),
                                            style: TextStyle(
                                              color: Colors.blue[700],
                                              fontWeight: FontWeight.bold,
                                              fontSize: MediaQuery.of(context)
                                                          .size
                                                          .width <
                                                      400
                                                  ? 11
                                                  : 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInvoiceOptionsSummary(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Bouton pour configurer
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _showInvoiceOptionsDialog(context),
                                icon: const Icon(Icons.settings, size: 18),
                                label: Text(_hasActiveInvoiceOptions
                                    ? AppLocalizations.of(context)
                                        .translate('modify_options')
                                    : AppLocalizations.of(context)
                                        .translate('configure_options')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A1E49),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Boutons d'action - Responsive
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 400;
                          if (isMobile) {
                            // Layout vertical pour mobile
                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _showAchatPdfPreviewDialog(context, achat,
                                          includeSupplierInfo, isProforma);
                                    },
                                    icon: const Icon(Icons.visibility),
                                    label: Text(AppLocalizations.of(context)
                                        .translate(
                                            'purchase_history_preview_pdf')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1A1E49),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text(AppLocalizations.of(context)
                                        .translate('cancel')),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Layout horizontal pour tablette/desktop
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(AppLocalizations.of(context)
                                      .translate('cancel')),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _showAchatPdfPreviewDialog(context, achat,
                                        includeSupplierInfo, isProforma);
                                  },
                                  icon: const Icon(Icons.visibility),
                                  label: Text(AppLocalizations.of(context)
                                      .translate(
                                          'purchase_history_preview_pdf')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A1E49),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showInvoiceOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)
                          .translate('billing_options_configuration'),
                      style: TextStyle(
                        fontSize:
                            MediaQuery.of(context).size.width < 400 ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: InvoiceOptionsConfig(
                    options: _invoiceOptions,
                    onOptionsChanged: _updateInvoiceOptions,
                    currencySymbol: '¥',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child:
                        Text(AppLocalizations.of(context).translate('close')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceOptionsSummary() {
    final List<Widget> summaryItems = [];

    if (_invoiceOptions.enableLineMargin &&
        _invoiceOptions.lineMarginValue != null) {
      summaryItems.add(_buildSummaryItem(
          AppLocalizations.of(context).translate('margin_per_line'),
          '${_invoiceOptions.lineMarginValue}${_invoiceOptions.lineMarginType == MarginType.percentage ? '%' : '¥'}'));
    }

    if (_invoiceOptions.enableGlobalMargin &&
        _invoiceOptions.globalMarginValue != null) {
      summaryItems.add(_buildSummaryItem(
          AppLocalizations.of(context).translate('global_margin'),
          '${_invoiceOptions.globalMarginValue}${_invoiceOptions.globalMarginType == MarginType.percentage ? '%' : '¥'}'));
    }

    if (_invoiceOptions.enableDiscount &&
        _invoiceOptions.discountValue != null) {
      final discountText =
          _invoiceOptions.discountType == DiscountType.percentage
              ? '${_invoiceOptions.discountValue}%'
              : '¥${_invoiceOptions.discountValue}';
      summaryItems.add(_buildSummaryItem(
          AppLocalizations.of(context).translate('discount'), discountText));
    }

    if (_invoiceOptions.enableStorageFees &&
        _invoiceOptions.storageFeeAmount != null) {
      final storageText =
          _invoiceOptions.storageFeeType == StorageFeeType.percentage
              ? '${_invoiceOptions.storageFeeAmount}%'
              : '¥${_invoiceOptions.storageFeeAmount}';
      summaryItems.add(_buildSummaryItem(
          AppLocalizations.of(context).translate('storage_fees'), storageText));
    }

    return Column(
      children: summaryItems
          .map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: item,
              ))
          .toList(),
    );
  }

  void _showAchatPdfPreviewDialog(BuildContext context, Achat achat,
      bool includeSupplierInfo, bool isProforma) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.6,
          child: PdfPreview(
            build: (format) => VersementPrintService.buildAchatPdfBytes(
              achat,
              includeSupplierInfo: includeSupplierInfo,
              currencyFormat: currencyFormat,
              localizations: AppLocalizations.of(context),
              isProforma: isProforma,
              invoiceOptions: _invoiceOptions,
            ),
            pdfFileName: 'achat_${achat.id ?? "detail"}.pdf',
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1E49),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final achat = widget.achat;
    // Filtrage des articles selon la recherche
    final List<Items> filteredItems = (achat.items ?? []).where((item) {
      final query = _searchQuery.toLowerCase();
      final description = (item.description ?? '').toLowerCase();
      final invoice = (item.invoiceNumber ?? '').toLowerCase();
      return query.isEmpty ||
          description.contains(query) ||
          invoice.contains(query);
    }).toList();
    return Container(
      // MODIFIE : largeur max et hauteur optimisée
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header fixe - Responsive
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne 1: Titre et bouton fermer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)
                          .translate('purchase_history_details_title'),
                      style: TextStyle(
                          fontSize:
                              MediaQuery.of(context).size.width < 400 ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5),
                    ),
                  ),
                  // Bouton fermer
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Ligne 2: Badge dette si applicable
              if (achat.isDebt == true)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F78AF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7F78AF)),
                  ),
                  child: Text(
                    AppLocalizations.of(context)
                        .translate('purchase_history_debt'),
                    style: const TextStyle(
                      color: Color(0xFF7F78AF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Champ de recherche fixe - Responsive
          buildTextField(
            controller: _searchController,
            label: MediaQuery.of(context).size.width < 400
                ? AppLocalizations.of(context).translate('search')
                : AppLocalizations.of(context)
                    .translate('purchase_history_search_hint'),
            icon: Icons.search,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),
          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                      achat.isDebt == true
                          ? AppLocalizations.of(context)
                              .translate('purchase_history_date')
                          : AppLocalizations.of(context)
                              .translate('purchase_history_reference'),
                      achat.isDebt == true
                          ? DateFormat('dd/MM/yyyy HH:mm')
                              .format(achat.createdAt ?? DateTime.now())
                          : (achat.referenceVersement ?? "N/A")),
                  _buildInfoRow(
                      AppLocalizations.of(context)
                          .translate('purchase_history_client'),
                      achat.client ?? "N/A"),
                  if (achat.clientPhone != null)
                    _buildInfoRow(
                        AppLocalizations.of(context)
                            .translate('purchase_history_phone'),
                        achat.clientPhone!),
                  _buildInfoRow(
                      AppLocalizations.of(context)
                          .translate('purchase_history_total_amount'),
                      '${_formatAmount(achat.montantTotal ?? 0)} ¥'),
                  const SizedBox(height: 20),
                  // Section Articles achetés avec bouton d'export
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .translate('purchase_history_purchased_items'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Bouton d'export PDF
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1E49),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.print,
                              color: Colors.white, size: 20),
                          onPressed: () => _handlePrintAchat(achat),
                          tooltip: AppLocalizations.of(context)
                              .translate('purchase_history_export_pdf'),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (filteredItems.isNotEmpty)
                    ...filteredItems.map((item) => _buildItemCard(item, achat))
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(AppLocalizations.of(context)
                            .translate('purchase_history_no_items')),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isAmount ? 16 : 15,
              fontWeight: isAmount ? FontWeight.bold : FontWeight.w600,
              color: isAmount ? const Color(0xFF1A1E49) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Items item, Achat achat) {
    final isConfirmed = confirmedArticles.contains(item.id?.toString());
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre et actions - Responsive
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Expanded(
                child: Text(
                  item.description ??
                      AppLocalizations.of(context).translate('unnamed_item'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: MediaQuery.of(context).size.width < 400 ? 15 : 16,
                    color: const Color(0xFF1A1E49),
                  ),
                ),
              ),
              // Actions éditer/supprimer - Plus compactes sur mobile
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit,
                        color: Color(0xFF1976D2), size: 20),
                    tooltip: AppLocalizations.of(context).translate('edit'),
                    onPressed: () => _showEditArticleDialog(item),
                    padding: const EdgeInsets.all(8),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFFD32F2F), size: 20),
                    tooltip: AppLocalizations.of(context).translate('delete'),
                    onPressed: () => _confirmDeleteArticle(item),
                    padding: const EdgeInsets.all(8),
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoIconText(
                icon: Icons.numbers,
                label: AppLocalizations.of(context).translate('quantity'),
                value: '${item.quantity ?? 0}',
              ),
              const SizedBox(height: 8),
              _InfoIconText(
                icon: Icons.attach_money,
                label: AppLocalizations.of(context).translate('unit_price'),
                value: _formatAmount(item.unitPrice ?? 0) + ' ¥',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoIconText(
                icon: Icons.business_outlined,
                label: AppLocalizations.of(context).translate('supplier'),
                value: item.supplierName ?? 'N/A',
              ),
              if (item.supplierPhone != null &&
                  (item.supplierPhone as String).isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoIconText(
                  icon: Icons.phone,
                  label: 'Téléphone',
                  value: item.supplierPhone ?? '',
                ),
              ],
              const SizedBox(height: 8),
              _InfoIconText(
                icon: Icons.percent,
                label: AppLocalizations.of(context).translate('purchase_rate'),
                value: (item.salesRate?.toString() ?? ''),
              ),
              const SizedBox(height: 8),
              _InfoIconText(
                icon: Icons.calculate,
                label: AppLocalizations.of(context).translate('total'),
                value: _formatAmount(item.totalPrice ??
                        (item.quantity ?? 0) * (item.unitPrice ?? 0)) +
                    ' ¥',
              ),
            ],
          ),
          // Statut et actions de confirmation
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!isConfirmed && item.status != Status.RECEIVED)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_long,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            item.invoiceNumber ?? '',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () =>
                          confirmArticle(item.id?.toString() ?? ''),
                      icon: const Icon(Icons.check_circle_outline,
                          color: Colors.white),
                      label: Text(isLoading ? "Chargement..." : "Confirmer"),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1E49),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              if (item.status == Status.RECEIVED)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        item.invoiceNumber ?? '',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget utilitaire pour afficher une info avec icône
class _InfoIconText extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoIconText(
      {required this.icon, required this.label, required this.value, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Text('$label: ',
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1A1E49))),
      ],
    );
  }
}
