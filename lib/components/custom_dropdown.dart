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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;

    return CustomDropdown<String>.search(
      hintText: selectedItem != null ? itemToString(selectedItem!) : hintText,
      decoration: CustomDropdownDecoration(
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        closedBorder: Border.all(color: Colors.grey[300]!),
        expandedBorder: Border.all(color: Colors.grey[300]!),
        closedFillColor: Colors.white,
        expandedFillColor: Colors.white,
        closedSuffixIcon: const Icon(Icons.keyboard_arrow_down),
        expandedSuffixIcon: const Icon(Icons.keyboard_arrow_up),
      ),
      noResultFoundText: 'Aucun résultat trouvé.',
      searchHintText: 'Rechercher...',
      items: items.map(itemToString).toList(),
      onChanged: (value) {
        final selected = items.firstWhere(
          (item) => itemToString(item) == value,
          orElse: () => null as T,
        );
        onChanged(selected);
      },
    );
  }
}
