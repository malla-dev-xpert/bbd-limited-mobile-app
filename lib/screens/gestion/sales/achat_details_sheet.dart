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
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/components/item_detail_chip.dart';

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
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('user_not_connected'));
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
    final cartonController =
        TextEditingController(text: item.carton?.toString() ?? '');
    final quantityPerCartonController =
        TextEditingController(text: item.quantityPerCarton?.toString() ?? '');
    final quantityController =
        TextEditingController(text: item.quantity?.toString() ?? '');
    final unitPriceController =
        TextEditingController(text: item.unitPrice?.toString() ?? '');
    final salesRateController =
        TextEditingController(text: item.salesRate?.toString() ?? '');
    final invoiceNumberController =
        TextEditingController(text: item.invoiceNumber ?? '');
    Partner? selectedSupplier;
    List<Partner> suppliers = [];
    bool loadingSuppliers = true;
    String? errorMsg;

    // Fonction pour recalculer la quantité totale
    void calculateTotalQuantity() {
      final carton = int.tryParse(cartonController.text) ?? 0;
      final quantityPerCarton =
          int.tryParse(quantityPerCartonController.text) ?? 0;
      final totalQuantity = carton * quantityPerCarton;
      quantityController.text = totalQuantity.toString();
    }

    // Ajouter des listeners pour recalculer automatiquement
    cartonController.addListener(calculateTotalQuantity);
    quantityPerCartonController.addListener(calculateTotalQuantity);

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
                                controller: invoiceNumberController,
                                label: AppLocalizations.of(context)
                                    .translate('invoice_number'),
                                icon: Icons.receipt_long,
                              ),
                              const SizedBox(height: 12),

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
                                      controller: cartonController,
                                      label: AppLocalizations.of(context)
                                          .translate('carton'),
                                      icon: Icons.inventory_2,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: buildTextField(
                                      controller: quantityPerCartonController,
                                      label: AppLocalizations.of(context)
                                          .translate('quantity_per_carton'),
                                      icon: Icons.format_list_numbered,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Champ quantité totale (lecture seule)
                              TextFormField(
                                controller: quantityController,
                                keyboardType: TextInputType.number,
                                enabled: false, // Lecture seule
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)
                                      .translate('total_quantity'),
                                  prefixIcon: Icon(Icons.calculate,
                                      color: Colors.grey[600]),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  hintText: AppLocalizations.of(context)
                                      .translate('calculated_automatically'),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              buildTextField(
                                controller: unitPriceController,
                                label: AppLocalizations.of(context).translate(
                                    'purchase_history_edit_unit_price'),
                                icon: Icons.attach_money,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
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
                                      subLabel: 'Modification...',
                                      onPressed: () async {
                                        if (isLoading) return;
                                        setState(() {
                                          isLoading = true;
                                        });
                                        setState(() {
                                          isLoading = true;
                                        });
                                        final user =
                                            await AuthService().getUserInfo();
                                        if (user == null) {
                                          showErrorTopSnackBar(
                                              context,
                                              AppLocalizations.of(context)
                                                  .translate(
                                                      'user_not_connected'));
                                          setState(() {
                                            isLoading = false;
                                          });
                                          return;
                                        }
                                        try {
                                          // Calculer la quantité totale automatiquement
                                          final carton = int.tryParse(
                                                  cartonController.text) ??
                                              0;
                                          final quantityPerCarton = int.tryParse(
                                                  quantityPerCartonController
                                                      .text) ??
                                              0;
                                          final totalQuantity =
                                              carton * quantityPerCarton;

                                          final updatedItem = Items(
                                            id: item.id,
                                            description:
                                                descriptionController.text,
                                            carton: carton,
                                            quantityPerCarton:
                                                quantityPerCarton,
                                            quantity: totalQuantity,
                                            unitPrice: double.tryParse(
                                                unitPriceController.text),
                                            totalPrice: totalQuantity *
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
                                            invoiceNumber:
                                                invoiceNumberController.text
                                                        .trim()
                                                        .isEmpty
                                                    ? null
                                                    : invoiceNumberController
                                                        .text
                                                        .trim(),
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
                                        } finally {
                                          setState(() {
                                            isLoading = false;
                                          });
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

  void _confirmReverseArticle(Items item) {
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
                    .translate('purchase_history_reverse_confirm_title'),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(AppLocalizations.of(context)
            .translate('purchase_history_reverse_confirm_message')
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
              _reverseItem(item);
              Navigator.pop(context);
            },
            child: Text(
                AppLocalizations.of(context)
                    .translate('purchase_history_reverse_confirm_reverse'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _reverseItem(Items item) async {
    setState(() {
      isLoading = true;
    });
    try {
      final user = await AuthService().getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('user_not_connected'));
        setState(() {
          isLoading = false;
        });
        return;
      }
      final itemServices = ItemServices();
      final result = await itemServices.reverseItem(
        item.id!,
        user.id,
        widget.achat.clientId ?? 0,
      );
      if (result == "DELETED_AND_REVERTED") {
        setState(() {
          // Mettre à jour le statut de l'item reversé et recalculer le statut de l'achat
          final itemIndex =
              widget.achat.items?.indexWhere((i) => i.id == item.id) ?? -1;
          if (itemIndex != -1) {
            widget.achat.items![itemIndex].status = Status.PENDING;
            _updateAchatStatusFromItems(widget.achat);
          }
        });
        showSuccessTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_item_reversed_success'));
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
              .translate('purchase_history_error_during_reverse')
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
                                fontSize: 18,
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
                                    style: const TextStyle(fontSize: 16),
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
                                    style: const TextStyle(fontSize: 16),
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
                                    fontSize: 18,
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
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
                          : (achat.referenceVersement ??
                              AppLocalizations.of(context)
                                  .translate('not_available'))),
                  _buildInfoRow(
                      AppLocalizations.of(context)
                          .translate('purchase_history_client'),
                      achat.client ??
                          AppLocalizations.of(context)
                              .translate('not_available')),
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
                          fontSize: 20,
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
              fontSize: 16,
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
    return Slidable(
      key: ValueKey('details_item_${item.id ?? item.hashCode}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.35,
        children: [
          SlidableAction(
            onPressed: (_) => _showEditArticleDialog(item),
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: AppLocalizations.of(context).translate('edit'),
          ),
          SlidableAction(
            onPressed: (item.status == Status.RECEIVED)
                ? (_) => _confirmReverseArticle(item)
                : null,
            backgroundColor: (item.status == Status.RECEIVED)
                ? Colors.orange
                : Colors.grey[300]!,
            foregroundColor: Colors.white,
            icon: Icons.undo_outlined,
            label: AppLocalizations.of(context).translate('reverse'),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            // En-tête de l'item avec actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec icône et actions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1E49).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: Color(0xFF1A1E49),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.description ??
                                  AppLocalizations.of(context)
                                      .translate('unnamed_item'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        '${AppLocalizations.of(context).translate('invoice_number')}: ',
                                  ),
                                  TextSpan(
                                    text: item.invoiceNumber ?? 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Image de statut (remplace les boutons inline)
                      Image.asset(
                        item.status == Status.RECEIVED
                            ? 'assets/images/delivery.png'
                            : 'assets/images/no-delivery.png',
                        width: 44,
                        height: 44,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Divider
                  Divider(color: Colors.grey[200], height: 1),
                  const SizedBox(height: 12),
                  // Détails de l'item
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ItemDetailChip(
                        text:
                            '${AppLocalizations.of(context).translate('carton')}: ${item.carton ?? 0}',
                        icon: Icons.inventory,
                      ),
                      const SizedBox(width: 16),
                      ItemDetailChip(
                        text:
                            '${AppLocalizations.of(context).translate('quantity_per_carton_2')}: ${item.quantityPerCarton ?? 0}',
                        icon: Icons.format_list_numbered,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ItemDetailChip(
                        text:
                            '${AppLocalizations.of(context).translate('total_quantity')}: ${item.quantity ?? 0}',
                        icon: Icons.numbers,
                      ),
                      const SizedBox(width: 8),
                      ItemDetailChip(
                        text: '${_formatAmount(item.unitPrice ?? 0)} ¥',
                        icon: Icons.attach_money,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Taux d'achat et total en colonne pour une meilleure lisibilité
                  Column(
                    children: [
                      ItemDetailChip(
                        text:
                            '${AppLocalizations.of(context).translate('sales_rate')}: ${item.salesRate ?? 0}',
                        icon: Icons.trending_up,
                        fullWidth: true,
                      ),
                      const SizedBox(height: 8),
                      ItemDetailChip(
                        text:
                            '${AppLocalizations.of(context).translate('total')}: ${_formatAmount(item.totalPrice ?? (item.quantity ?? 0) * (item.unitPrice ?? 0))} ¥',
                        icon: Icons.calculate,
                        fullWidth: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Information sur le fournisseur
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.business,
                            size: 16, color: Colors.purple[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${AppLocalizations.of(context).translate('supplier')}: ${item.supplierName ?? AppLocalizations.of(context).translate('not_available')}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.purple[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (item.supplierPhone != null &&
                                  (item.supplierPhone as String).isNotEmpty)
                                Text(
                                  '${AppLocalizations.of(context).translate('purchase_history_phone')}: ${item.supplierPhone}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.purple[700],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Statut et bouton de confirmation
                  if (!isConfirmed && item.status != Status.RECEIVED) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pending_actions,
                              size: 20, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate('purchase_history_item_pending'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () =>
                                confirmArticle(item.id?.toString() ?? ''),
                            icon: const Icon(Icons.check_circle_outline,
                                size: 18),
                            label: Text(
                              isLoading
                                  ? AppLocalizations.of(context)
                                      .translate('loading_short')
                                  : AppLocalizations.of(context)
                                      .translate('confirm_short'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1E49),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (item.status == Status.RECEIVED) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 20, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate('purchase_history_item_received'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour compter les articles livrés (par numéro de facture)
  int _getDeliveredItemsCount(Achat achat) {
    if (achat.items == null) return 0;

    final deliveredInvoices = <String>{};
    for (var item in achat.items!) {
      if (item.status == Status.RECEIVED &&
          item.invoiceNumber != null &&
          item.invoiceNumber!.isNotEmpty) {
        deliveredInvoices.add(item.invoiceNumber!);
      }
    }
    return deliveredInvoices.length;
  }

  // Méthode pour compter le total des factures
  int _getTotalInvoicesCount(Achat achat) {
    if (achat.items == null) return 0;

    final allInvoices = <String>{};
    for (var item in achat.items!) {
      if (item.invoiceNumber != null && item.invoiceNumber!.isNotEmpty) {
        allInvoices.add(item.invoiceNumber!);
      }
    }
    return allInvoices.length;
  }

  void _updateAchatStatusFromItems(Achat achat) {
    final total = _getTotalInvoicesCount(achat);
    final delivered = _getDeliveredItemsCount(achat);
    if (total > 0 && delivered >= total) {
      achat.status = Status.COMPLETED;
    } else {
      // S'il reste des factures non livrées, on considère l'achat comme en attente
      if (achat.status == Status.COMPLETED) {
        achat.status = Status.PENDING;
      }
    }
  }
}
