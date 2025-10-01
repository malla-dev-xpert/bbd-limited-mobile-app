import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbd_limited/providers/reports_provider.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  // États pour gérer l'ouverture/fermeture des sections
  final Map<String, bool> _expandedSections = {
    'products': true,
    'customers': true,
    'suppliers': true,
    'harbors': true,
  };

  // États pour le sélecteur de dates personnalisé
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showCustomDatePicker = false;

  @override
  void initState() {
    super.initState();
    // Charger les rapports au démarrage avec la période par défaut
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).loadReports(ReportPeriod.currentMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Rapports et Statistiques',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1E49),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(reportsProvider.notifier).loadReports(selectedPeriod);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // En-tête avec sélecteur de période
            _buildPeriodSelector(selectedPeriod),

            // Contenu principal
            Expanded(
              child: reportsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : reportsState.error != null
                      ? _buildErrorWidget(reportsState.error!)
                      : _buildReportsContent(reportsState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(ReportPeriod selectedPeriod) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: const Color(0xFF1A1E49),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Période de rapport',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPeriodChip(
                  'Mois en cours',
                  ReportPeriod.currentMonth,
                  selectedPeriod,
                  Icons.calendar_month,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPeriodChip(
                  '3 derniers mois',
                  ReportPeriod.lastThreeMonths,
                  selectedPeriod,
                  Icons.calendar_view_month,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPeriodChip(
                  'Année en cours',
                  ReportPeriod.currentYear,
                  selectedPeriod,
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPeriodChip(
                  'Période personnalisée',
                  ReportPeriod.customRange,
                  selectedPeriod,
                  Icons.date_range,
                ),
              ),
            ],
          ),
          // Sélecteur de dates personnalisé
          if (selectedPeriod == ReportPeriod.customRange) ...[
            const SizedBox(height: 16),
            _buildCustomDateSelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodChip(
    String label,
    ReportPeriod period,
    ReportPeriod selectedPeriod,
    IconData icon,
  ) {
    final isSelected = period == selectedPeriod;

    return GestureDetector(
      onTap: () {
        ref.read(selectedPeriodProvider.notifier).state = period;
        if (period == ReportPeriod.customRange) {
          // Ne pas charger les rapports immédiatement pour la période personnalisée
          // Attendre que l'utilisateur sélectionne les dates
        } else {
          ref.read(reportsProvider.notifier).loadReports(period);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1E49) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A1E49) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur lors du chargement des rapports',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final selectedPeriod = ref.read(selectedPeriodProvider);
              ref.read(reportsProvider.notifier).loadReports(selectedPeriod);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1E49),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(AppLocalizations.of(context).translate('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsContent(ReportStatistics reportsState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Produits les plus achetés
          _buildCollapsibleSection(
            key: 'products',
            title: 'Produits les plus achetés',
            icon: Icons.shopping_bag,
            content: reportsState.topProducts.isNotEmpty
                ? _buildProductsList(reportsState.topProducts)
                : _buildEmptyState('Aucun produit acheté dans cette période'),
          ),

          const SizedBox(height: 16),

          // Clients avec le plus d'achats
          _buildCollapsibleSection(
            key: 'customers',
            title:
                'Clients avec le plus d\'${AppLocalizations.of(context).translate('purchases_count')}',
            icon: Icons.people,
            content: reportsState.topCustomers.isNotEmpty
                ? _buildCustomersList(reportsState.topCustomers)
                : _buildEmptyState(
                    'Aucun client avec des achats dans cette période'),
          ),

          const SizedBox(height: 16),

          // Fournisseurs les plus sollicités
          _buildCollapsibleSection(
            key: 'suppliers',
            title: 'Fournisseurs les plus sollicités',
            icon: Icons.business,
            content: reportsState.topSuppliers.isNotEmpty
                ? _buildSuppliersList(reportsState.topSuppliers)
                : _buildEmptyState(
                    'Aucun fournisseur sollicité dans cette période'),
          ),

          const SizedBox(height: 16),

          // Ports les plus utilisés
          _buildCollapsibleSection(
            key: 'harbors',
            title: 'Ports les plus utilisés',
            icon: Icons.local_shipping,
            content: reportsState.topHarbors.isNotEmpty
                ? _buildHarborsList(reportsState.topHarbors)
                : _buildEmptyState('Aucun port utilisé dans cette période'),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProductsList(List<ProductStat> products) {
    return Column(
      children: products.asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${product.frequency} achats • ${product.totalQuantity.toInt()} unités • ¥${NumberFormat('#,##0.00').format(product.totalValue)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        // const SizedBox(height: 2),
                        // Text(
                        //   'Classé par quantité (70%) et fréquence (30%)',
                        //   style: TextStyle(
                        //     fontSize: 12,
                        //     color: Colors.grey[500],
                        //     fontStyle: FontStyle.italic,
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomersList(List<CustomerStat> customers) {
    return Column(
      children: customers.asMap().entries.map((entry) {
        final index = entry.key;
        final customer = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${customer.purchaseCount} achats • ¥${NumberFormat('#,##0.00').format(customer.totalSpent)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    // const SizedBox(height: 2),
                    // Text(
                    //   'Classé par montant (60%) et fréquence (40%)',
                    //   style: TextStyle(
                    //     fontSize: 12,
                    //     color: Colors.grey[500],
                    //     fontStyle: FontStyle.italic,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuppliersList(List<SupplierStat> suppliers) {
    return Column(
      children: suppliers.asMap().entries.map((entry) {
        final index = entry.key;
        final supplier = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.supplierName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${supplier.itemCount} articles • ${supplier.containerCount} conteneurs • ¥${NumberFormat('#,##0.00').format(supplier.totalValue)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHarborsList(List<HarborStat> harbors) {
    return Column(
      children: harbors.asMap().entries.map((entry) {
        final index = entry.key;
        final harbor = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      harbor.harborName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${harbor.packageCount} colis • ${harbor.containerCount} conteneurs',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String key,
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    final isExpanded = _expandedSections[key] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête cliquable
          InkWell(
            onTap: () {
              setState(() {
                _expandedSections[key] = !isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1E49).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF1A1E49),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1E49),
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF1A1E49),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          // Contenu collapsible
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: content,
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélectionner une période',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  'Date de début',
                  _startDate,
                  (date) {
                    setState(() {
                      _startDate = date;
                    });
                    _loadReportsWithCustomRange();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  'Date de fin',
                  _endDate,
                  (date) {
                    setState(() {
                      _endDate = date;
                    });
                    _loadReportsWithCustomRange();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
      String label, DateTime? date, Function(DateTime?) onDateSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (selectedDate != null) {
              onDateSelected(selectedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                        : 'Sélectionner',
                    style: TextStyle(
                      fontSize: 14,
                      color: date != null ? Colors.grey[800] : Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _loadReportsWithCustomRange() {
    if (_startDate != null && _endDate != null) {
      final customRange = DateRange(startDate: _startDate!, endDate: _endDate!);
      ref.read(customDateRangeProvider.notifier).state = customRange;
      ref.read(reportsProvider.notifier).loadReports(
            ReportPeriod.customRange,
            customRange: customRange,
          );
    }
  }
}
