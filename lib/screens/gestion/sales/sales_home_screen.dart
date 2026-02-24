import 'package:flutter/material.dart';
import 'historique_achats_screen.dart';
import 'customers_with_purchases_screen.dart';
import 'widgets/sales_header.dart';
import 'widgets/sales_stats_card.dart';
import 'widgets/sales_quick_actions.dart';
import 'package:bbd_limited/routes.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:intl/intl.dart';
import 'reports_screen.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

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
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final achats = await AchatServices().findAll();
      if (!mounted) return;
      final now = DateTime.now();
      final achatsDuMois = achats
          .where((achat) =>
              achat.createdAt != null &&
              achat.createdAt!.year == now.year &&
              achat.createdAt!.month == now.month)
          .toList();

      final int count = achatsDuMois.length;
      final double total = achatsDuMois.fold(
          0.0, (sum, achat) => sum + (achat.montantTotal ?? 0.0));

      if (!mounted) return;
      setState(() {
        achatsDuMoisCount = count;
        chiffreAffaires = total;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        achatsDuMoisCount = 0;
        chiffreAffaires = 0;
        isLoading = false;
      });
    }
  }

  List<SalesQuickActionItem> _buildQuickActionItems(AppLocalizations loc) {
    return [
      SalesQuickActionItem(
        label: loc.translate('sales_new_purchase'),
        icon: Icons.add_shopping_cart,
        iconColor: const Color(0xFF42A5F5),
        onTap: () => Navigator.pushNamed(context, Routes.purchase),
      ),
      SalesQuickActionItem(
        label: loc.translate('sales_history'),
        icon: Icons.history,
        iconColor: const Color(0xFFFFA726),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HistoriqueAchatsScreen(),
          ),
        ),
      ),
      SalesQuickActionItem(
        label: loc.translate('sales_customers'),
        icon: Icons.people,
        iconColor: const Color(0xFF66BB6A),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CustomersWithPurchasesScreen(),
          ),
        ),
      ),
      SalesQuickActionItem(
        label: loc.translate('sales_reports'),
        icon: Icons.bar_chart,
        iconColor: const Color(0xFFAB47BC),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReportsScreen(),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isTablet = DeviceBreakpoints.isTablet(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: SalesHeader(
        title: loc.translate('sales_management_title'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppSpacing.screen(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SalesStatsCard(
                  monthlyPurchasesLabel:
                      loc.translate('sales_monthly_purchases'),
                  monthlyPurchasesValue: achatsDuMoisCount.toString(),
                  revenueLabel: loc.translate('sales_revenue'),
                  revenueValue: NumberFormat.currency(
                    locale: 'fr_FR',
                    symbol: '¥',
                  ).format(chiffreAffaires),
                  isLoading: isLoading,
                ),
                SizedBox(
                  height: isTablet ? AppSpacing.xxl : AppSpacing.xl,
                ),
                SalesQuickActions(
                  sectionTitle: loc.translate('sales_quick_actions'),
                  items: _buildQuickActionItems(loc),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
