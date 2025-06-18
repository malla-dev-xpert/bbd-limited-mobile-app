import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/package/widgets/item_info_display.dart';

class PackageItemsList extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final List<Partner> suppliers;
  final Function(int index) onRemoveItem;
  final Function(int index) onDuplicateItem;
  final Function(int index, Map<String, dynamic> updatedItem) onEditItem;

  const PackageItemsList({
    Key? key,
    required this.items,
    required this.suppliers,
    required this.onRemoveItem,
    required this.onDuplicateItem,
    required this.onEditItem,
  }) : super(key: key);

  @override
  State<PackageItemsList> createState() => _PackageItemsListState();
}

class _PackageItemsListState extends State<PackageItemsList> {
  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');
  int? editingIndex;
  final Map<String, TextEditingController> controllers = {};
  Partner? selectedSupplier;

  @override
  void dispose() {
    controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _startEditing(int index) {
    setState(() {
      editingIndex = index;
      final item = widget.items[index];
      controllers['description'] =
          TextEditingController(text: item['description']);
      controllers['quantity'] =
          TextEditingController(text: item['quantity'].toString());
      controllers['unitPrice'] =
          TextEditingController(text: item['unitPrice'].toString());
      controllers['invoiceNumber'] =
          TextEditingController(text: item['invoiceNumber']);

      // Trouver le fournisseur actuel
      selectedSupplier = widget.suppliers.firstWhere(
        (supplier) => supplier.id == item['supplierId'],
        orElse: () => widget.suppliers.first,
      );
    });
  }

  void _saveChanges(int index) {
    final updatedItem = Map<String, dynamic>.from(widget.items[index]);
    updatedItem['description'] = controllers['description']!.text;
    updatedItem['quantity'] =
        int.tryParse(controllers['quantity']!.text) ?? updatedItem['quantity'];
    updatedItem['unitPrice'] =
        double.tryParse(controllers['unitPrice']!.text) ??
            updatedItem['unitPrice'];
    updatedItem['invoiceNumber'] = controllers['invoiceNumber']!.text;

    if (selectedSupplier != null) {
      updatedItem['supplierId'] = selectedSupplier!.id;
      updatedItem['supplier'] =
          "${selectedSupplier!.firstName} ${selectedSupplier!.lastName}";
    }

    widget.onEditItem(index, updatedItem);
    setState(() {
      editingIndex = null;
      controllers.clear();
      selectedSupplier = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      editingIndex = null;
      controllers.clear();
      selectedSupplier = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.items.isNotEmpty
            ? SizedBox(
                height: MediaQuery.of(context).size.height * 0.334,
                child: ListView.builder(
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    final isEditing = editingIndex == index;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.grey[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['description'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isEditing) ...[
                                      IconButton(
                                        icon: const Icon(Icons.check,
                                            color: Colors.green, size: 20),
                                        onPressed: () => _saveChanges(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red, size: 20),
                                        onPressed: _cancelEditing,
                                      ),
                                    ] else ...[
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue, size: 20),
                                        onPressed: () => _startEditing(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy,
                                            color: Colors.green, size: 20),
                                        onPressed: () =>
                                            widget.onDuplicateItem(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red, size: 20),
                                        onPressed: () =>
                                            widget.onRemoveItem(index),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isEditing)
                                    _buildEditFields(item)
                                  else
                                    _buildDisplayFields(item),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Total :",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          currencyFormat.format(
                                              (item['unitPrice'] as num) *
                                                  (item['quantity'] as num)),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            : const Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Center(
                  child: Text(
                    "Aucun article ajouté.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildEditFields(Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controllers['description'],
          decoration: const InputDecoration(
            labelText: 'Description',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controllers['quantity'],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantité',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controllers['unitPrice'],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prix unitaire',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controllers['invoiceNumber'],
          decoration: const InputDecoration(
            labelText: 'Numéro de facture',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Partner>(
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
          value: selectedSupplier,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Fournisseur',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: widget.suppliers.map((supplier) {
            return DropdownMenuItem<Partner>(
              value: supplier,
              child: Text(
                "${supplier.firstName} ${supplier.lastName}",
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (Partner? newValue) {
            if (newValue != null) {
              setState(() {
                selectedSupplier = newValue;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDisplayFields(Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ItemInfoDisplay(
          icon: Icons.shopping_cart,
          label: "Quantité",
          value: item['quantity'].toString(),
        ),
        const SizedBox(height: 8),
        ItemInfoDisplay(
          icon: Icons.attach_money,
          label: "Prix unitaire",
          value: item['unitPrice'].toString(),
        ),
        const SizedBox(height: 8),
        ItemInfoDisplay(
          icon: Icons.receipt,
          label: "Facture N",
          value: item['invoiceNumber'],
        ),
        const SizedBox(height: 8),
        ItemInfoDisplay(
          icon: Icons.business,
          label: "Fournisseur",
          value: item['supplier'],
        ),
      ],
    );
  }
}
