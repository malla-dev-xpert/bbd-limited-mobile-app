import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/supplier_detail_screen.dart';
import 'package:bbd_limited/core/services/item_services.dart';

class SupplierListItem extends StatefulWidget {
  final Partner supplier;
  final Function(Partner) onEdit;
  final Function(Partner) onDelete;
  final Function(Partner)? onSupplierUpdated;

  const SupplierListItem({
    Key? key,
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
    this.onSupplierUpdated,
  }) : super(key: key);

  @override
  State<SupplierListItem> createState() => _SupplierListItemState();
}

class _SupplierListItemState extends State<SupplierListItem> {
  final ItemServices itemServices = ItemServices();
  int? totalItems;
  int? paidItems;
  bool isLoadingTotal = true;

  @override
  void initState() {
    super.initState();
    _loadTotalItems();
  }

  Future<void> _loadTotalItems() async {
    try {
      final supplierId = widget.supplier.id.toInt();
      final items = await itemServices.findItemsBySupplier(supplierId);
      final total = items.length;
      final paidCount = items.where((item) => item.paid == true).length;
      if (!mounted) return;
      setState(() {
        totalItems = total;
        paidItems = paidCount;
        isLoadingTotal = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        totalItems = 0;
        paidItems = 0;
        isLoadingTotal = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(widget.supplier.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => widget.onEdit(widget.supplier),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: AppLocalizations.of(context).translate('edit'),
          ),
          SlidableAction(
            onPressed: (_) => widget.onDelete(widget.supplier),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: AppLocalizations.of(context).translate('delete'),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SupplierDetailScreen(supplier: widget.supplier),
            ),
          );
        },
        title: Text("${widget.supplier.firstName} ${widget.supplier.lastName}"),
        subtitle: Text(widget.supplier.phoneNumber),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoadingTotal)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    '${paidItems ?? 0}/${totalItems ?? 0}',
                    style: AppTextSize.bodyStyle(context,
                      color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
