import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/create_supplier_bottom_sheet.dart';

class PackageItemForm extends StatefulWidget {
  final Function(
    String description,
    double quantity,
    double unitPrice,
    int supplierId,
    String supplierName,
    String invoiceNumber,
    double salesRate,
  ) onAddItem;
  final List<Partner> suppliers;

  const PackageItemForm({
    Key? key,
    required this.onAddItem,
    required this.suppliers,
  }) : super(key: key);

  @override
  State<PackageItemForm> createState() => _PackageItemFormState();
}

class _PackageItemFormState extends State<PackageItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _salesRateController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final PartnerServices partnerServices = PartnerServices();
  ValueKey _dropdownKey = ValueKey(DateTime.now().millisecondsSinceEpoch);

  List<Partner> get suppliers => widget.suppliers;
  Partner? selectedSupplier;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 4,
                child: DropDownCustom<Partner>(
                  key: _dropdownKey,
                  items: suppliers,
                  selectedItem: selectedSupplier,
                  onChanged: (Partner? newSupplier) {
                    if (newSupplier != null) {
                      setState(() {
                        selectedSupplier = newSupplier;
                      });
                    }
                  },
                  itemToString: (supplier) =>
                      '${supplier.firstName}  ${supplier.lastName} ${supplier.lastName.isNotEmpty ? '|' : ''} ${supplier.phoneNumber}',
                  hintText: 'Choisir un fournisseur...',
                  prefixIcon: Icons.person_add,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: IconButton(
                  onPressed: () async {
                    final result = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => CreateSupplierBottomSheet(
                        onSupplierCreated: () async {
                          // Recharger la liste des fournisseurs
                          // await _loadSupplier();
                        },
                      ),
                    );

                    if (result == true) {
                      // Le fournisseur a été créé avec succès
                      // await _loadSupplier();
                    }
                  },
                  icon: Icon(Icons.add, color: Colors.grey[500]),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.grey[200]!,
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey[500]!),
                      ),
                    ),
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          buildTextField(
            controller: _descriptionController,
            label: "Description de l'article",
            icon: Icons.description,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer une description';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          buildTextField(
            controller: _invoiceNumberController,
            label: "Numéro de facture",
            icon: Icons.inventory_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un numéro de facture';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: buildTextField(
                  controller: _unitPriceController,
                  label: "Prix Unitaire",
                  keyboardType: TextInputType.number,
                  icon: Icons.attach_money,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildTextField(
                  controller: _salesRateController,
                  label: "Taux d'achat",
                  icon: Icons.percent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 10,
            children: [
              Expanded(
                child: buildTextField(
                  controller: _quantityController,
                  label: "Quantité",
                  keyboardType: TextInputType.number,
                  icon: Icons.numbers,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Ajouter",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7F78AF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (selectedSupplier == null) {
        showErrorTopSnackBar(context, "Veuillez sélectionner un fournisseur");
        return;
      }

      widget.onAddItem(
        _descriptionController.text,
        double.parse(_quantityController.text),
        double.parse(_unitPriceController.text),
        selectedSupplier!.id,
        '${selectedSupplier!.firstName} ${selectedSupplier!.lastName}',
        _invoiceNumberController.text,
        double.parse(_salesRateController.text),
      );

      // Reset form
      _formKey.currentState!.reset();
      setState(() {
        selectedSupplier = null;
        _dropdownKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _invoiceNumberController.dispose();
    _salesRateController.dispose();
    super.dispose();
  }
}
