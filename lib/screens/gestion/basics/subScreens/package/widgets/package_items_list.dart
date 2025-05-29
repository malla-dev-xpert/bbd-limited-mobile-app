import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PackageItemsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(int index) onRemoveItem;

  PackageItemsList({Key? key, required this.items, required this.onRemoveItem})
      : super(key: key);

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
                    return ListTile(
                      title: Text(item['description']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("Qté : ${item['quantity']}"),
                              const SizedBox(width: 10),
                              Text("P.U : ${item['unitPrice']}"),
                            ],
                          ),
                          Text("Fournisseur : ${item['supplier']}"),
                          Text(
                            "Total : ${currencyFormat.format((item['unitPrice'] as num) * (item['quantity'] as num))}",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => onRemoveItem(index),
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
}
