import 'package:bbd_limited/screens/gestion/accounts/widgets/versment_detail_modal.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/create_paiement.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/expedition.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/expedition/widgets/expedition_list_item.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/expedition/widgets/expedition_details_bottom_sheet.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/expedition/widgets/create_expedition_form.dart';
import 'package:intl/intl.dart';

enum OperationType { versements, expeditions }

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
  List<Expedition>? _filteredExpeditions;
  OperationType _selectedOperationType = OperationType.versements;

  @override
  void initState() {
    super.initState();
    _partner = widget.partner;
    _filteredVersements = _partner.versements;
    _filteredExpeditions = _partner.expeditions;
  }

  Future<void> _refreshData() async {
    setState(() {
      _partner = widget.partner;
      _filteredVersements = _partner.versements;
      _filteredExpeditions = _partner.expeditions;
    });
  }

  void _filterOperations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVersements = _partner.versements;
        _filteredExpeditions = _partner.expeditions;
      } else {
        _filteredVersements =
            _partner.versements?.where((versement) {
              final reference = versement.reference?.toLowerCase() ?? '';
              final searchLower = query.toLowerCase();
              return reference.contains(searchLower);
            }).toList();

        _filteredExpeditions =
            _partner.expeditions?.where((expedition) {
              final reference = expedition.ref?.toLowerCase() ?? '';
              final searchLower = query.toLowerCase();
              return reference.contains(searchLower);
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            } else {
              _showCreateExpeditionBottomSheet(context);
            }
          },
          label: Text(
            _selectedOperationType == OperationType.versements
                ? 'Nouveau versement'
                : 'Nouvelle expédition',
            style: TextStyle(color: Colors.white),
          ),
          icon: Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBalanceCard(currencyFormat, context),
            const SizedBox(height: 30),
            _buildOperationTypeSelector(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 8),
            _buildOperationsList(currencyFormat, context),
          ],
        ),
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
          const SizedBox(width: 10),
          Expanded(
            child: _buildOperationTypeButton(
              OperationType.expeditions,
              'Expéditions',
              Icons.local_shipping_outlined,
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7F78AF) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
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
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: _searchController,
        onChanged: _filterOperations,
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(vertical: 0),
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
    } else {
      return _buildExpeditionsList(context);
    }
  }

  Widget _buildExpeditionsList(BuildContext context) {
    if (_filteredExpeditions == null || _filteredExpeditions!.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.2,
        ),
        child: Center(
          child: Text(
            'Aucune expédition trouvée.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              'Historique des expéditions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _filteredExpeditions?.length ?? 0,
              itemBuilder: (context, index) {
                final expedition = _filteredExpeditions![index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ExpeditionListItem(
                    expedition: expedition,
                    onTap: () => _showExpeditionDetails(context, expedition),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showExpeditionDetails(BuildContext context, Expedition expedition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ExpeditionDetailsBottomSheet(
          expedition: expedition,
          onStart: (updatedExpedition) {
            _refreshData();
          },
          onEdit: (updatedExpedition) {
            _refreshData();
          },
          onDelete: (updatedExpedition) {
            _refreshData();
          },
        );
      },
    );
  }

  Widget _buildBalanceCard(NumberFormat currencyFormat, BuildContext context) {
    final balance = _partner.balance ?? 0.0;
    final isNegative = balance <= 0;
    final statusColor = isNegative ? Colors.red[200] : Colors.green[200];

    final totalVersement =
        _partner.versements?.fold(
          0.0,
          (sum, versement) => sum + (versement.montantVerser ?? 0.0),
        ) ??
        0.0;

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
              opacity: 0.1, // Augmentation de l'opacité

              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/ports.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center, // Centrage de l'image
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
                        color: Colors.blue[50],
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
                          "Montant total versé",
                          style: TextStyle(color: Colors.grey[50]),
                        ),
                        Text(
                          currencyFormat.format(totalVersement),
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

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              'Historique des versements',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _filteredVersements?.length ?? 0,
              itemBuilder: (context, index) {
                final versement = _filteredVersements![index];
                final montantRestant = versement.montantRestant ?? 0.0;
                final isNegative = montantRestant < 0;
                final statusColor =
                    isNegative ? Colors.red[400] : Colors.green[400];

                return Container(
                  padding: EdgeInsets.all(0),
                  child: ListTile(
                    onTap:
                        () =>
                            showVersementDetailsBottomSheet(context, versement),
                    title: Text(
                      versement.reference ?? 'Sans référence',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      versement.createdAt != null
                          ? DateFormat(
                            'dd/MM/yyyy',
                          ).format(versement.createdAt!)
                          : 'Date inconnue',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 5,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(versement.montantVerser),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              currencyFormat.format(versement.montantRestant),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          isNegative
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: statusColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
        return CreateExpeditionForm();
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
        return CreatePaiementModal();
      },
    );

    if (result == true) {
      _refreshData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
