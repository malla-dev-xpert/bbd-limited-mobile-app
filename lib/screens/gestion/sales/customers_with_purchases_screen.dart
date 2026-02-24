import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/screens/gestion/sales/customer_purchases_page.dart';
import 'package:intl/intl.dart';

/// Page pleine : liste des clients avec achats (remplace le bottom sheet).
class CustomersWithPurchasesScreen extends StatefulWidget {
  const CustomersWithPurchasesScreen({super.key});

  @override
  State<CustomersWithPurchasesScreen> createState() =>
      _CustomersWithPurchasesScreenState();
}

class _CustomersWithPurchasesScreenState
    extends State<CustomersWithPurchasesScreen> {
  final PartnerServices _partnerServices = PartnerServices();
  final TextEditingController _searchController = TextEditingController();

  List<Partner> _allCustomers = [];
  List<Partner> _filteredCustomers = [];
  bool _isLoading = true;

  static const Color _primary = Color(0xFF1A1E49);

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
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('error_loading_clients'));
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

  void _openCustomerPurchasesPage(Partner customer) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CustomerPurchasesPage(customer: customer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = DeviceBreakpoints.isTablet(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Clients avec achats',
          style: AppTextSize.titleStyle(context, color: Colors.white),
        ),
        backgroundColor: _primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: AppSpacing.screen(context),
              child: TextField(
                controller: _searchController,
                onChanged: _filterCustomers,
                decoration: InputDecoration(
                  hintText: 'Rechercher un client...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    borderSide: const BorderSide(color: _primary),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                style: AppTextSize.bodyStyle(context),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primary),
                    )
                  : _filteredCustomers.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: AppSpacing.xxl * 2,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: AppSpacing.lg),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'Aucun client avec achats'
                                      : 'Aucun client trouvé',
                                  style: AppTextSize.titleStyle(context,
                                      color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: AppSpacing.sm),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'Les clients apparaîtront ici après leurs premiers achats'
                                      : 'Essayez avec d\'autres termes de recherche',
                                  style: AppTextSize.bodyStyle(context,
                                      color: Colors.grey[500]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? AppSpacing.xl : AppSpacing.lg,
                          ),
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = _filteredCustomers[index];
                            final totalPurchases =
                                _getTotalPurchases(customer);
                            final totalAmount = _getTotalAmount(customer);

                            return Padding(
                              padding: EdgeInsets.only(bottom: AppSpacing.md),
                              child: _CustomerCard(
                                customer: customer,
                                totalPurchases: totalPurchases,
                                totalAmount: totalAmount,
                                onTap: () =>
                                    _openCustomerPurchasesPage(customer),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Partner customer;
  final int totalPurchases;
  final double totalAmount;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.totalPurchases,
    required this.totalAmount,
    required this.onTap,
  });

  static const Color _primary = Color(0xFF1A1E49);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.lg),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: AppSpacing.sm,
                offset: Offset(0, AppSpacing.xs),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: AppSpacing.xxl + AppSpacing.md,
                height: AppSpacing.xxl + AppSpacing.md,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primary,
                      _primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.lg),
                ),
                child: Center(
                  child: Text(
                    '${customer.firstName.isNotEmpty ? customer.firstName[0] : ''}${customer.lastName.isNotEmpty ? customer.lastName[0] : ''}'
                        .toUpperCase(),
                    style: AppTextSize.titleStyle(context,
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${customer.firstName} ${customer.lastName}',
                      style: AppTextSize.subtitleStyle(context,
                          color: _primary, fontWeight: FontWeight.w600),
                    ),
                    if (customer.phoneNumber.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        customer.phoneNumber,
                        style: AppTextSize.bodyStyle(context,
                            color: Colors.grey[600]),
                      ),
                    ],
                    SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _StatChip(
                          icon: Icons.shopping_cart,
                          text: '$totalPurchases achats',
                          color: const Color(0xFF42A5F5),
                        ),
                        _StatChip(
                          icon: Icons.currency_yen,
                          text: NumberFormat.currency(
                            locale: 'fr_FR',
                            symbol: 'CNY',
                          ).format(totalAmount),
                          color: const Color(0xFF66BB6A),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: AppTextSize.body(context),
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppTextSize.caption(context) + 2, color: color),
          SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTextSize.bodyStyle(context,
                fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }
}
