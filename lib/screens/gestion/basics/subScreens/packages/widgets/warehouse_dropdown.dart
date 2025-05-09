import 'package:flutter/material.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:bbd_limited/models/warehouses.dart';

class WarehouseDropdown extends StatelessWidget {
  final List<Warehouses> warehouses;
  final Warehouses? selectedWarehouse;
  final Function(Warehouses?) onChanged;

  const WarehouseDropdown({
    Key? key,
    required this.warehouses,
    required this.selectedWarehouse,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: CustomDropdown<String>.search(
        hintText: 'Choisir un entrepôt...',
        decoration: CustomDropdownDecoration(
          prefixIcon: Icon(Icons.local_shipping_rounded),
        ),
        items: warehouses.map((e) => '${e.name} | ${e.adresse}').toList(),
        onChanged: (value) {
          // Correction: Trouver l'entrepôt correspondant
          final selected = warehouses.firstWhere(
            (warehouse) => '${warehouse.name} | ${warehouse.adresse}' == value,
          );
          onChanged(selected);
        },
      ),
    );
  }
}
