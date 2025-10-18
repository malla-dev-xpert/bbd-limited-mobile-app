import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:intl/intl.dart';
import 'achat_details_sheet.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/components/confirm_btn.dart';

class HistoriqueAchatsScreen extends StatefulWidget {
  const HistoriqueAchatsScreen({super.key});

  @override
  State<HistoriqueAchatsScreen> createState() => _HistoriqueAchatsScreenState();
}

class _HistoriqueAchatsScreenState extends State<HistoriqueAchatsScreen> {
  final AchatServices _achatsService = AchatServices();
  List<Achat> _achats = [];
  List<Achat> _filteredAchats = [];
  bool _isLoading = true;
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  Status? _selectedStatus;
  bool _showItemsDirectly =
      false; // Mode d'affichage: false = achats, true = items
  final Set<String> confirmedArticles = {};

  @override
  void initState() {
    super.initState();
    _chargerAchats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chargerAchats() async {
    final achats = await _achatsService.findAll();
    setState(() {
      _achats = achats;
      _filteredAchats = achats;
      _isLoading = false;
    });
  }

  void _filterAchats() {
    final searchQuery = _searchController.text.toLowerCase();
    setState(() {
      _filteredAchats = _achats.where((achat) {
        bool matchesSearch;
        if (searchQuery.isEmpty) {
          matchesSearch = true;
        } else {
          // Recherche par référence, client, ou id client si achat en dette
          final refMatch =
              (achat.referenceVersement?.toLowerCase().contains(searchQuery) ??
                  false);
          final clientMatch =
              (achat.client?.toLowerCase().contains(searchQuery) ?? false);
          final clientIdMatch = (achat.isDebt == true && achat.clientId != null)
              ? achat.clientId.toString().contains(searchQuery)
              : false;
          matchesSearch = refMatch || clientMatch || clientIdMatch;
        }

        final matchesStatus =
            _selectedStatus == null || achat.status == _selectedStatus;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('purchase_history_title'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header fixe avec recherche et filtres
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                buildTextField(
                  controller: _searchController,
                  label: AppLocalizations.of(context)
                      .translate('purchase_history_search_hint'),
                  icon: Icons.search,
                  onChanged: (_) => _filterAchats(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          AppLocalizations.of(context)
                              .translate('purchase_history_filter_status'),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatusFilterChip(
                                null,
                                AppLocalizations.of(context)
                                    .translate('purchase_history_filter_all')),
                            _buildStatusFilterChip(
                                Status.COMPLETED,
                                AppLocalizations.of(context).translate(
                                    'purchase_history_filter_completed')),
                            _buildStatusFilterChip(
                                Status.PENDING,
                                AppLocalizations.of(context).translate(
                                    'purchase_history_filter_pending')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Toggle pour afficher les achats ou les items
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildViewModeButton(
                                label: AppLocalizations.of(context).translate(
                                    'purchase_history_view_purchases'),
                                icon: Icons.receipt_long,
                                isSelected: !_showItemsDirectly,
                                onTap: () {
                                  setState(() {
                                    _showItemsDirectly = false;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: _buildViewModeButton(
                                label: AppLocalizations.of(context)
                                    .translate('purchase_history_view_items'),
                                icon: Icons.inventory_2,
                                isSelected: _showItemsDirectly,
                                onTap: () {
                                  setState(() {
                                    _showItemsDirectly = true;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Contenu scrollable
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAchats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)
                                  .translate('purchase_history_no_purchases'),
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _showItemsDirectly
                        ? _buildItemsListView()
                        : RefreshIndicator(
                            onRefresh: _chargerAchats,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredAchats.length,
                              itemBuilder: (context, index) {
                                final achat = _filteredAchats[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
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
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () =>
                                          _showAchatDetails(context, achat),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${AppLocalizations.of(context).translate('purchase_history_date')}: ${DateFormat('dd/MM/yyyy HH:mm').format(achat.createdAt ?? DateTime.now())}',
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (achat.isDebt == true)
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 2),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: const Color(
                                                                    0xFF7F78AF)
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            border: Border.all(
                                                                color: const Color(
                                                                    0xFF7F78AF)),
                                                          ),
                                                          child: Text(
                                                            AppLocalizations.of(
                                                                    context)
                                                                .translate(
                                                                    'purchase_history_debt'),
                                                            style:
                                                                const TextStyle(
                                                              color: Color(
                                                                  0xFF7F78AF),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        )
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                            achat.status)
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    achat.status?.name ==
                                                            AppLocalizations.of(
                                                                    context)
                                                                .translate(
                                                                    'completed')
                                                        ? AppLocalizations.of(
                                                                context)
                                                            .translate(
                                                                'purchase_history_filter_completed')
                                                        : achat.status?.name ==
                                                                AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'pending')
                                                            ? AppLocalizations
                                                                    .of(context)
                                                                .translate(
                                                                    'purchase_history_filter_pending')
                                                            : achat.status
                                                                    ?.name ??
                                                                AppLocalizations.of(
                                                                        context)
                                                                    .translate(
                                                                        'not_available'),
                                                    style: TextStyle(
                                                      color: _getStatusColor(
                                                          achat.status),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.person_outline,
                                                  size: 16,
                                                  color: Colors.grey[700]!,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    (achat.client != null &&
                                                            achat.client!
                                                                .isNotEmpty)
                                                        ? achat.client!
                                                        : (achat.isDebt ==
                                                                    true &&
                                                                achat.clientId !=
                                                                    null)
                                                            ? '${AppLocalizations.of(context).translate('client')} #${achat.clientId}'
                                                            : AppLocalizations
                                                                    .of(context)
                                                                .translate(
                                                                    'not_available'),
                                                    style: TextStyle(
                                                      color: Colors.grey[700]!,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (achat.clientPhone != null) ...[
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.phone_outlined,
                                                    size: 16,
                                                    color: Colors.grey[700]!,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    achat.clientPhone!,
                                                    style: TextStyle(
                                                      color: Colors.grey[700]!,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            const SizedBox(height: 12),
                                            // Informations sur les articles
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: Colors.blue[200]!),
                                              ),
                                              child: Column(
                                                children: [
                                                  _buildArticleInfoRow(
                                                    Icons.inventory_2,
                                                    AppLocalizations.of(context)
                                                        .translate(
                                                            'total_items'),
                                                    '${achat.items?.length ?? 0}',
                                                    Colors.blue[700]!,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  _buildArticleInfoRow(
                                                    Icons.check_circle,
                                                    AppLocalizations.of(context)
                                                        .translate(
                                                            'delivered_items'),
                                                    '${_getDeliveredItemsCount(achat)}/${_getTotalInvoicesCount(achat)}',
                                                    Colors.green[700]!,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  _buildArticleInfoRow(
                                                    Icons.business,
                                                    AppLocalizations.of(context)
                                                        .translate('suppliers'),
                                                    _getSuppliersInfo(achat),
                                                    Colors.orange[700]!,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            // Montant total
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1A1E49)
                                                    .withOpacity(0.05),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color:
                                                        const Color(0xFF1A1E49)
                                                            .withOpacity(0.2)),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    AppLocalizations.of(context)
                                                        .translate(
                                                            'purchase_history_total_amount'),
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${_formatAmount(achat.montantTotal)} ¥',
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF1A1E49),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
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

  Color _getStatusColor(Status? status) {
    switch (status) {
      case Status.PENDING:
        return Colors.amber;
      case Status.COMPLETED:
        return Colors.green;
      case Status.DELETE:
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  // Méthode pour obtenir les informations sur les fournisseurs
  String _getSuppliersInfo(Achat achat) {
    if (achat.items == null || achat.items!.isEmpty) {
      return AppLocalizations.of(context).translate('none');
    }

    final suppliers = <String>{};
    for (var item in achat.items!) {
      if (item.supplierName != null && item.supplierName!.isNotEmpty) {
        suppliers.add(item.supplierName!);
      }
    }

    if (suppliers.isEmpty) {
      return AppLocalizations.of(context).translate('none');
    }

    if (suppliers.length == 1) {
      return AppLocalizations.of(context).translate('same_supplier');
    } else {
      return '${suppliers.length}';
    }
  }

  // Méthode pour construire une ligne d'information sur les articles
  Widget _buildArticleInfoRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showAchatDetails(BuildContext context, Achat achat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AchatDetailsSheet(achat: achat),
    );
  }

  Widget _buildStatusFilterChip(Status? status, String label) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedStatus = isSelected ? null : status;
                _filterAchats();
              });
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1A1E49) : Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFF1A1E49) : Colors.grey[300]!,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1A1E49).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1E49) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> confirmArticle(String itemId, Achat achat) async {
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
      final result = await _achatsService.confirmDelivery(
        itemIds: [int.parse(itemId)],
        userId: user.id,
      );

      if (result.isSuccess) {
        setState(() {
          confirmedArticles.add(itemId);
          // Met à jour le statut de l'article dans la liste locale
          for (var a in _achats) {
            final idx =
                a.items?.indexWhere((i) => i.id?.toString() == itemId) ?? -1;
            if (idx != -1) {
              a.items![idx].status = Status.RECEIVED;
            }
          }
          // Met à jour aussi dans les achats filtrés
          for (var a in _filteredAchats) {
            final idx =
                a.items?.indexWhere((i) => i.id?.toString() == itemId) ?? -1;
            if (idx != -1) {
              a.items![idx].status = Status.RECEIVED;
            }
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

  void _showEditArticleDialog(Items item, Achat achat) async {
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
                                            invoiceNumber: item.invoiceNumber,
                                          );
                                          final itemServices = ItemServices();
                                          final result =
                                              await itemServices.updateItem(
                                            itemId: item.id!,
                                            userId: user.id,
                                            clientId: achat.clientId ?? 0,
                                            item: updatedItem,
                                          );
                                          if (result == 'SUCCESS') {
                                            setState(() {
                                              // Mettre à jour l'item dans tous les achats
                                              for (var a in _achats) {
                                                final idx = a.items?.indexWhere(
                                                        (i) =>
                                                            i.id == item.id) ??
                                                    -1;
                                                if (idx != -1) {
                                                  a.items![idx] = updatedItem;
                                                }
                                              }
                                              for (var a in _filteredAchats) {
                                                final idx = a.items?.indexWhere(
                                                        (i) =>
                                                            i.id == item.id) ??
                                                    -1;
                                                if (idx != -1) {
                                                  a.items![idx] = updatedItem;
                                                }
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

  void _confirmDeleteArticle(Items item, Achat achat) {
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
            Expanded(
              child: Text(
                  AppLocalizations.of(context)
                      .translate('purchase_history_delete_confirm_title'),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
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
              _deleteArticle(item, achat);
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

  void _deleteArticle(Items item, Achat achat) async {
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
      final result = await itemServices.deleteItem(
        item.id!,
        user.id,
        achat.clientId ?? 0,
      );
      if (result == AppLocalizations.of(context).translate('deleted')) {
        setState(() {
          // Supprimer l'item de tous les achats
          for (var a in _achats) {
            a.items?.removeWhere((i) => i.id == item.id);
          }
          for (var a in _filteredAchats) {
            a.items?.removeWhere((i) => i.id == item.id);
          }
        });
        showSuccessTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_item_deleted_success'));
      } else if (result ==
          AppLocalizations.of(context).translate('item_not_found')) {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_item_not_found'));
      } else if (result ==
          AppLocalizations.of(context)
              .translate('client_not_found_or_mismatch')) {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_client_mismatch'));
      } else if (result ==
          AppLocalizations.of(context).translate('user_not_found')) {
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

  Widget _buildItemsListView() {
    // Extraire tous les items de tous les achats filtrés
    final allItems = <Map<String, dynamic>>[];

    for (var achat in _filteredAchats) {
      if (achat.items != null) {
        for (var item in achat.items!) {
          allItems.add({
            'item': item,
            'achat': achat,
          });
        }
      }
    }

    if (allItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)
                  .translate('purchase_history_no_items'),
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _chargerAchats,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: allItems.length,
        itemBuilder: (context, index) {
          final itemData = allItems[index];
          final item = itemData['item'];
          final achat = itemData['achat'] as Achat;

          final isConfirmed = confirmedArticles.contains(item.id?.toString());
          return Container(
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête de l'item avec actions
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
                              item.description ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppLocalizations.of(context).translate('invoice_number')}: ${item.invoiceNumber ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Actions éditer/supprimer
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Color(0xFF1976D2), size: 20),
                            tooltip:
                                AppLocalizations.of(context).translate('edit'),
                            onPressed: () =>
                                _showEditArticleDialog(item, achat),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Color(0xFFD32F2F), size: 20),
                            tooltip: AppLocalizations.of(context)
                                .translate('delete'),
                            onPressed: () => _confirmDeleteArticle(item, achat),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                        ],
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
                      _buildItemDetailChip(
                        '${AppLocalizations.of(context).translate('carton')}: ${item.carton ?? 0}',
                        Icons.inventory,
                      ),
                      const SizedBox(width: 8),
                      _buildItemDetailChip(
                        '${AppLocalizations.of(context).translate('quantity_per_carton_2')}: ${item.quantityPerCarton ?? 0}',
                        Icons.format_list_numbered,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildItemDetailChip(
                        '${AppLocalizations.of(context).translate('total_quantity')}: ${item.quantity ?? 0}',
                        Icons.numbers,
                      ),
                      const SizedBox(width: 8),
                      _buildItemDetailChip(
                        '${_formatAmount(item.unitPrice)} ¥',
                        Icons.attach_money,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Taux d'achat et total en colonne pour une meilleure lisibilité
                  Column(
                    children: [
                      _buildItemDetailChipFullWidth(
                        '${AppLocalizations.of(context).translate('sales_rate')}: ${item.salesRate ?? 0}',
                        Icons.trending_up,
                      ),
                      const SizedBox(height: 8),
                      _buildItemDetailChipFullWidth(
                        '${AppLocalizations.of(context).translate('total')}: ${_formatAmount((item.quantity ?? 0) * (item.unitPrice ?? 0))} ¥',
                        Icons.calculate,
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
                  const SizedBox(height: 12),
                  // Information sur l'achat parent
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.receipt, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${AppLocalizations.of(context).translate('client')}: ${achat.client ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${AppLocalizations.of(context).translate('purchase_history_date')}: ${DateFormat('dd/MM/yyyy').format(achat.createdAt ?? DateTime.now())}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (achat.isDebt == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7F78AF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppLocalizations.of(context)
                                  .translate('purchase_history_debt'),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF7F78AF),
                                fontWeight: FontWeight.bold,
                              ),
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
                            onPressed: () => confirmArticle(
                                item.id?.toString() ?? '', achat),
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
          );
        },
      ),
    );
  }

  Widget _buildItemDetailChip(String text, IconData icon) {
    // Séparer le label et la valeur
    final colonIndex = text.indexOf(':');
    final label = colonIndex != -1 ? text.substring(0, colonIndex + 1) : text;
    final value = colonIndex != -1 ? text.substring(colonIndex + 1).trim() : '';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey[700]),
            const SizedBox(width: 4),
            Flexible(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: label,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (value.isNotEmpty)
                      TextSpan(
                        text: ' $value',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDetailChipFullWidth(String text, IconData icon) {
    // Séparer le label et la valeur
    final colonIndex = text.indexOf(':');
    final label = colonIndex != -1 ? text.substring(0, colonIndex + 1) : text;
    final value = colonIndex != -1 ? text.substring(colonIndex + 1).trim() : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (value.isNotEmpty)
                    TextSpan(
                      text: ' $value',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
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
}
