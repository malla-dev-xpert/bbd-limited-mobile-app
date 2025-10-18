import 'dart:async';
import 'package:bbd_limited/utils/partner_print_service.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/exchange_rate_service.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/new_versement.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/create_package_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/package_list_item.dart';
import 'package:bbd_limited/screens/gestion/accounts/versement_detail_screen.dart';
import 'package:bbd_limited/screens/gestion/sales/achat_details_sheet.dart';
import 'package:bbd_limited/routes.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/package_details_screen.dart';
import 'package:printing/printing.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/models/invoice_options.dart';
import 'package:bbd_limited/components/invoice_options_config.dart';

import 'widgets/balance_card_widget.dart';
import 'widgets/operation_type_selector.dart';
import 'widgets/date_filter.dart';
import 'widgets/versement_list.dart';
import 'widgets/debt_list.dart';

enum OperationType { versements, expeditions, debts }

class PartnerDetailScreen extends StatefulWidget {
  final Partner partner;
  final Function(Partner)? onPartnerUpdated;

  const PartnerDetailScreen({
    Key? key,
    required this.partner,
    this.onPartnerUpdated,
  }) : super(key: key);

  @override
  State<PartnerDetailScreen> createState() => _PartnerDetailScreenState();
}

class _PartnerDetailScreenState extends State<PartnerDetailScreen> {
  late Partner _partner;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic>? _filteredVersements;
  List<Packages>? _filteredPackages;
  List<Achat>? _filteredDebts;
  OperationType _selectedOperationType = OperationType.versements;
  final ExchangeRateService _exchangeRateService = ExchangeRateService();
  double _totalVersementsUSD = 0.0;
  VersementType? _selectedVersementType;
  final GlobalKey _filterIconKey = GlobalKey();

  // Variables pour les filtres
  DateTime? _selectedDateDebut;
  DateTime? _selectedDateFin;
  bool _showDateFilter = false;
  TextEditingController _dateDebutController = TextEditingController();
  TextEditingController _dateFinController = TextEditingController();
  Timer? _searchTimer;

  // Options de facturation configurables
  InvoiceOptions _invoiceOptions = const InvoiceOptions();

  @override
  void initState() {
    super.initState();
    _partner = widget.partner;
    _filteredVersements = _partner.versements;
    _filteredPackages = _partner.packages;
    _filteredDebts = [];
    _dateDebutController = TextEditingController();
    _dateFinController = TextEditingController();
    _sortVersementsByDate();
    _sortExpeditionsByDate();
    _initializeData();
    _loadDebts();
  }

  Future<void> _initializeData() async {
    await _calculateTotalVersementsUSD();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadDebts() async {
    try {
      final achats = await AchatServices().findAll();
      final filteredDebts = achats
          .where((a) =>
              a.isDebt == true &&
              ((a.clientPhone != null &&
                      a.clientPhone == _partner.phoneNumber) ||
                  (a.clientId != null && a.clientId == _partner.id)))
          .toList();

      setState(() {
        _filteredDebts = filteredDebts;
      });
    } catch (e) {
      print('Erreur lors du chargement des dettes: $e');
    }
  }

  void _updateInvoiceOptions(InvoiceOptions newOptions) {
    setState(() {
      _invoiceOptions = newOptions;
    });
  }

  void _sortVersementsByDate() {
    if (_filteredVersements != null) {
      _filteredVersements!.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(1900);
        final dateB = b.createdAt ?? DateTime(1900);
        return dateB.compareTo(dateA);
      });
    }
  }

  void _sortExpeditionsByDate() {
    if (_filteredPackages != null) {
      _filteredPackages!.sort((a, b) {
        final dateA = a.startDate ?? DateTime(1900);
        final dateB = b.startDate ?? DateTime(1900);
        return dateB.compareTo(dateA);
      });
    }
  }

  Future<void> _refreshData() async {
    try {
      final partnerServices = PartnerServices();
      final partners = await partnerServices.findCustomers(page: 0);
      final freshPartner = partners.firstWhere(
        (p) => p.id == widget.partner.id,
        orElse: () => widget.partner,
      );

      setState(() {
        _partner = freshPartner;
        _filteredVersements = _partner.versements;
        _filteredPackages = _partner.packages;
        _filteredDebts = [];
        _sortVersementsByDate();
        _sortExpeditionsByDate();
      });

      await _loadDebts();
      await _calculateTotalVersementsUSD(); // Recalculer le total après le rafraîchissement

      // Notifier le parent que le partenaire a été mis à jour
      if (widget.onPartnerUpdated != null) {
        widget.onPartnerUpdated!(_partner);
      }
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }

  void _filterOperations(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        if (_selectedOperationType == OperationType.versements) {
          _filteredVersements = _partner.versements?.where((versement) {
            // Filtre texte
            final searchText = query.isEmpty ||
                (versement.reference
                        ?.toLowerCase()
                        .contains(query.toLowerCase()) ??
                    false);

            // Filtre type
            bool typeMatch = _selectedVersementType == null ||
                versement.type ==
                    _selectedVersementType!.toString().split('.').last;

            // Filtre date
            bool dateMatch = true;
            if (_selectedDateDebut != null || _selectedDateFin != null) {
              final dateVersement = versement.createdAt;
              if (dateVersement == null) {
                dateMatch = false;
              } else {
                if (_selectedDateDebut != null) {
                  dateMatch = dateMatch &&
                      dateVersement.isAfter(_selectedDateDebut!
                          .subtract(const Duration(days: 1)));
                }
                if (_selectedDateFin != null) {
                  dateMatch = dateMatch &&
                      dateVersement.isBefore(
                          _selectedDateFin!.add(const Duration(days: 1)));
                }
              }
            }
            return searchText && typeMatch && dateMatch;
          }).toList();
        } else if (_selectedOperationType == OperationType.expeditions) {
          _filteredPackages = _partner.packages?.where((package) {
            // Filtre texte
            final searchText = query.isEmpty ||
                (package.ref?.toLowerCase().contains(query.toLowerCase()) ??
                    false);

            // Filtre date
            bool dateMatch = true;
            if (_selectedDateDebut != null || _selectedDateFin != null) {
              final datePackage = package.startDate;
              if (datePackage == null) {
                dateMatch = false;
              } else {
                if (_selectedDateDebut != null) {
                  dateMatch = dateMatch &&
                      datePackage.isAfter(_selectedDateDebut!
                          .subtract(const Duration(days: 1)));
                }
                if (_selectedDateFin != null) {
                  dateMatch = dateMatch &&
                      datePackage.isBefore(
                          _selectedDateFin!.add(const Duration(days: 1)));
                }
              }
            }
            return searchText && dateMatch;
          }).toList();
        } else if (_selectedOperationType == OperationType.debts) {
          _filteredDebts = _filteredDebts?.where((debt) {
            // Filtre texte
            final searchText =
                query.isEmpty || (debt.id?.toString().contains(query) ?? false);

            // Filtre date
            bool dateMatch = true;
            if (_selectedDateDebut != null || _selectedDateFin != null) {
              final dateDebt = debt.createdAt;
              if (dateDebt == null) {
                dateMatch = false;
              } else {
                if (_selectedDateDebut != null) {
                  dateMatch = dateMatch &&
                      dateDebt.isAfter(_selectedDateDebut!
                          .subtract(const Duration(days: 1)));
                }
                if (_selectedDateFin != null) {
                  dateMatch = dateMatch &&
                      dateDebt.isBefore(
                          _selectedDateFin!.add(const Duration(days: 1)));
                }
              }
            }
            return searchText && dateMatch;
          }).toList();
        }
        _sortVersementsByDate();
        _sortExpeditionsByDate();
      });
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _selectedDateDebut ?? DateTime.now()
          : _selectedDateFin ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _selectedDateDebut = picked;
          _dateDebutController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _selectedDateFin = picked;
          _dateFinController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
      _filterOperations(_searchController.text);
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateDebut = null;
      _selectedDateFin = null;
      _dateDebutController.clear();
      _dateFinController.clear();
      _showDateFilter = false;
    });
    _filterOperations(_searchController.text);
  }

  Future<void> _calculateTotalVersementsUSD() async {
    if (_partner.versements == null || _partner.versements!.isEmpty) {
      setState(() {
        _totalVersementsUSD = 0.0;
      });
      return;
    }

    double totalCNY = 0.0;
    for (var versement in _partner.versements!) {
      if (versement.montantVerser != null && versement.deviseCode != null) {
        if (versement.deviseCode == 'CNY') {
          // Si la devise est déjà en CNY, ajouter directement
          totalCNY += versement.montantVerser!;
        } else {
          // Utiliser le taux utilisé lors du versement s'il existe
          if (versement.tauxUtilise != null && versement.tauxUtilise! > 0) {
            // Convertir en CNY en utilisant le taux utilisé lors du versement
            totalCNY += versement.montantVerser! * versement.tauxUtilise!;
          } else {
            // Fallback: utiliser le taux de change actuel si tauxUtilise n'est pas disponible
            final rate = await _exchangeRateService
                .getExchangeRate(versement.deviseCode!);
            totalCNY += versement.montantVerser! * rate;
          }
        }
      }
    }

    setState(() {
      _totalVersementsUSD = totalCNY; // Maintenant c'est en CNY
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'CNY',
    );

    final partnerName =
        "${_partner.firstName} ${_partner.lastName} ${_partner.lastName.isNotEmpty ? '|' : ''} ${_partner.phoneNumber}";

    return Scaffold(
      appBar: AppBar(
          title: Text(
            partnerName,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          actions: [
            TextButton.icon(
              onPressed: _showPrintOptionsDialog,
              icon: const Icon(Icons.print),
              label: Text(
                AppLocalizations.of(context).translate('print'),
              ),
            ),
          ]),
      floatingActionButton: _buildFloatingActionButton(),
      body: Column(
        children: [
          PartnerBalanceCard(
            partner: _partner,
            totalVersementsUSD: _totalVersementsUSD,
          ),
          const SizedBox(height: 30),
          OperationTypeSelector(
            selectedOperationType: _selectedOperationType,
            onTypeSelected: (type) {
              setState(() {
                _selectedOperationType = type;
              });
            },
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildSearchAndFilterRow(),
              DateFilterWidget(
                showDateFilter: _showDateFilter,
                dateDebutController: _dateDebutController,
                dateFinController: _dateFinController,
                onDateDebutSelected: () => _selectDate(context, true),
                onDateFinSelected: () => _selectDate(context, false),
                onClearDateFilter: _clearDateFilter,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildOperationsList(currencyFormat, context),
          ),
        ],
      ),
    );
  }

  void _showPdfPreviewDialog(DateTimeRange? dateRange) async {
    try {
      final pdfBytes = await PartnerPrintService.buildClientReportPdfBytes(
        _partner,
        dateRange: dateRange,
        localizations: AppLocalizations.of(context),
        invoiceOptions: _invoiceOptions,
      );

      await showDialog(
        context: context,
        builder: (context) {
          final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
          final heightFactor = isTablet ? 0.8 : 0.6;

          return Dialog(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * heightFactor,
              child: PdfPreview(
                build: (format) => pdfBytes,
              ),
            ),
          );
        },
      );
    } catch (e) {
      showErrorTopSnackBar(context,
          AppLocalizations.of(context).translate('report_generation_error'));
    }
  }

  Future<void> _showPrintOptionsDialog() async {
    DateTimeRange? selectedDateRange;
    bool printAll = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.95,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: Container(
                  width: double.infinity,
                  child: Column(
                    children: [
                      // Header fixe
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isTablet =
                                MediaQuery.of(context).size.shortestSide >= 600;

                            if (isTablet) {
                              // Design pour tablettes - layout horizontal
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Configuration et aperçu du rapport client',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              );
                            } else {
                              // Design pour téléphones - layout horizontal optimisé
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Configuration et aperçu du rapport client',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),

                      // Contenu scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Section options d'impression
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Options d\'impression',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1E49),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Période d'impression - Responsive
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final isTablet = MediaQuery.of(context)
                                                .size
                                                .shortestSide >=
                                            600;

                                        if (isTablet) {
                                          // Design pour tablettes - layout horizontal
                                          return Row(
                                            children: [
                                              const Text(
                                                  "Période d'impression:"),
                                              const SizedBox(width: 20),
                                              Row(
                                                children: [
                                                  Radio<bool>(
                                                    value: true,
                                                    groupValue: printAll,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        printAll = value!;
                                                        if (value)
                                                          selectedDateRange =
                                                              null;
                                                      });
                                                    },
                                                  ),
                                                  const Text(
                                                      'Toutes les données'),
                                                ],
                                              ),
                                              const SizedBox(width: 20),
                                              Row(
                                                children: [
                                                  Radio<bool>(
                                                    value: false,
                                                    groupValue: printAll,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        printAll = value!;
                                                      });
                                                    },
                                                  ),
                                                  const Text(
                                                      'Filtrer par date'),
                                                ],
                                              ),
                                            ],
                                          );
                                        } else {
                                          // Design pour téléphones - layout vertical
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Période d'impression:",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Radio<bool>(
                                                    value: true,
                                                    groupValue: printAll,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        printAll = value!;
                                                        if (value)
                                                          selectedDateRange =
                                                              null;
                                                      });
                                                    },
                                                  ),
                                                  const Expanded(
                                                    child: Text(
                                                        'Toutes les données'),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Radio<bool>(
                                                    value: false,
                                                    groupValue: printAll,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        printAll = value!;
                                                      });
                                                    },
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                        'Filtrer par date'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        }
                                      },
                                    ),

                                    // Sélecteur de date (seulement si pas "toutes les données")
                                    if (!printAll) ...[
                                      const SizedBox(height: 16),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () async {
                                          final DateTimeRange? range =
                                              await showDateRangePicker(
                                            context: context,
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100),
                                            currentDate: DateTime.now(),
                                            initialDateRange: selectedDateRange,
                                            builder: (context, child) {
                                              return Theme(
                                                data:
                                                    Theme.of(context).copyWith(
                                                  dialogTheme: DialogTheme(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    elevation: 4,
                                                  ),
                                                  colorScheme:
                                                      ColorScheme.fromSwatch(
                                                    primarySwatch: Colors.blue,
                                                  ).copyWith(
                                                    surface: Colors.white,
                                                  ),
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );
                                          if (range != null && mounted) {
                                            setState(() =>
                                                selectedDateRange = range);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey[300]!),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  selectedDateRange == null
                                                      ? 'Sélectionner une période'
                                                      : "${DateFormat('dd/MM/yyyy').format(selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(selectedDateRange!.end)}",
                                                  style: TextStyle(
                                                    color: selectedDateRange ==
                                                            null
                                                        ? Colors.grey[600]
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ),
                                              const Icon(Icons.calendar_today,
                                                  size: 20, color: Colors.grey),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Configuration des options de facturation
                              InvoiceOptionsConfig(
                                options: _invoiceOptions,
                                onOptionsChanged: _updateInvoiceOptions,
                                currencySymbol: _getPartnerCurrency(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Footer fixe avec boutons
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey[300]!),
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isTablet =
                                MediaQuery.of(context).size.shortestSide >= 600;

                            if (isTablet) {
                              // Design pour tablettes - layout horizontal
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Annuler'),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _showPdfPreviewDialog(
                                        printAll ? null : selectedDateRange,
                                      );
                                    },
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('Voir l\'aperçu PDF'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1A1E49),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // Design pour téléphones - layout vertical
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _showPdfPreviewDialog(
                                        printAll ? null : selectedDateRange,
                                      );
                                    },
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('Voir l\'aperçu PDF'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1A1E49),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Annuler'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
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

  Widget _buildFloatingActionButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E49),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton.icon(
        onPressed: () {
          if (_selectedOperationType == OperationType.versements) {
            _showCreateVersementBottomSheet(context);
          } else if (_selectedOperationType == OperationType.expeditions) {
            _showCreateExpeditionBottomSheet(context);
          } else {
            _showCreateDebtBottomSheet(context);
          }
        },
        label: Text(
          _selectedOperationType == OperationType.versements
              ? AppLocalizations.of(context).translate('new_versement')
              : _selectedOperationType == OperationType.expeditions
                  ? AppLocalizations.of(context).translate('new_package')
                  : AppLocalizations.of(context).translate('new_debt'),
          style: const TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilterRow() {
    return Row(
      children: [
        Expanded(flex: 4, child: _buildSearchBar()),
        const SizedBox(width: 8),
        // Bouton pour filtrer par type (seulement pour les versements)
        if (_selectedOperationType == OperationType.versements)
          _buildFilterTypeButton(),
        const SizedBox(width: 8),
        // Bouton pour filtrer par date
        _buildDateFilterButton(),
      ],
    );
  }

  Widget _buildFilterTypeButton() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final RenderBox button = _filterIconKey.currentContext!
                      .findRenderObject() as RenderBox;
                  final RenderBox overlay = Overlay.of(context)
                      .context
                      .findRenderObject() as RenderBox;
                  final Offset position =
                      button.localToGlobal(Offset.zero, ancestor: overlay);

                  final selected = await showMenu<VersementType?>(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      position.dx,
                      position.dy + button.size.height,
                      position.dx + button.size.width,
                      overlay.size.height - (position.dy + button.size.height),
                    ),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    items: [
                      PopupMenuItem<VersementType?>(
                        value: null,
                        child: Text(
                          AppLocalizations.of(context).translate('all_types'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      ...VersementType.values.map(
                        (type) => PopupMenuItem<VersementType?>(
                          value: type,
                          child: Text(
                            _getVersementTypeTranslation(type),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  );
                  if (selected != null || selected == null) {
                    setState(() {
                      _selectedVersementType = selected;
                    });
                    _filterOperations(_searchController.text);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Icon(
                    Icons.filter_list,
                    key: _filterIconKey,
                    size: 26,
                    color: const Color(0xFF1A1E49),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _showDateFilter = !_showDateFilter;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Icon(
                  _showDateFilter ? Icons.calendar_today : Icons.date_range,
                  size: 26,
                  color: const Color(0xFF1A1E49),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: buildTextField(
        controller: _searchController,
        label: AppLocalizations.of(context).translate('search'),
        icon: Icons.search,
        onChanged: _filterOperations,
      ),
    );
  }

  Widget _buildOperationsList(
    NumberFormat currencyFormat,
    BuildContext context,
  ) {
    if (_selectedOperationType == OperationType.versements) {
      return VersementListWidget(
        versements: _filteredVersements,
        onRefresh: _refreshData,
        onVersementTap: (versement) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VersementDetailScreen(
              versement: versement,
              onVersementUpdated: _refreshData,
            ),
          ),
        ),
        onEditVersement: _showEditVersementModal,
        onDeleteVersement: _deleteVersement,
      );
    } else if (_selectedOperationType == OperationType.expeditions) {
      return _buildExpeditionsList(context);
    } else {
      return DebtListWidget(
        debts: _filteredDebts,
        onRefresh: _refreshData,
        onDebtTap: _showAchatDetails,
      );
    }
  }

  Widget _buildExpeditionsList(BuildContext context) {
    if (_filteredPackages == null || _filteredPackages!.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.2,
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context).translate('no_packages_found'),
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: _filteredPackages?.length ?? 0,
        itemBuilder: (context, index) {
          final package = _filteredPackages![index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: PackageListItem(
              packages: package,
              onTap: () => _showPackageDetails(context, package),
            ),
          );
        },
      ),
    );
  }

  void _showPackageDetails(BuildContext context, Packages package) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PackageDetailsScreen(
          packages: package,
          onStart: (updatedExpedition) {
            _refreshData();
          },
          onEdit: (updatedExpedition) {
            _refreshData();
          },
          onDelete: (updatedExpedition) {
            _refreshData();
          },
        ),
      ),
    );
    if (result == true) {
      await _refreshData();
      // Notifier le parent que le partenaire a été mis à jour
      if (widget.onPartnerUpdated != null) {
        widget.onPartnerUpdated!(_partner);
      }
    }
  }

  void _showAchatDetails(BuildContext context, Achat achat) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AchatDetailsSheet(achat: achat);
      },
    );
    if (result == true) {
      await _refreshData();
      // Notifier le parent que le partenaire a été mis à jour
      if (widget.onPartnerUpdated != null) {
        widget.onPartnerUpdated!(_partner);
      }
    }
  }

  Future<void> _showCreateExpeditionBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CreateExpeditionForm(
          clientId: widget.partner.id.toString(),
          onExpeditionCreated: () async {
            await _refreshData();
          },
        );
      },
    );

    if (result == true) {
      await _refreshData();
      // Notifier le parent que le partenaire a été mis à jour
      if (widget.onPartnerUpdated != null) {
        widget.onPartnerUpdated!(_partner);
      }
    }
  }

  Future<void> _showCreateVersementBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return NewVersementModal(
          isVersementScreen: false,
          clientId: widget.partner.id.toString(),
          onVersementCreated: () async {
            await _refreshData();
          },
        );
      },
    );

    if (result == true) {
      await _refreshData();
      // Notifier le parent que le partenaire a été mis à jour
      if (widget.onPartnerUpdated != null) {
        widget.onPartnerUpdated!(_partner);
      }
    }
  }

  Future<void> _showCreateDebtBottomSheet(BuildContext context) async {
    final result = await Navigator.pushNamed(
      context,
      Routes.purchase,
      arguments: {
        'clientId': _partner.id,
        'onPurchaseComplete': (achat) async {
          await _loadDebts();
          setState(() {});
        },
      },
    );
    if (result == true) {
      await _loadDebts();
      setState(() {});
      // Notifier le parent que le partenaire a été mis à jour
      if (widget.onPartnerUpdated != null) {
        widget.onPartnerUpdated!(_partner);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getVersementTypeTranslation(VersementType type) {
    switch (type) {
      case VersementType.General:
        return AppLocalizations.of(context).translate('versement_type_general');
      case VersementType.Dette:
        return AppLocalizations.of(context).translate('versement_type_dette');
      case VersementType.Commande:
        return AppLocalizations.of(context)
            .translate('versement_type_commande');
      case VersementType.CompteBancaire:
        return AppLocalizations.of(context)
            .translate('versement_type_compte_bancaire');
      case VersementType.Autres:
        return AppLocalizations.of(context).translate('versement_type_autres');
    }
  }

  String _getPartnerCurrency() {
    if (_partner.versements == null || _partner.versements!.isEmpty) {
      return 'CNY'; // Default currency if no versements
    }
    final firstVersement = _partner.versements!.first;
    return firstVersement.deviseCode ??
        'CNY'; // Default to CNY if no deviseCode
  }

  Future<void> _showEditVersementModal(Versement versement) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return NewVersementModal(
          isVersementScreen: false,
          clientId: widget.partner.id.toString(),
          versementToEdit: versement,
          onVersementCreated: () async {
            await _refreshData();
          },
        );
      },
    );

    if (result == true) {
      await _refreshData();
      // Notifier le parent que le partenaire a été mis à jour
      if (widget.onPartnerUpdated != null) {
        widget.onPartnerUpdated!(_partner);
      }
    }
  }

  Future<void> _deleteVersement(Versement versement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('confirm_deletion')),
        content: Text(
          AppLocalizations.of(context)
              .translate('confirm_delete_payment')
              .replaceAll('{reference}', versement.reference ?? ''),
        ),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).translate('cancel')),
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

    if (confirmed != true) return;

    try {
      final user = await AuthService().getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('error_user_not_connected'));
        return;
      }

      if (versement.id == null) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('error_payment_not_exists'));
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await VersementServices().delete(versement.id!, user.id);

      Navigator.of(context).pop();

      if (result == "ACHATS_NOT_DELETED") {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('error_cannot_delete_payment_with_purchases'),
        );
      } else if (result == "DELETED") {
        await _refreshData();
        showSuccessTopSnackBar(context,
            AppLocalizations.of(context).translate('payment_deleted_success'));
        // Notifier le parent que le partenaire a été mis à jour
        if (widget.onPartnerUpdated != null) {
          widget.onPartnerUpdated!(_partner);
        }
      } else {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('error_unknown_deletion'));
      }
    } catch (e) {
      Navigator.of(context).pop();
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context)
            .translate('error_during_deletion')
            .replaceAll('{error}', e.toString()),
      );
    }
  }
}
