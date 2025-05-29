import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/create_supplier_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/components/text_input.dart';

class ContainerInfoForm extends StatefulWidget {
  final TextEditingController refController;
  final TextEditingController size;
  final bool initialAvailability;
  final Partner? selectedSupplier;

  const ContainerInfoForm({
    Key? key,
    required this.refController,
    required this.size,
    this.initialAvailability = false,
    this.selectedSupplier,
  }) : super(key: key);

  @override
  ContainerInfoFormState createState() => ContainerInfoFormState();
}

class ContainerInfoFormState extends State<ContainerInfoForm> {
  late bool _isAvailable;
  List<Partner> suppliers = [];
  Partner? selectedSupplier;
  bool get isAvailable => _isAvailable;
  final PartnerServices _partnerServices = PartnerServices();

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.initialAvailability;
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    final data = await _partnerServices.findSuppliers(page: 0);
    setState(() {
      suppliers = data;
    });
  }

  void _showCreateSupplierBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateSupplierBottomSheet(),
    ).then((_) {
      _loadSuppliers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildTextField(
            controller: widget.refController,
            label: "Référence du conteneur",
            icon: Icons.description,
            validator: (v) =>
                v == null || v.isEmpty ? 'Veuillez entrer la référence' : null,
          ),
          const SizedBox(height: 10),
          buildTextField(
            controller: widget.size,
            label: "Taille du conteneur",
            icon: Icons.height,
            validator: (v) =>
                v == null || v.isEmpty ? 'Veuillez entrer la référence' : null,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                flex: 3,
                child: DropDownCustom<Partner>(
                  items: suppliers,
                  selectedItem: selectedSupplier,
                  onChanged: (s) {
                    setState(() {
                      selectedSupplier = s;
                    });
                  },
                  itemToString: (client) =>
                      '${client.firstName} ${client.lastName} | ${client.phoneNumber}',
                  hintText: 'Choisir un fournisseur...',
                  prefixIcon: Icons.person,
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  onPressed: _showCreateSupplierBottomSheet,
                  icon: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text("Disponibilité", style: TextStyle(fontSize: 16)),
                ),
                Switch(
                  value: _isAvailable,
                  activeColor: Colors.green,
                  activeTrackColor: Colors.green[200],
                  inactiveThumbColor: Colors.grey[400],
                  inactiveTrackColor: Colors.grey[200],
                  onChanged: (value) {
                    setState(() => _isAvailable = value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
