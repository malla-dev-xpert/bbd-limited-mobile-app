import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/reusable_item_card.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/supplier_payment_screen.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/edit_supplier_payment_screen.dart';
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

  Widget _buildItemsList() {
    return Column(
      children: items.map((item) {
        final bool isPaid = item.paid == true;
        final List<Widget> actions = [];

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

        return ReusableItemCard(
          item: item,
          actions: actions,
          showPaymentStatus: true,
          showAdminInfo: _isCurrentUserAdmin,
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
