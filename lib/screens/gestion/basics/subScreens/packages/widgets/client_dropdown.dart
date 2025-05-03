import 'package:flutter/material.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:bbd_limited/models/partner.dart';

class ClientDropdown extends StatelessWidget {
  final List<Partner> clients;
  final Partner? selectedClient;
  final Function(Partner?) onChanged;

  const ClientDropdown({
    Key? key,
    required this.clients,
    required this.selectedClient,
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
        hintText: 'Choisir un client...',
        items:
            clients
                .map((e) => '${e.firstName} ${e.lastName} | ${e.phoneNumber}')
                .toList(),
        onChanged: (value) {
          final selected = clients.firstWhere(
            (client) =>
                '${client.firstName} ${client.lastName} | ${client.phoneNumber}' ==
                value,
          );
          onChanged(selected);
        },
      ),
    );
  }
}
