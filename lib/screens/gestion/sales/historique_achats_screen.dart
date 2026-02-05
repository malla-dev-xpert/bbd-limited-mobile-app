import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/achats/update_achat_dto.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'achat_detail_screen.dart';
import 'package:bbd_limited/screens/gestion/sales/edit_article_screen.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/item_detail_chip.dart';

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
                                return Slidable(
                                  key: ValueKey('achat_${achat.id ?? index}'),
                                  endActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    extentRatio: 0.25,
                                    children: [
                                      SlidableAction(
                                        onPressed: (_) =>
                                            _showEditDateDialog(achat),
                                        backgroundColor:
                                            const Color(0xFF1976D2),
                                        foregroundColor: Colors.white,
                                        icon: Icons.edit_calendar,
                                        label: AppLocalizations.of(context)
                                            .translate('edit_date'),
                                      ),
                                    ],
                                  ),
                                  child: Container(
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
                                                          '${AppLocalizations.of(context).translate('purchase_number')} : ${achat.id ?? 'N/A'}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .calendar_today,
                                                              size: 16,
                                                              color: Colors
                                                                  .grey[700]!,
                                                            ),
                                                            const SizedBox(
                                                                width: 6),
                                                            Text(
                                                              DateFormat(
                                                                      'dd/MM/yyyy')
                                                                  .format(achat
                                                                          .createdAt ??
                                                                      DateTime
                                                                          .now()),
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .grey[700]!,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        if (achat.isDebt ==
                                                            true)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 8),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          16,
                                                                      vertical:
                                                                          2),
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
                                                            ),
                                                          )
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 20),
                                                  Image.asset(
                                                    achat.status ==
                                                            Status.COMPLETED
                                                        ? 'assets/images/delivery.png'
                                                        : 'assets/images/no-delivery.png',
                                                    width: 44,
                                                    height: 44,
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
                                                                      .of(
                                                                          context)
                                                                  .translate(
                                                                      'not_available'),
                                                      style: TextStyle(
                                                        color:
                                                            Colors.grey[700]!,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (achat.clientPhone !=
                                                  null) ...[
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
                                                        color:
                                                            Colors.grey[700]!,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              const SizedBox(height: 12),
                                              // Informations sur les articles
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(16),
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
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate(
                                                              'total_items'),
                                                      '${achat.items?.length ?? 0}',
                                                      Colors.blue[700]!,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    _buildArticleInfoRow(
                                                      Icons.check_circle,
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate(
                                                              'delivered_items'),
                                                      '${_getDeliveredItemsCount(achat)}/${_getTotalInvoicesCount(achat)}',
                                                      Colors.green[700]!,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    _buildArticleInfoRow(
                                                      Icons.business,
                                                      AppLocalizations.of(
                                                              context)
                                                          .translate(
                                                              'suppliers'),
                                                      _getSuppliersInfo(achat),
                                                      Colors.orange[700]!,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              // Montant total
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF1A1E49)
                                                      .withOpacity(0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: const Color(
                                                              0xFF1A1E49)
                                                          .withOpacity(0.2)),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      AppLocalizations.of(
                                                              context)
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
                                                        color:
                                                            Color(0xFF1A1E49),
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
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => AchatDetailScreen(achat: achat),
      ),
    ).then((_) => setState(() {}));
  }

  void _showEditDateDialog(Achat achat) {
    DateTime selectedDate = achat.createdAt ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context).translate('edit_date')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppLocalizations.of(context).translate('purchase_number')} : ${achat.id ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  selectedDate = picked;
                  (context as Element).markNeedsBuild();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          confirmationButton(
            isLoading: isLoading,
            onPressed: () => _updateAchatDate(achat, selectedDate),
            label: AppLocalizations.of(context).translate('save'),
            icon: Icons.save,
            subLabel: AppLocalizations.of(context).translate('saving'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAchatDate(Achat achat, DateTime newDate) async {
    if (achat.id == null) return;

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

      final dto = UpdateAchatDto(createdAt: newDate);
      final result = await _achatsService.updateAchat(
        achatId: achat.id!,
        userId: user.id,
        dto: dto,
      );

      if (result.isSuccess) {
        setState(() {
          // Mettre à jour la date dans la liste locale
          for (int i = 0; i < _achats.length; i++) {
            if (_achats[i].id == achat.id) {
              _achats[i] = _achats[i].copyWith(createdAt: newDate);
            }
          }
          for (int i = 0; i < _filteredAchats.length; i++) {
            if (_filteredAchats[i].id == achat.id) {
              _filteredAchats[i] =
                  _filteredAchats[i].copyWith(createdAt: newDate);
            }
          }
        });
        showSuccessTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('date_updated_successfully'));
        Navigator.pop(context);
      } else {
        showErrorTopSnackBar(
            context,
            result.errorMessage ??
                AppLocalizations.of(context).translate('error_updating_date'));
      }
    } catch (e) {
      showErrorTopSnackBar(context,
          AppLocalizations.of(context).translate('error_updating_date'));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
              _updateAchatStatusFromItems(a);
            }
          }
          // Met à jour aussi dans les achats filtrés
          for (var a in _filteredAchats) {
            final idx =
                a.items?.indexWhere((i) => i.id?.toString() == itemId) ?? -1;
            if (idx != -1) {
              a.items![idx].status = Status.RECEIVED;
              _updateAchatStatusFromItems(a);
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

  void _showEditArticleDialog(Items item, Achat achat) async {
    final updated = await Navigator.push<Items>(
      context,
      MaterialPageRoute(
        builder: (context) => EditArticleScreen(item: item, achat: achat),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        for (var a in _achats) {
          final idx = a.items?.indexWhere((i) => i.id == updated.id) ?? -1;
          if (idx != -1) {
            a.items![idx] = updated;
            break;
          }
        }
        for (var a in _filteredAchats) {
          final idx = a.items?.indexWhere((i) => i.id == updated.id) ?? -1;
          if (idx != -1) {
            a.items![idx] = updated;
            break;
          }
        }
      });
    }
  }

    void _confirmReverseArticle(Items item, Achat achat) {
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
                      .translate('purchase_history_reverse_confirm_title'),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
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
              _reverseItem(item, achat);
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

  void _reverseItem(Items item, Achat achat) async {
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
        achat.clientId ?? 0,
      );
      if (result == "DELETED_AND_REVERTED") {
        setState(() {
          // Mettre à jour le statut de l'item reversé et recalculer le statut de l'achat
          for (var a in _achats) {
            final itemIndex = a.items?.indexWhere((i) => i.id == item.id) ?? -1;
            if (itemIndex != -1) {
              a.items![itemIndex].status = Status.PENDING;
              _updateAchatStatusFromItems(a);
            }
          }
          for (var a in _filteredAchats) {
            final itemIndex = a.items?.indexWhere((i) => i.id == item.id) ?? -1;
            if (itemIndex != -1) {
              a.items![itemIndex].status = Status.PENDING;
              _updateAchatStatusFromItems(a);
            }
          }
        });
        showSuccessTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('purchase_history_item_reversed_success'));
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

  Future<void> _handleDeleteItem(Items item, Achat achat) async {
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
          achat.items?.removeWhere((i) => i.id == item.id);
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
          return Slidable(
            key: ValueKey('item_${item.id ?? index}'),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.35,
              children: [
                SlidableAction(
                  onPressed: (_) => _showEditArticleDialog(item, achat),
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  icon: Icons.edit,
                  label: AppLocalizations.of(context).translate('edit'),
                ),
                SlidableAction(
                  onPressed: (item.status == Status.RECEIVED)
                      ? (_) => _confirmReverseArticle(item, achat)
                      : null,
                  backgroundColor: (item.status == Status.RECEIVED)
                      ? Colors.orange
                      : Colors.grey[300]!,
                  foregroundColor: Colors.white,
                  icon: Icons.undo_outlined,
                  label: AppLocalizations.of(context).translate('reverse'),
                ),
                SlidableAction(
                  onPressed: (item.status != Status.RECEIVED)
                      ? (_) => _handleDeleteItem(item, achat)
                      : null,
                  backgroundColor: (item.status != Status.RECEIVED)
                      ? Colors.red
                      : Colors.grey[300]!,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: AppLocalizations.of(context).translate('delete'),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête de l'item avec image de statut
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
                        const SizedBox(width: 12),
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
                          text: '${_formatAmount(item.unitPrice)} ¥',
                          icon: Icons.attach_money,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Poids et CBN (0 si null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ItemDetailChip(
                          text:
                              '${AppLocalizations.of(context).translate('weight')}: ${item.weight ?? 0}',
                          icon: Icons.scale,
                        ),
                        const SizedBox(width: 16),
                        ItemDetailChip(
                          text:
                              '${AppLocalizations.of(context).translate('cbn')}: ${item.cbn ?? 0}',
                          icon: Icons.straighten,
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
                              '${AppLocalizations.of(context).translate('total')}: ${_formatAmount((item.quantity ?? 0) * (item.unitPrice ?? 0))} ¥',
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
                          Icon(Icons.receipt,
                              size: 16, color: Colors.blue[700]),
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
