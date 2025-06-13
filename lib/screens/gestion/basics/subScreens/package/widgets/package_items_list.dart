import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PackageItemsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(int index) onRemoveItem;
  final Function(int index) onDuplicateItem;
  final Function(int index) onEditItem;

  PackageItemsList({
    Key? key,
    required this.items,
    required this.onRemoveItem,
    required this.onDuplicateItem,
    required this.onEditItem,
  }) : super(key: key);

  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        items.isNotEmpty
            ? SizedBox(
                height: MediaQuery.of(context).size.height * 0.334,
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue, size: 20),
                                      onPressed: () => onEditItem(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy,
                                          color: Colors.green, size: 20),
                                      onPressed: () => onDuplicateItem(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red, size: 20),
                                      onPressed: () => onRemoveItem(index),
                                    ),
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoChip(
                                        icon: Icons.shopping_cart,
                                        label: "Qté : ${item['quantity']}",
                                      ),
                                      _buildInfoChip(
                                        icon: Icons.attach_money,
                                        label: "P.U : ${item['unitPrice']}",
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoChip(
                                    icon: Icons.business,
                                    label: "Fournisseur : ${item['supplier']}",
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoChip(
                                    icon: Icons.receipt,
                                    label:
                                        "Facture N : ${item['invoiceNumber']}",
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
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
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
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

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
