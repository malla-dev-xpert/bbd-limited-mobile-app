import 'package:flutter/material.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';

class DropDownCustom<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedItem;
  final Function(T?) onChanged;
  final String Function(T) itemToString;
  final String hintText;
  final IconData? prefixIcon;
  final String? labelText;

  const DropDownCustom({
    Key? key,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
    required this.itemToString,
    this.hintText = 'Sélectionner...',
    this.prefixIcon,
    this.labelText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                labelText!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          CustomDropdown<String>.search(
            hintText:
                selectedItem != null ? itemToString(selectedItem!) : hintText,
            decoration: CustomDropdownDecoration(
              prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            ),
            noResultFoundText: 'Aucun résultat trouvé.',
            items: items.map(itemToString).toList(),
            onChanged: (value) {
              final selected = items.firstWhere(
                (item) => itemToString(item) == value,
                orElse: () => null as T,
              );
              onChanged(selected);
            },
          ),
        ],
      ),
    );
  }
}
