import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/item_detail_chip.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/supplier_payment_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/edit_supplier_payment_screen.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/core/services/auth_services.dart';

class SupplierDetailScreen extends StatefulWidget {
  final Partner supplier;

  const SupplierDetailScreen({
    Key? key,
    required this.supplier,
  }) : super(key: key);

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  final ItemServices itemServices = ItemServices();
  final AuthService authService = AuthService();
  List<Items> items = [];
  bool isLoading = true;
  bool _isCurrentUserAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadSupplierItems();
    _loadCurrentUserRole();
  }

  Future<void> _loadSupplierItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      final itemsData =
          await itemServices.findItemsBySupplier(widget.supplier.id);
      setState(() {
        items = itemsData;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('error_loading_items'),
        );
      }
    }
  }

  Future<void> _loadCurrentUserRole() async {
    try {
      final user = await authService.getUserInfo();
      if (!mounted || user == null) return;
      final permissions = user.role?.permissions ?? [];
      final isAdmin = permissions.contains('IS_ADMIN');
      if (isAdmin != _isCurrentUserAdmin) {
        setState(() {
          _isCurrentUserAdmin = isAdmin;
        });
      }
    } catch (_) {
      // Ignorer les erreurs de récupération d'utilisateur
    }
  }

  // Méthode pour formater le montant
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

  double _calculateRemainingAmount(Items item) {
    final total = item.totalPrice ?? 0.0;
    final paid = item.amountPaid ?? 0.0;
    final remaining = total - paid;
    return remaining > 0 ? remaining : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('supplier_details'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSupplierItems,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section des items
              Text(
                AppLocalizations.of(context).translate('purchased_items'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Liste des items ou état vide
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (items.isEmpty)
                _buildEmptyState()
              else ...[
                _buildItemsList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Méthode pour construire l'état vide
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).translate('no_items_purchased'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)
                .translate('no_items_purchased_description'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Méthode pour construire la liste des articles
  Widget _buildItemsList() {
    return Column(
      children: items.map((item) {
        final bool isPaid = item.paid == true;
        // Déterminer les actions à afficher
        final List<Widget> actions = [];

        // Si l'item n'est pas payé, afficher le bouton "Pay"
        if (!isPaid) {
          actions.add(
            SlidableAction(
              onPressed: (_) => _openPaymentScreen(item),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: Icons.payment,
              label: AppLocalizations.of(context).translate('pay'),
            ),
          );
        }

        // Si l'utilisateur est admin, toujours afficher le bouton "Edit"
        if (_isCurrentUserAdmin) {
          actions.add(
            SlidableAction(
              onPressed: (_) => _openEditPaymentScreen(item),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: AppLocalizations.of(context).translate('edit'),
            ),
          );
        }

        return Slidable(
          key: ValueKey('item_${item.id}'),
          enabled: actions.isNotEmpty,
          endActionPane: actions.isNotEmpty
              ? ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: actions.length > 1 ? 0.5 : 0.25,
                  children: actions,
                )
              : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête de l'item avec image de statut
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1E49).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: Color(0xFF1A1E49),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.description ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        '${AppLocalizations.of(context).translate('invoice_number')}: ',
                                  ),
                                  TextSpan(
                                    text: item.invoiceNumber ?? 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      item.paid == true
                          ? Image.asset(
                              'assets/images/paid.png',
                              width: 44,
                              height: 44,
                            )
                          : Image.asset(
                              'assets/images/not-paid.png',
                              width: 44,
                              height: 44,
                            ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Divider
                  Divider(color: Colors.grey[200], height: 1),
                  const SizedBox(height: 12),
                  // Détails de l'item
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ItemDetailChip(
                        text:
                            '${AppLocalizations.of(context).translate('carton')}: ${item.carton ?? 0}',
                        icon: Icons.inventory,
                      ),
                      const SizedBox(width: 16),
                      ItemDetailChip(
                        text:
                            '${AppLocalizations.of(context).translate('quantity_per_carton_2')}: ${item.quantityPerCarton ?? 0}',
                        icon: Icons.format_list_numbered,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ItemDetailChip(
                        text:
                            '${AppLocalizations.of(context).translate('total_quantity')}: ${item.quantity ?? 0}',
                        icon: Icons.numbers,
                      ),
                      const SizedBox(width: 8),
                      ItemDetailChip(
                        text: '${_formatAmount(item.unitPrice)} ¥',
                        icon: Icons.attach_money,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Taux d'achat et total en colonne pour une meilleure lisibilité
                  Column(
                    children: [
                      ItemDetailChip(
                        text:
                            '${AppLocalizations.of(context).translate('sales_rate')}: ${item.salesRate ?? 0}',
                        icon: Icons.trending_up,
                        fullWidth: true,
                      ),
                      const SizedBox(height: 8),
                      ItemDetailChip(
                        text:
                            '${AppLocalizations.of(context).translate('total')}: ${_formatAmount(item.totalPrice ?? (item.quantity ?? 0) * (item.unitPrice ?? 0))} ¥',
                        icon: Icons.calculate,
                        fullWidth: true,
                      ),
                      const SizedBox(height: 8),
                      ItemDetailChip(
                        text:
                            '${AppLocalizations.of(context).translate('total_amount_paid')}: ${_formatAmount(item.amountPaid)} ¥',
                        icon: Icons.payments,
                        fullWidth: true,
                      ),
                      const SizedBox(height: 8),
                      ItemDetailChip(
                        text:
                            '${AppLocalizations.of(context).translate('remaining_amount')}: ${_formatAmount(_calculateRemainingAmount(item))} ¥',
                        icon: Icons.account_balance_wallet,
                        fullWidth: true,
                      ),
                      if (_isCurrentUserAdmin) ...[
                        const SizedBox(height: 8),
                        ItemDetailChip(
                          text:
                              '${AppLocalizations.of(context).translate('paid_by')}: ${item.paidByUserName ?? 'N/A'}',
                          icon: Icons.person,
                          fullWidth: true,
                        ),
                        const SizedBox(height: 8),
                        ItemDetailChip(
                          text:
                              '${AppLocalizations.of(context).translate('paid_date')}: ${item.paiementDate != null ? DateFormat('dd/MM/yyyy').format(item.paiementDate!) : 'N/A'}',
                          icon: Icons.date_range,
                          fullWidth: true,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _openPaymentScreen(Items item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierPaymentScreen(
          item: item,
          supplier: widget.supplier,
        ),
      ),
    );

    if (result == true) {
      // Rafraîchir la liste des items après le paiement
      _loadSupplierItems();
    }
  }

  void _openEditPaymentScreen(Items item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditSupplierPaymentScreen(
          item: item,
          supplier: widget.supplier,
        ),
      ),
    );

    if (result == true) {
      // Rafraîchir la liste des items après la modification du paiement
      _loadSupplierItems();
    }
  }
}
