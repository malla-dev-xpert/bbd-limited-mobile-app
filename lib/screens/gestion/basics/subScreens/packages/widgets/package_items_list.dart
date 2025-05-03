import 'package:flutter/material.dart';

class PackageItemsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(int index) onRemoveItem;

  const PackageItemsList({
    Key? key,
    required this.items,
    required this.onRemoveItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return items.isNotEmpty
        ? SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item['description']),
                subtitle: Text("Quantité : ${item['quantity']}"),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onRemoveItem(index),
                ),
              );
            },
          ),
        )
        : Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "Aucun article ajouté.",
            style: TextStyle(color: Colors.grey),
          ),
        );
  }
}
