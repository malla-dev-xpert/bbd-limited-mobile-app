import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbd_limited/providers/reports_provider.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final Map<String, bool> _expandedSections = {
    'customers': true,
    'suppliers': true,
    'products': true,
    'harbors': true,
  };
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).loadReports(ReportPeriod.currentWeek);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Rapports et Statistiques',
          style: AppTextSize.headlineStyle(context,
                  color: Colors.white)
              .copyWith(letterSpacing: 0.5, fontWeight: FontWeight.w600),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(reportsProvider.notifier).loadReports(selectedPeriod);
        },
        child: SafeArea(
          child: Column(
            children: [
              // En-tête avec sélecteur de période (simplifié)
              _buildPeriodSelector(selectedPeriod),

              // Contenu principal
              Expanded(
                child: reportsState.isLoading
                    ? _buildSkeletonLoader()
                    : reportsState.error != null
                        ? _buildErrorWidget(reportsState.error!)
                        : _buildReportsContent(reportsState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(ReportPeriod selectedPeriod) {
    return Container(
      margin: const EdgeInsets.all(16),
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
        children: [
          // En-tête cliquable
          InkWell(
            onTap: () {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.filter_list,
                      color: const Color(0xFF1A1E49), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Période de rapport',
                      style: AppTextSize.titleStyle(context,
                          color: Colors.grey[800]),
                    ),
                  ),
                  Icon(
                    _isFilterExpanded ? Icons.expand_less : Icons.expand_more,
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
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReportPeriod.values.map((period) {
                  return _buildPeriodChip(period, selectedPeriod);
                }).toList(),
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isFilterExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(ReportPeriod period, ReportPeriod selectedPeriod) {
    final isSelected = period == selectedPeriod;
    return FilterChip(
      label: Text(period.getDisplayName()),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(selectedPeriodProvider.notifier).state = period;
          ref.read(reportsProvider.notifier).loadReports(period);
        }
      },
      selectedColor: const Color(0xFF1A1E49).withOpacity(0.2),
      checkmarkColor: const Color(0xFF1A1E49),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1A1E49) : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF1A1E49) : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSkeletonSection(),
        const SizedBox(height: 16),
        _buildSkeletonSection(),
        const SizedBox(height: 16),
        _buildSkeletonSection(),
        const SizedBox(height: 16),
        _buildSkeletonSection(),
      ],
    );
  }

  Widget _buildSkeletonSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              style: AppTextSize.titleStyle(context,
                  color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final selectedPeriod = ref.read(selectedPeriodProvider);
                ref.read(reportsProvider.notifier).loadReports(selectedPeriod);
              },
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).translate('retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1E49),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsContent(ReportStatistics reportsState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clients les plus actifs
          _buildSection(
            key: 'customers',
            title: 'Clients les plus actifs',
            icon: Icons.people,
            iconColor: Colors.blue,
            content: reportsState.topCustomers.isNotEmpty
                ? _buildCustomersList(reportsState.topCustomers)
                : _buildEmptyState('Aucun client actif disponible'),
          ),

          const SizedBox(height: 16),

          // Fournisseurs les plus sollicités
          _buildSection(
            key: 'suppliers',
            title: 'Fournisseurs les plus sollicités',
            icon: Icons.business,
            iconColor: Colors.orange,
            content: reportsState.topSuppliers.isNotEmpty
                ? _buildSuppliersList(reportsState.topSuppliers)
                : _buildEmptyState('Aucun fournisseur sollicité disponible'),
          ),

          const SizedBox(height: 16),

          // Produits les plus achetés
          _buildSection(
            key: 'products',
            title: 'Produits les plus achetés',
            icon: Icons.shopping_bag,
            iconColor: Colors.green,
            content: reportsState.topProducts.isNotEmpty
                ? _buildProductsList(reportsState.topProducts)
                : _buildEmptyState('Aucun produit acheté disponible'),
          ),

          const SizedBox(height: 16),

          // Ports (Envoi / Réception)
          _buildSection(
            key: 'harbors',
            title: 'Ports les plus utilisés',
            icon: Icons.local_shipping,
            iconColor: Colors.purple,
            content: Column(
              children: [
                // Ports d'envoi
                if (reportsState.shippingHarbors.isNotEmpty) ...[
                  _buildSubSectionTitle('Ports d\'envoi', Icons.send),
                  const SizedBox(height: 12),
                  _buildHarborsList(reportsState.shippingHarbors,
                      isShipping: true),
                  const SizedBox(height: 24),
                ] else if (reportsState.receivingHarbors.isEmpty)
                  _buildEmptyState('Aucun port utilisé disponible'),

                // Ports de réception
                if (reportsState.receivingHarbors.isNotEmpty) ...[
                  _buildSubSectionTitle(
                      'Ports de réception', Icons.call_received),
                  const SizedBox(height: 12),
                  _buildHarborsList(reportsState.receivingHarbors,
                      isShipping: false),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String key,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
  }) {
    final isExpanded = _expandedSections[key] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          InkWell(
            onTap: () {
              setState(() {
                _expandedSections[key] = !isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextSize.titleStyle(context,
                          color: const Color(0xFF1A1E49)),
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

  Widget _buildSubSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextSize.bodyStyle(context,
              fontWeight: FontWeight.w600, color: Colors.grey[800]),
        ),
      ],
    );
  }

  Widget _buildCustomersList(List<CustomerStat> customers) {
    final maxOperations = customers.isNotEmpty
        ? customers.map((c) => c.purchaseCount).reduce((a, b) => a > b ? a : b)
        : 1;

    return Column(
      children: customers.asMap().entries.map((entry) {
        final index = entry.key;
        final customer = entry.value;
        final isTopThree = index < 3;
        final progress =
            maxOperations > 0 ? customer.purchaseCount / maxOperations : 0.0;

        return _buildStatCard(
          index: index,
          title: customer.customerName,
          value: '${customer.purchaseCount} opérations',
          progress: progress,
          color: _getRankColor(index),
          isTopThree: isTopThree,
        );
      }).toList(),
    );
  }

  Widget _buildSuppliersList(List<SupplierStat> suppliers) {
    final maxVolume = suppliers.isNotEmpty
        ? suppliers.map((s) => s.itemCount).reduce((a, b) => a > b ? a : b)
        : 1;

    return Column(
      children: suppliers.asMap().entries.map((entry) {
        final index = entry.key;
        final supplier = entry.value;
        final isTopThree = index < 3;
        final progress = maxVolume > 0 ? supplier.itemCount / maxVolume : 0.0;

        return _buildStatCard(
          index: index,
          title: supplier.supplierName,
          value: '${supplier.itemCount} articles',
          progress: progress,
          color: _getRankColor(index),
          isTopThree: isTopThree,
          icon: Icons.business,
        );
      }).toList(),
    );
  }

  Widget _buildProductsList(List<ProductStat> products) {
    final maxQuantity = products.isNotEmpty
        ? products.map((p) => p.totalQuantity).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Column(
      children: products.asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;
        final isTopThree = index < 3;
        final progress =
            maxQuantity > 0 ? product.totalQuantity / maxQuantity : 0.0;

        return _buildStatCard(
          index: index,
          title: product.description,
          value: '${product.totalQuantity.toInt()} unités',
          progress: progress,
          color: _getRankColor(index),
          isTopThree: isTopThree,
          icon: Icons.inventory_2,
        );
      }).toList(),
    );
  }

  Widget _buildHarborsList(List<dynamic> harbors, {required bool isShipping}) {
    if (harbors.isEmpty) {
      return _buildEmptyState('Aucun port disponible');
    }

    final maxCount = harbors
        .map((h) => isShipping
            ? (h as ShippingHarborStat).packageCount
            : (h as ReceivingHarborStat).packageCount)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children: harbors.asMap().entries.map((entry) {
        final index = entry.key;
        final harbor = entry.value;
        final harborName = isShipping
            ? (harbor as ShippingHarborStat).harborName
            : (harbor as ReceivingHarborStat).harborName;
        final packageCount = isShipping
            ? (harbor as ShippingHarborStat).packageCount
            : (harbor as ReceivingHarborStat).packageCount;
        final isTopThree = index < 3;
        final progress = maxCount > 0 ? packageCount / maxCount : 0.0;

        return _buildStatCard(
          index: index,
          title: harborName,
          value: '$packageCount colis',
          progress: progress,
          color: _getRankColor(index),
          isTopThree: isTopThree,
          icon: isShipping ? Icons.send : Icons.call_received,
        );
      }).toList(),
    );
  }

  Widget _buildStatCard({
    required int index,
    required String title,
    required String value,
    required double progress,
    required Color color,
    required bool isTopThree,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isTopThree
            ? Border.all(color: color.withOpacity(0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Badge de classement
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppTextSize.titleStyle(context, color: color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            title,
                            style: AppTextSize.bodyStyle(context,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1E49)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTextSize.bodyStyle(context,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Badge Top 3
              if (isTopThree)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    index == 0
                        ? '🥇'
                        : index == 1
                            ? '🥈'
                            : '🥉',
                    style: AppTextSize.bodyStyle(context),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber.shade700; // Or
      case 1:
        return Colors.grey.shade600; // Argent
      case 2:
        return Colors.brown.shade600; // Bronze
      default:
        return Colors.blue.shade600;
    }
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
              style: AppTextSize.bodyStyle(context,
                  color: Colors.grey[600], fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
