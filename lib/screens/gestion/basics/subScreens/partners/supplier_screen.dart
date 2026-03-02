import 'dart:async';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/partner_notification_service.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/create_supplier_bottom_sheet.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/partner_edit_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/supplier_list_items.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/print/print_config_page.dart';
import 'package:bbd_limited/core/print/print_language.dart';
import 'package:bbd_limited/core/print/print_localizations.dart';
import 'package:bbd_limited/utils/partner_print_service.dart';
import 'package:bbd_limited/models/invoice_options.dart';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({Key? key}) : super(key: key);

  @override
  _SupplierScreenState createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  final TextEditingController searchController = TextEditingController();
  final PartnerServices _partnerServices = PartnerServices();
  final AuthService authService = AuthService();
  final PartnerNotificationService _partnerNotificationService =
      PartnerNotificationService();

  List<Partner> _allSuppliers = [];
  List<Partner> _filteredSuppliers = [];

  bool _isLoading = false;
  bool _hasMoreData = true;
  int currentPage = 0;

  StreamSubscription<Partner>? _partnerUpdateSubscription;
  InvoiceOptions _invoiceOptions = const InvoiceOptions();

  @override
  void initState() {
    super.initState();
    loadSuppliers();
    _setupPartnerUpdateListener();
  }

  @override
  void dispose() {
    searchController.dispose();
    _partnerUpdateSubscription?.cancel();
    super.dispose();
  }

  void _setupPartnerUpdateListener() {
    _partnerUpdateSubscription =
        _partnerNotificationService.partnerUpdateStream.listen(
      (updatedPartner) {
        // Mettre à jour le fournisseur dans la liste locale
        _updateSupplierInList(updatedPartner);
      },
    );
  }

  Future<void> loadSuppliers({bool reset = false, String? searchQuery}) async {
    if (_isLoading || (!reset && !_hasMoreData)) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        currentPage = 0;
        _hasMoreData = true;
        _allSuppliers.clear();
      }
    });

    try {
      final result = await _partnerServices.findSuppliers(
        page: currentPage,
        query: searchQuery,
      );

      setState(() {
        if (reset) {
          _allSuppliers.clear();
        }
        _allSuppliers.addAll(result);

        if (searchQuery == null || searchQuery.isEmpty) {
          _filteredSuppliers = List.from(_allSuppliers);
        } else {
          _filteredSuppliers = _allSuppliers
              .where(
                (supplier) => supplier.firstName.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
              )
              .toList();
        }

        if (result.isEmpty || result.length < 30) {
          _hasMoreData = false;
        } else {
          currentPage++;
        }
      });
    } catch (e) {
      showErrorTopSnackBar(context,
          AppLocalizations.of(context).translate('error_loading_suppliers'));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void searchSupplier(String query) async {
    if (query.isEmpty) {
      await loadSuppliers(reset: true);
      return;
    }

    // recherche locale
    final localResults = _allSuppliers.where((supplier) {
      return supplier.firstName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (localResults.isNotEmpty) {
      setState(() => _filteredSuppliers = localResults);
    } else {
      // recherche dans la base de donnee
      try {
        await loadSuppliers(reset: true, searchQuery: query);
      } catch (e) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('partner_search_error'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('supplier_management_title'),
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_sharp),
            onPressed: _showPrintOptionsDialog,
            tooltip: AppLocalizations.of(context)
                .translate('print_suppliers_balance'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1E49),
        tooltip: AppLocalizations.of(context).translate('add_new_supplier'),
        heroTag: 'supplier_fab',
        onPressed: () async {
          final shouldRefresh = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (context) => CreateSupplierBottomSheet(),
          );

          if (shouldRefresh == true) {
            loadSuppliers(reset: true);
          }
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 10,
              children: [
                Expanded(
                  child: buildTextField(
                    controller: searchController,
                    label: AppLocalizations.of(context)
                        .translate('search_supplier'),
                    icon: Icons.search,
                    onChanged: searchSupplier,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildSupplierList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierList() {
    final localizations = AppLocalizations.of(context);

    if (_isLoading && _filteredSuppliers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredSuppliers.isEmpty) {
      return Center(child: Text(localizations.translate('no_supplier_found')));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await loadSuppliers(reset: true);
      },
      displacement: 40,
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: ListView.builder(
          physics:
              const AlwaysScrollableScrollPhysics(), // permet le pull même si la liste est courte
          itemCount: _filteredSuppliers.length + (_hasMoreData ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _filteredSuppliers.length) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(localizations.translate('loading')),
                    ],
                  ),
                ),
              );
            }

            final supplier = _filteredSuppliers[index];
            return SupplierListItem(
              supplier: supplier,
              onEdit: _editSupplier,
              onDelete: _deleteSupplier,
              onSupplierUpdated: _updateSupplierInList,
            );
          },
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification scrollInfo) {
    if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
        !_isLoading &&
        _hasMoreData) {
      loadSuppliers(searchQuery: searchController.text);
    }
    return false;
  }

  void _editSupplier(Partner supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PartnerEditForm(
        partner: supplier,
        onSubmit: (updatedSupplier) async {
          try {
            setState(() => _isLoading = true);

            // Récupérer l'utilisateur connecté
            final user = await authService.getUserInfo();
            if (user == null) {
              showErrorTopSnackBar(
                context,
                AppLocalizations.of(context).translate('user_not_connected'),
              );
              setState(() => _isLoading = false);
              return;
            }

            final success = await _partnerServices.updatePartner(
              updatedSupplier.id,
              updatedSupplier,
              user.id,
            );

            if (success) {
              await loadSuppliers(reset: true);
              Navigator.pop(context);
              showSuccessTopSnackBar(
                context,
                AppLocalizations.of(context)
                    .translate('partner_updated_success'),
              );
            }
          } catch (e) {
            showErrorTopSnackBar(context,
                AppLocalizations.of(context).translate('partner_update_error'));
          } finally {
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  Future<void> _deleteSupplier(Partner supplier) async {
    final localizations = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('confirm_deletion')),
        backgroundColor: Colors.white,
        content: Text(
          AppLocalizations.of(context)
              .translate('confirm_delete_partner_message')
              .replaceAll('{firstName}', supplier.firstName)
              .replaceAll('{lastName}', supplier.lastName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.translate('cancel')),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete, color: Colors.red),
            label: Text(
              AppLocalizations.of(context).translate('delete'),
              style: const TextStyle(color: Colors.red, fontSize: 18),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = await authService.getUserInfo();

        if (user == null) {
          showErrorTopSnackBar(
              context, AppLocalizations.of(context).translate('please_login'));
          return;
        }
        setState(() => _isLoading = true);
        final result = await _partnerServices.deletePartner(
          supplier.id,
          user.id,
        );

        if (result == "DELETED") {
          loadSuppliers(reset: true);
          _filteredSuppliers
              .removeWhere((element) => element.id == supplier.id);
          showSuccessTopSnackBar(
              context,
              AppLocalizations.of(context)
                  .translate('partner_deleted_success'));
        } else if (result == "CANT_DELETED") {
          showErrorTopSnackBar(context,
              AppLocalizations.of(context).translate('partner_cant_deleted'));
        } else {
          _handleDeleteError(result);
        }
      } catch (e) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('partner_delete_error'));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleDeleteError(String? errorCode) {
    switch (errorCode) {
      case "PARTNER_NOT_FOUND":
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('partner_not_found'));
        break;
      case "PACKAGE_FOUND":
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('partner_packages_exist'),
        );
        break;
      default:
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('partner_unknown_error'));
    }
  }

  void _updateSupplierInList(Partner updatedSupplier) {
    setState(() {
      // Mettre à jour le fournisseur dans _allSuppliers
      final allIndex =
          _allSuppliers.indexWhere((p) => p.id == updatedSupplier.id);
      if (allIndex != -1) {
        _allSuppliers[allIndex] = updatedSupplier;
      }

      // Mettre à jour le fournisseur dans _filteredSuppliers
      final filteredIndex =
          _filteredSuppliers.indexWhere((p) => p.id == updatedSupplier.id);
      if (filteredIndex != -1) {
        _filteredSuppliers[filteredIndex] = updatedSupplier;
      }
    });
  }

  Future<void> _showPrintOptionsDialog() async {
    if (_filteredSuppliers.isEmpty) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('no_supplier_found'),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrintConfigPage(
          title:
              AppLocalizations.of(context).translate('print_suppliers_balance'),
          previewButtonLabel: AppLocalizations.of(context)
              .translate('purchase_history_preview_pdf'),
          initialOptions: _invoiceOptions,
          currencySymbol: '¥',
          onOptionsChanged: (options) {
            setState(() {
              _invoiceOptions = options;
            });
          },
          onPreview: (result) =>
              _showPdfPreviewDialog(result.dateRange, result.printLanguage),
          printOptionsTitle: AppLocalizations.of(context)
              .translate('purchase_history_invoice_options'),
          billingOptionsTitle:
              AppLocalizations.of(context).translate('billing_options'),
          appliedOptionsLabel: AppLocalizations.of(context)
              .translate('currently_applied_options'),
          showDateRange: true,
          dateSectionTitle:
              AppLocalizations.of(context).translate('purchase_history_date'),
          allDataLabel: AppLocalizations.of(context).translate('all_data'),
          filterByDateLabel:
              AppLocalizations.of(context).translate('filter_by_date'),
          selectPeriodPlaceholder:
              AppLocalizations.of(context).translate('select_period'),
          showBillingOptions: false,
        ),
      ),
    );
  }

  Future<void> _showPdfPreviewDialog(
      DateTimeRange? dateRange, PrintLanguage printLanguage) async {
    try {
      final printLocalizations = await PrintLocalizations.create(printLanguage);
      if (!context.mounted) return;

      final pdfBytes = await PartnerPrintService.buildSuppliersBalancePdfBytes(
        _filteredSuppliers,
        dateRange: dateRange,
        printLocalizations: printLocalizations,
      );

      await showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.9,
              child: PdfPreview(
                build: (format) => pdfBytes,
                pdfFileName: 'suppliers_balance.pdf',
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('report_generation_error'),
        );
        print('Error generating PDF: $e');
      }
    }
  }
}
