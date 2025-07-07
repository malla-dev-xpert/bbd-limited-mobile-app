import 'package:flutter/material.dart';
import 'historique_achats_screen.dart';
import 'widgets/customers_with_purchases_bottom_sheet.dart';
import 'package:bbd_limited/models/partner.dart';
import 'widgets/purchase_wizard_dialog.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:intl/intl.dart';

class SalesHomeScreen extends StatefulWidget {
  const SalesHomeScreen({super.key});

  @override
  State<SalesHomeScreen> createState() => _SalesHomeScreenState();
}

class _SalesHomeScreenState extends State<SalesHomeScreen> {
  int achatsDuMoisCount = 0;
  double chiffreAffaires = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => isLoading = true);
    try {
      final achats = await AchatServices().findAll();
      final now = DateTime.now();
      // Filtrer les achats du mois courant
      final achatsDuMois = achats
          .where((achat) =>
              achat.createdAt != null &&
              achat.createdAt!.year == now.year &&
              achat.createdAt!.month == now.month)
          .toList();

      final int count = achatsDuMois.length;
      final double total = achatsDuMois.fold(
          0.0, (sum, achat) => sum + (achat.montantTotal ?? 0.0));

      setState(() {
        achatsDuMoisCount = count;
        chiffreAffaires = total;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        achatsDuMoisCount = 0;
        chiffreAffaires = 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Gestion des achats',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1A1E49),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec statistiques
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1A1E49),
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              context,
                              'Achats du mois',
                              isLoading ? '...' : achatsDuMoisCount.toString(),
                              Icons.calendar_month,
                              Colors.white,
                            ),
                            _buildStatItem(
                              context,
                              'Chiffre d\'affaires',
                              isLoading
                                  ? '...'
                                  : NumberFormat.currency(
                                          locale: 'fr_FR', symbol: '¥')
                                      .format(chiffreAffaires),
                              Icons.currency_yen,
                              Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Section des actions rapides
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Actions rapides',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildActionCard(
                      context,
                      'Nouveau achat',
                      Icons.add_shopping_cart,
                      () {
                        showDialog(
                          context: context,
                          builder: (context) => const PurchaseWizardDialog(),
                        );
                      },
                      Colors.blue,
                    ),
                    _buildActionCard(
                      context,
                      'Historique',
                      Icons.history,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoriqueAchatsScreen(),
                        ),
                      ),
                      Colors.orange,
                    ),
                    _buildActionCard(
                      context,
                      'Clients',
                      Icons.people,
                      () => _showCustomersWithPurchases(context),
                      Colors.green,
                    ),
                    _buildActionCard(
                      context,
                      'Rapports',
                      Icons.bar_chart,
                      () {},
                      Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 32,
            color: color,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: color.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomersWithPurchases(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) =>
            CustomersWithPurchasesBottomSheet(
          onCustomerSelected: (Partner customer) {
            print(
                'Client sélectionné: [200m${customer.firstName} ${customer.lastName}[0m');
          },
        ),
      ),
    );
  }
}
