import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:intl/intl.dart';
import 'achat_details_sheet.dart';

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
  final TextEditingController _searchController = TextEditingController();
  Status? _selectedStatus;

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
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)
                        .translate('purchase_history_search_hint'),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF1A1E49)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _filterAchats();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
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
                            fontSize: 14,
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
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
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
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    achat.isDebt == true
                                                        ? '${AppLocalizations.of(context).translate('purchase_history_date')}: ${DateFormat('dd/MM/yyyy HH:mm').format(achat.createdAt ?? DateTime.now())}'
                                                        : '${AppLocalizations.of(context).translate('purchase_history_reference')}: ${achat.referenceVersement ?? "N/A"}',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (achat.isDebt == true)
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                                0xFF7F78AF)
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                            color: const Color(
                                                                0xFF7F78AF)),
                                                      ),
                                                      child: Text(
                                                        AppLocalizations.of(
                                                                context)
                                                            .translate(
                                                                'purchase_history_debt'),
                                                        style: const TextStyle(
                                                          color:
                                                              Color(0xFF7F78AF),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    )
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                        achat.status)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                achat.status?.name ==
                                                        "COMPLETED"
                                                    ? AppLocalizations.of(
                                                            context)
                                                        .translate(
                                                            'purchase_history_filter_completed')
                                                    : achat.status?.name ==
                                                            "PENDING"
                                                        ? AppLocalizations.of(
                                                                context)
                                                            .translate(
                                                                'purchase_history_filter_pending')
                                                        : achat.status?.name ??
                                                            "N/A",
                                                style: TextStyle(
                                                  color: _getStatusColor(
                                                      achat.status),
                                                  fontWeight: FontWeight.w500,
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
                                                        achat
                                                            .client!.isNotEmpty)
                                                    ? achat.client!
                                                    : (achat.isDebt == true &&
                                                            achat.clientId !=
                                                                null)
                                                        ? '${AppLocalizations.of(context).translate('client')} #${achat.clientId}'
                                                        : "N/A",
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
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)
                                                  .translate(
                                                      'purchase_history_total_amount'),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_formatAmount(achat.montantTotal)} ¥',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1A1E49),
                                              ),
                                            ),
                                          ],
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
                      fontSize: 14,
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
}
