import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/new_versement.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/create_package_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/package_list_item.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/exchange_rate_service.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/screens/gestion/accounts/versement_detail_screen.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/screens/gestion/sales/achat_details_sheet.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/purchase_dialog.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/package_details_screen.dart';

enum OperationType { versements, expeditions, debts }

class PartnerDetailScreen extends StatefulWidget {
  final Partner partner;

  const PartnerDetailScreen({Key? key, required this.partner})
      : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _partner = widget.partner;
    _filteredVersements = _partner.versements;
    _filteredPackages = _partner.packages;
    _filteredDebts = [];
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
    final achats = await AchatServices().findAll();
    setState(() {
      _filteredDebts = achats
          .where(
              (a) => a.isDebt == true && a.clientPhone == _partner.phoneNumber)
          .toList();
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
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }

  void _filterOperations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVersements = _partner.versements;
        _filteredPackages = _partner.packages;
      } else {
        _filteredVersements = _partner.versements?.where((versement) {
          final reference = versement.reference?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return reference.contains(searchLower);
        }).toList();

        _filteredPackages = _partner.packages?.where((expedition) {
          final reference = expedition.ref?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return reference.contains(searchLower);
        }).toList();
      }
      if (_selectedVersementType != null) {
        _filteredVersements = _filteredVersements?.where((versement) {
          return versement.type ==
              _selectedVersementType!.toString().split('.').last;
        }).toList();
      }
      _sortVersementsByDate();
      _sortExpeditionsByDate();
    });
  }

  Future<void> _calculateTotalVersementsUSD() async {
    if (_partner.versements == null || _partner.versements!.isEmpty) {
      setState(() {
        _totalVersementsUSD = 0.0;
      });
      return;
    }

    double totalUSD = 0.0;
    for (var versement in _partner.versements!) {
      if (versement.montantVerser != null && versement.deviseCode != null) {
        if (versement.deviseCode == 'USD') {
          totalUSD += versement.montantVerser!;
        } else {
          final rate =
              await _exchangeRateService.getExchangeRate(versement.deviseCode!);
          totalUSD += versement.montantVerser! / rate;
        }
      }
    }

    setState(() {
      _totalVersementsUSD = totalUSD;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'CNY',
    );

    final partnerName =
        "${_partner.firstName} ${_partner.lastName} | ${_partner.phoneNumber}";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          partnerName,
          textAlign: TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      floatingActionButton: Container(
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
                ? 'Nouveau versement'
                : _selectedOperationType == OperationType.expeditions
                    ? 'Nouveau colis'
                    : 'Nouvelle dette',
            style: const TextStyle(color: Colors.white),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          _buildBalanceCard(currencyFormat, context),
          const SizedBox(height: 30),
          _buildOperationTypeSelector(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(flex: 3, child: _buildSearchBar()),
              if (_selectedOperationType == OperationType.versements)
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                              final RenderBox button = _filterIconKey
                                  .currentContext!
                                  .findRenderObject() as RenderBox;
                              final RenderBox overlay = Overlay.of(context)
                                  .context
                                  .findRenderObject() as RenderBox;
                              final Offset position = button.localToGlobal(
                                  Offset.zero,
                                  ancestor: overlay);

                              final selected = await showMenu<VersementType?>(
                                context: context,
                                position: RelativeRect.fromLTRB(
                                  position.dx,
                                  position.dy + button.size.height,
                                  position.dx + button.size.width,
                                  overlay.size.height -
                                      (position.dy + button.size.height),
                                ),
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                items: [
                                  const PopupMenuItem<VersementType?>(
                                    value: null,
                                    child: Text(
                                      'Tous les types',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  ...VersementType.values.map(
                                    (type) => PopupMenuItem<VersementType?>(
                                      value: type,
                                      child: Text(
                                        type.toString().split('.').last,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
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
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildOperationsList(currencyFormat, context)),
        ],
      ),
    );
  }

  Widget _buildOperationTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: _buildOperationTypeButton(
              OperationType.versements,
              'Versements',
              Icons.payments_outlined,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _buildOperationTypeButton(
              OperationType.expeditions,
              'Colis',
              Icons.inventory_2,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _buildOperationTypeButton(
              OperationType.debts,
              'Dettes',
              Icons.money_off_csred,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationTypeButton(
    OperationType type,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedOperationType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedOperationType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        constraints: const BoxConstraints(minWidth: 0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7F78AF) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: TextField(
        controller: _searchController,
        onChanged: _filterOperations,
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildOperationsList(
    NumberFormat currencyFormat,
    BuildContext context,
  ) {
    if (_selectedOperationType == OperationType.versements) {
      return _buildVersementsList(currencyFormat, context);
    } else if (_selectedOperationType == OperationType.expeditions) {
      return _buildExpeditionsList(context);
    } else {
      return _buildDebtsList(context);
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
            'Aucun colis trouvé.',
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
      _refreshData();
    }
  }

  Widget _buildBalanceCard(NumberFormat currencyFormat, BuildContext context) {
    final balance = _partner.balance ?? 0.0;
    final isNegative = balance <= 0;
    final statusColor = isNegative ? Colors.red[200] : Colors.green[200];

    return Card(
      elevation: 4,
      color: const Color(0xFF7F78AF),
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/ports.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Balance Actuelle',
                      style: TextStyle(fontSize: 16, color: Colors.grey[50]!),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      isNegative ? Icons.arrow_downward : Icons.arrow_upward,
                      color: statusColor,
                      size: 24,
                    ),
                    Text(
                      currencyFormat.format(balance),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  spacing: 10,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[300]!),
                      ),
                      child: Icon(
                        Icons.attach_money_rounded,
                        color: Colors.blue[600]!,
                        size: 24,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Montant total versé (CNY)",
                          style: TextStyle(color: Colors.grey[50]),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'fr_FR',
                            symbol: 'CNY',
                          ).format(_totalVersementsUSD),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey[100],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersementsList(
    NumberFormat currencyFormat,
    BuildContext context,
  ) {
    if (_partner.versements == null || _partner.versements!.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.2,
        ),
        child: Center(
          child: Text(
            'Aucun versement trouvé.',
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
        padding: const EdgeInsets.only(bottom: 100, left: 10, right: 10),
        itemCount: _filteredVersements?.length ?? 0,
        itemBuilder: (context, index) {
          final versement = _filteredVersements![index];
          final montantRestant = versement.montantRestant ?? 0.0;
          final isNegative = montantRestant < 0;
          final statusColor = isNegative ? Colors.red[400] : Colors.green[400];

          final versementCurrencyFormat = NumberFormat.currency(
            locale: 'fr_FR',
            symbol: versement.deviseCode ?? 'CNY',
          );

          String typeLabel = versement.type != null
              ? versement.type!.substring(0, 1).toUpperCase() +
                  versement.type!.substring(1)
              : 'Type inconnu';

          return Container(
            padding: const EdgeInsets.all(0),
            child: ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VersementDetailScreen(
                    versement: versement,
                    onVersementUpdated: _refreshData,
                  ),
                ),
              ),
              title: Text(
                versement.reference ?? 'Sans référence',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                versement.createdAt != null
                    ? DateFormat('dd/MM/yyyy').format(versement.createdAt!)
                    : 'Date inconnue',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        versementCurrencyFormat.format(versement.montantVerser),
                        style:
                            const TextStyle(fontSize: 13, color: Colors.blue),
                      ),
                      Text(
                        versementCurrencyFormat
                            .format(versement.montantRestant),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isNegative ? Icons.arrow_downward : Icons.arrow_upward,
                    color: statusColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDebtsList(BuildContext context) {
    if (_filteredDebts == null || _filteredDebts!.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.2,
        ),
        child: Center(
          child: Text(
            'Aucune dette trouvée.',
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
        padding: const EdgeInsets.only(bottom: 100, left: 10, right: 10),
        itemCount: _filteredDebts?.length ?? 0,
        itemBuilder: (context, index) {
          final achat = _filteredDebts![index];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showAchatDetails(context, achat),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Identifiant: ${achat.id ?? "N/A"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(achat.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (achat.status == Status.COMPLETED
                              ? "Complété"
                              : achat.status == Status.PENDING
                                  ? "En attente"
                                  : (achat.status != null
                                      ? achat.status.toString().split('.').last
                                      : "N/A")),
                          style: TextStyle(
                            color: _getStatusColor(achat.status),
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
                          achat.client ?? "N/A",
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Montant total',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${achat.montantTotal?.toStringAsFixed(2) ?? "0.00"} ¥',
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
          );
        },
      ),
    );
  }

  Color _getStatusColor(status) {
    final statusStr = status != null ? status.toString().split('.').last : "";
    if (statusStr == "COMPLETED") {
      return Colors.green;
    } else if (statusStr == "PENDING") {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  void _showAchatDetails(BuildContext context, Achat achat) {
    showModalBottomSheet(
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
      _refreshData();
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
    }
  }

  Future<void> _showCreateDebtBottomSheet(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => DebtPurchaseDialog(
        clientId: _partner.id,
        onDebtCreated: () async {
          await _loadDebts();
          setState(() {});
        },
      ),
    );
    if (result == true) {
      await _loadDebts();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
