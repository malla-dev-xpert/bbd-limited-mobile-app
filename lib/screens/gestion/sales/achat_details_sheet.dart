import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/core/services/access_control_service.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/utils/invoice_service.dart';
import 'package:printing/printing.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/print/print_localizations.dart';
import 'package:bbd_limited/core/print/print_language.dart';
import 'package:bbd_limited/models/invoice_options.dart';
import 'package:bbd_limited/components/print/print_config_page.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/components/reusable_item_card.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/models/versement.dart';

class AchatDetailsSheet extends StatefulWidget {
  final Achat achat;
  final VoidCallback? onItemConfirmed;
  final VoidCallback? onItemReversed;

  /// When true, widget is used inside a full-screen page (no bottom sheet chrome).
  final bool fullScreen;

  /// When set, Edit action opens this callback (e.g. push EditArticleScreen) instead of the edit bottom sheet.
  final Future<void> Function(Items item)? onEditArticle;

  const AchatDetailsSheet({
    super.key,
    required this.achat,
    this.onItemConfirmed,
    this.onItemReversed,
    this.fullScreen = false,
    this.onEditArticle,
  });

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

  Future<void> _handleDeleteItem(Items item) async {
    // 1. Demander confirmation à l'utilisateur
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title:
            Text(AppLocalizations.of(context).translate('delete_item_title')),
        content: Text(
            AppLocalizations.of(context).translate('delete_item_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).translate('delete')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 2. Appel au service (Assurez-vous d'avoir accès au currentUserId)
      final itemServices = ItemServices();
      final authService = AuthService();
      final user = await authService.getUserInfo();
      // Note : Remplacez 'currentUserId' par votre variable réelle (ex: authProvider.user.id)
      final result = await itemServices.deleteItem(
        itemId: item.id!,
        userId: user!.id,
      );

      if (result.isSuccess) {
        Navigator.of(context).pop(true);
        // 3. Mise à jour de l'UI
        setState(() {
          widget.achat.items?.removeWhere((i) => i.id == item.id);
        });

        showSuccessTopSnackBar(
          context,
          AppLocalizations.of(context).translate('delete_item_success'),
        );
      } else {
        showErrorTopSnackBar(
          context,
          result.errorMessage ??
              AppLocalizations.of(context).translate('delete_item_error'),
        );
      }
    } catch (e) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('delete_item_error'),
      );
    }
  }

  /// Affiche un dialogue pour confirmer la livraison avec champs optionnels
  /// (nombre de cartons, quantité par carton, quantité totale).
  Future<_ConfirmDeliveryData?> _showConfirmDeliveryDialog(Items item) async {
    final cartonController = TextEditingController(
        text: item.carton != null ? item.carton.toString() : '');
    final quantityPerCartonController = TextEditingController(
        text: item.quantityPerCarton != null
            ? item.quantityPerCarton.toString()
            : '');
    int? quantityTotal;
    void computeTotal() {
      final c = int.tryParse(cartonController.text);
      final qpc = int.tryParse(quantityPerCartonController.text);
      if (c != null && qpc != null && c > 0) quantityTotal = c * qpc;
    }

    return showDialog<_ConfirmDeliveryData?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            computeTotal();
            return Dialog(
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .translate('confirm_delivery_dialog_title'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildTextField(
                      controller: cartonController,
                      label: AppLocalizations.of(context).translate('carton'),
                      icon: Icons.inventory_2,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    buildTextField(
                      controller: quantityPerCartonController,
                      label: AppLocalizations.of(context)
                          .translate('quantity_per_carton'),
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate('total_quantity'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          quantityTotal != null
                              ? quantityTotal.toString()
                              : '—',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(null),
                          child: Text(
                              AppLocalizations.of(context).translate('cancel')),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final c = int.tryParse(cartonController.text);
                            final qpc =
                                int.tryParse(quantityPerCartonController.text);
                            final q = quantityTotal ??
                                (item.quantity != null ? item.quantity! : null);
                            Navigator.of(ctx).pop(_ConfirmDeliveryData(
                              carton: c,
                              quantityPerCarton: qpc,
                              quantity: q ??
                                  (c != null && qpc != null ? c * qpc : null),
                            ));
                          },
                          child: Text(AppLocalizations.of(context)
                              .translate('confirm_short')),
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

  Future<void> confirmArticle(
    String itemId,
    Items item, {
    int? carton,
    int? quantityPerCarton,
    int? quantity,
  }) async {
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
      final id = int.parse(itemId);
      final quantitySent = quantity ?? item.quantity;
      final cartonSent = carton ?? item.carton;
      final qpcSent = quantityPerCarton ?? item.quantityPerCarton;
      final itemQuantities = [
        AchatServices.itemQuantityUpdate(
          id,
          quantity: quantitySent,
          carton: cartonSent,
          quantityPerCarton: qpcSent,
        ),
      ];
      final result = await achatServices.confirmDelivery(
        itemIds: [id],
        userId: user.id,
        itemQuantities: itemQuantities,
      );

      if (result.isSuccess) {
        setState(() {
          confirmedArticles.add(itemId);
          final idx = widget.achat.items
                  ?.indexWhere((i) => i.id?.toString() == itemId) ??
              -1;
          if (idx != -1) {
            final it = widget.achat.items![idx];
            widget.achat.items![idx] = it.copyWith(
              carton: cartonSent,
              quantityPerCarton: qpcSent,
              quantity: quantitySent,
            );
            widget.achat.items![idx].status = Status.RECEIVED;
          }
        });

        if (widget.onItemConfirmed != null) {
          widget.onItemConfirmed!();
        }

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
                                icon: Icons.currency_yen,
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
                                          try {
                                            final result =
                                                await itemServices.updateItem(
                                              itemId: item.id!,
                                              userId: user.id,
                                              item: updatedItem,
                                            );
                                            if (result.success == true) {
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
                                            }
                                          } on ItemUpdateException catch (e) {
                                            // Gérer les erreurs selon le code d'erreur
                                            if (e.errorCode ==
                                                'ITEM_NOT_FOUND') {
                                              showErrorTopSnackBar(
                                                  context,
                                                  AppLocalizations.of(context)
                                                      .translate(
                                                          'purchase_history_item_not_found'));
                                            } else if (e.errorCode ==
                                                'USER_NOT_FOUND') {
                                              showErrorTopSnackBar(
                                                  context,
                                                  AppLocalizations.of(context)
                                                      .translate(
                                                          'purchase_history_user_not_found'));
                                            } else if (e.errorCode ==
                                                'CLIENT_MISMATCH') {
                                              showErrorTopSnackBar(
                                                  context,
                                                  AppLocalizations.of(context)
                                                      .translate(
                                                          'purchase_history_client_mismatch'));
                                            } else if (e.errorCode ==
                                                'SUPPLIER_NOT_FOUND') {
                                              showErrorTopSnackBar(
                                                  context,
                                                  AppLocalizations.of(context)
                                                      .translate(
                                                          'purchase_history_supplier_not_found'));
                                            } else {
                                              showErrorTopSnackBar(
                                                  context,
                                                  e.message.isNotEmpty
                                                      ? e.message
                                                      : AppLocalizations.of(
                                                              context)
                                                          .translate(
                                                              'purchase_history_error_occurred')
                                                          .replaceAll(
                                                              '{error}',
                                                              e.errorCode ??
                                                                  'UNKNOWN'));
                                            }
                                          } catch (e) {
                                            showErrorTopSnackBar(
                                                context,
                                                AppLocalizations.of(context)
                                                    .translate(
                                                        'purchase_history_error_occurred')
                                                    .replaceAll('{error}',
                                                        e.toString()));
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

        // Appeler le callback pour notifier le parent
        if (widget.onItemReversed != null) {
          widget.onItemReversed!();
        }

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrintConfigPage(
          title: AppLocalizations.of(context)
              .translate('purchase_history_print_options'),
          previewButtonLabel: AppLocalizations.of(context)
              .translate('purchase_history_preview_pdf'),
          initialOptions: _invoiceOptions,
          currencySymbol: '¥',
          onOptionsChanged: _updateInvoiceOptions,
          onPreview: (result) => _showAchatPdfPreviewDialog(
            context,
            achat,
            result.includeSupplierInfo ?? false,
            result.isProforma ?? false,
            result.printLanguage,
          ),
          printOptionsTitle: AppLocalizations.of(context)
              .translate('purchase_history_invoice_options'),
          billingOptionsTitle:
              AppLocalizations.of(context).translate('billing_options'),
          appliedOptionsLabel: AppLocalizations.of(context)
              .translate('currently_applied_options'),
          showSupplierToggle: true,
          includeSupplierLabel: AppLocalizations.of(context)
              .translate('purchase_history_include_supplier'),
          showProformaToggle: true,
          proformaLabel: AppLocalizations.of(context)
              .translate('purchase_history_generate_proforma'),
          items: achat.items ?? [],
          subtotal: (achat.items?.fold<double>(
                  0.0, (sum, item) => sum + (item.totalPrice ?? 0.0))) ??
              0.0,
        ),
      ),
    );
  }

  Future<void> _showAchatPdfPreviewDialog(
      BuildContext context,
      Achat initialAchat,
      bool includeSupplierInfo,
      bool isProforma,
      PrintLanguage printLanguage) async {
    // Récupérer les informations complètes de l'achat pour s'assurer d'avoir les containerIds
    Achat achatToUse = initialAchat;
    if (initialAchat.id != null) {
      try {
        final fullAchat = await AchatServices().getById(initialAchat.id!);
        if (fullAchat != null) {
          achatToUse = fullAchat;
        }
      } catch (e) {
        print(
            'Erreur lors de la récupération des détails complets de l\'achat: $e');
      }
    }

    // Récupérer les informations des conteneurs liés
    List<Containers> containers = [];
    try {
      final containerIds = achatToUse.items
              ?.map((e) => e.containerId)
              .where((id) => id != null)
              .toSet() ??
          {};

      if (containerIds.isNotEmpty) {
        final service = ContainerServices();
        for (final id in containerIds) {
          try {
            final container = await service.getContainerDetails(id!);
            containers.add(container);
          } catch (e) {
            print('Erreur lors du chargement du conteneur $id: $e');
          }
        }
      } else {
        print(
            'Aucun Container ID trouvé dans les items de l\'achat ${achatToUse.id}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des conteneurs: $e');
    }

    // Charger le versement pour afficher la référence et le montant restant à l'impression
    Versement? versement;
    if (achatToUse.referenceVersement != null &&
        achatToUse.referenceVersement!.isNotEmpty &&
        achatToUse.isDebt != true) {
      try {
        versement =
            await VersementServices().getByReference(achatToUse.referenceVersement!);
      } catch (e) {
        print('Erreur lors de la récupération du versement: $e');
      }
    }

    final printLocalizations = await PrintLocalizations.create(printLanguage);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          child: PdfPreview(
            build: (format) => InvoiceService.buildAchatPdfBytes(
              achatToUse,
              includeSupplierInfo: includeSupplierInfo,
              currencyFormat: currencyFormat,
              printLocalizations: printLocalizations,
              isProforma: isProforma,
              invoiceOptions: _invoiceOptions,
              containers: containers,
              versement: versement,
            ),
            pdfFileName: 'achat_${achatToUse.id ?? "detail"}.pdf',
          ),
        ),
      ),
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

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.fullScreen) ...[
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
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        if (achat.isDebt == true) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF7F78AF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7F78AF)),
            ),
            child: Text(
              AppLocalizations.of(context).translate('purchase_history_debt'),
              style: const TextStyle(
                color: Color(0xFF7F78AF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
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
                if (achat.code != null && achat.code!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate('code'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                achat.code!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: achat.code!));
                                  showSuccessTopSnackBar(
                                      context,
                                      AppLocalizations.of(context)
                                          .translate('code_copied'));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.copy,
                                    size: 20,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
    );

    if (widget.fullScreen) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: content,
      );
    }
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: content,
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
    final user = AuthService.currentUser;
    final access = AccessControlService();
    final canEdit = access.canEditItem(user);
    final canDelete = access.canDeleteItem(user);

    final slidableActions = <Widget>[
      if (canEdit)
        SlidableAction(
          onPressed: (_) {
            if (widget.onEditArticle != null) {
              widget.onEditArticle!(item);
            } else {
              _showEditArticleDialog(item);
            }
          },
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          icon: Icons.edit,
          label: AppLocalizations.of(context).translate('edit'),
        ),
      if (canEdit)
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
      if (canDelete)
        SlidableAction(
          onPressed: (item.status != Status.RECEIVED)
              ? (_) => _handleDeleteItem(item)
              : null,
          backgroundColor:
              (item.status != Status.RECEIVED) ? Colors.red : Colors.grey[300]!,
          foregroundColor: Colors.white,
          icon: Icons.delete,
          label: AppLocalizations.of(context).translate('delete'),
        ),
    ];

    return ReusableItemCard(
      item: item,
      achat: achat,
      actions: slidableActions,
      showSupplierInfo: true,
      isLoading: isLoading,
      onConfirm: (item, achat) async {
        final data = await _showConfirmDeliveryDialog(item);
        if (data != null && mounted) {
          await confirmArticle(item.id!.toString(), item,
              carton: data.carton,
              quantityPerCarton: data.quantityPerCarton,
              quantity: data.quantity);
        }
      },
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

class _ConfirmDeliveryData {
  final int? carton;
  final int? quantityPerCarton;
  final int? quantity;
  _ConfirmDeliveryData({this.carton, this.quantityPerCarton, this.quantity});
}
