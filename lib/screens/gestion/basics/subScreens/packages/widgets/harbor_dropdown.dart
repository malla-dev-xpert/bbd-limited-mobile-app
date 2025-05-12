import 'package:bbd_limited/models/harbor.dart';
import 'package:flutter/material.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';

class HarborDropdown extends StatelessWidget {
  final List<Harbor> harbors;
  final Harbor? selectedHarbor;
  final Function(Harbor?) onChanged;

  const HarborDropdown({
    Key? key,
    required this.harbors,
    required this.selectedHarbor,
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
        hintText: 'Choisir un port...',
        decoration: CustomDropdownDecoration(
          prefixIcon: Icon(Icons.cabin_outlined),
        ),
        items: harbors.map((e) => '${e.name} | ${e.location}').toList(),
        onChanged: (value) {
          // Correction: Trouver l'entrepôt correspondant
          final selected = harbors.firstWhere(
            (harbor) => '${harbor.name} | ${harbor.location}' == value,
          );
          onChanged(selected);
        },
      ),
    );
  }
}
