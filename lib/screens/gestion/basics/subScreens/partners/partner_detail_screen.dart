import 'package:bbd_limited/screens/gestion/accounts/widgets/versment_detail_modal.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _partner = widget.partner;
    _filteredVersements = _partner.versements;
  }

  Future<void> _refreshVersements() async {
    setState(() {
      _partner = widget.partner;
    });
  }

  void _filterVersements(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVersements = _partner.versements;
      } else {
        _filteredVersements =
            _partner.versements?.where((versement) {
              final reference = versement.reference?.toLowerCase() ?? '';
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
          onPressed: () {},
          label: Text(
            'Nouveau versement',
            style: TextStyle(color: Colors.white),
          ),
          icon: Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBalanceCard(currencyFormat, context),
            const SizedBox(height: 16),
            _buildVersementsList(currencyFormat, context),
          ],
        ),
      ),
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
              'Historique des opérations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterVersements,
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
          ),
          RefreshIndicator(
            onRefresh: _refreshVersements,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
