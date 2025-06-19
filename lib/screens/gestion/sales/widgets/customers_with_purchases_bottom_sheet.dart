import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:intl/intl.dart';
import 'customer_purchases_dialog.dart';

class CustomersWithPurchasesBottomSheet extends StatefulWidget {
  final Function(Partner)? onCustomerSelected;

  const CustomersWithPurchasesBottomSheet({
    Key? key,
    this.onCustomerSelected,
  }) : super(key: key);

  @override
  State<CustomersWithPurchasesBottomSheet> createState() =>
      _CustomersWithPurchasesBottomSheetState();
}

class _CustomersWithPurchasesBottomSheetState
    extends State<CustomersWithPurchasesBottomSheet> {
  final PartnerServices _partnerServices = PartnerServices();
  final TextEditingController _searchController = TextEditingController();

  List<Partner> _allCustomers = [];
  List<Partner> _filteredCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomersWithPurchases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomersWithPurchases() async {
    try {
      setState(() => _isLoading = true);

      final customers = await _partnerServices.findCustomers(page: 0);

      // Filtrer seulement les clients qui ont des achats
      final customersWithPurchases = customers.where((customer) {
        return customer.versements?.any((versement) =>
                versement.achats != null && versement.achats!.isNotEmpty) ??
            false;
      }).toList();

      setState(() {
        _allCustomers = customersWithPurchases;
        _filteredCustomers = customersWithPurchases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showErrorTopSnackBar(context, "Erreur lors du chargement des clients");
      }
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _allCustomers;
      } else {
        _filteredCustomers = _allCustomers.where((customer) {
          final fullName =
              '${customer.firstName} ${customer.lastName}'.toLowerCase();
          final phone = customer.phoneNumber.toLowerCase();
          final email = customer.email.toLowerCase();
          final searchLower = query.toLowerCase();

          return fullName.contains(searchLower) ||
              phone.contains(searchLower) ||
              email.contains(searchLower);
        }).toList();
      }
    });
  }

  int _getTotalPurchases(Partner customer) {
    num total = 0;
    for (var versement in customer.versements ?? []) {
      final achats = versement.achats;
      if (achats != null) {
        total += achats.length;
      }
    }
    return total.toInt();
  }

  double _getTotalAmount(Partner customer) {
    double total = 0;
    for (var versement in customer.versements ?? []) {
      for (var achat in versement.achats ?? []) {
        total += achat.montantTotal ?? 0;
      }
    }
    return total;
  }

  void _showCustomerPurchasesDialog(Partner customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomerPurchasesDialog(
          customer: customer,
          onCustomerSelected: widget.onCustomerSelected,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header avec drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Titre et barre de recherche
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Clients avec achats',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1E49),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: _filterCustomers,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un client...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1A1E49)),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ],
            ),
          ),

          // Liste des clients
          Flexible(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1A1E49),
                    ),
                  )
                : _filteredCustomers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Aucun client avec achats'
                                  : 'Aucun client trouvé',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Les clients apparaîtront ici après leurs premiers achats'
                                  : 'Essayez avec d\'autres termes de recherche',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          final totalPurchases = _getTotalPurchases(customer);
                          final totalAmount = _getTotalAmount(customer);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  _showCustomerPurchasesDialog(customer);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF1A1E49),
                                              const Color(0xFF1A1E49)
                                                  .withOpacity(0.8),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${customer.firstName[0]}${customer.lastName[0]}'
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 16),

                                      // Informations du client
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${customer.firstName} ${customer.lastName}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1A1E49),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              customer.phoneNumber,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                _buildStatChip(
                                                  Icons.shopping_cart,
                                                  '$totalPurchases achats',
                                                  Colors.blue,
                                                ),
                                                const SizedBox(width: 8),
                                                _buildStatChip(
                                                  Icons.currency_yen,
                                                  NumberFormat.currency(
                                                    locale: 'fr_FR',
                                                    symbol: 'CNY',
                                                  ).format(totalAmount),
                                                  Colors.green,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 16),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
