import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PackageItemsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(int index) onRemoveItem;

  PackageItemsList({Key? key, required this.items, required this.onRemoveItem})
    : super(key: key);

  // Fonction pour calculer le total
  double _calculateTotal() {
    double total = 0.0;
    for (var item in items) {
      total += (item['unitPrice'] as double) * (item['quantity'] as double);
    }
    return total;
  }

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
                        Text("Quantité : ${item['quantity']}"),
                        Text("P.U : ${item['unitPrice']}"),
                        Text(
                          "Total : ${(item['unitPrice'] * item['quantity']).toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => onRemoveItem(index),
                    ),
                  );
                },
              ),
            )
            : Padding(
              padding: const EdgeInsets.symmetric(vertical: 50),
              child: Center(
                child: Text(
                  "Aucun article ajouté.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),

        // Affichage du total général
        if (items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Total général : ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormat.format(_calculateTotal()),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
