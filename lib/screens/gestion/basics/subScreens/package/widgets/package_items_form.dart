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
  ) onAddItem;

  const PackageItemForm({Key? key, required this.onAddItem}) : super(key: key);

  @override
  _PackageItemFormState createState() => _PackageItemFormState();
}

class _PackageItemFormState extends State<PackageItemForm> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController invoiceNumberController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  final PartnerServices partnerServices = PartnerServices();
  ValueKey _dropdownKey = ValueKey(DateTime.now().millisecondsSinceEpoch);

  List<Partner> suppliers = [];
  Partner? selectedSupplier;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSupplier();
  }

  Future<void> _loadSupplier() async {
    setState(() => isLoading = true);
    try {
      final supplierData = await partnerServices.findSuppliers(page: 0);

      setState(() {
        suppliers = supplierData;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
      showErrorTopSnackBar(context, "Erreur lors du chargement des données");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
                    '${supplier.firstName}  ${supplier.lastName} | ${supplier.phoneNumber}',
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
                        await _loadSupplier();
                      },
                    ),
                  );

                  if (result == true) {
                    // Le fournisseur a été créé avec succès
                    await _loadSupplier();
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
          controller: descriptionController,
          label: "Description de l'article",
          icon: Icons.description,
        ),
        const SizedBox(height: 10),
        buildTextField(
          controller: invoiceNumberController,
          label: "Numéro de facture",
          icon: Icons.inventory_outlined,
        ),
        const SizedBox(height: 10),
        buildTextField(
          controller: unitPriceController,
          label: "Prix Unitaire",
          keyboardType: TextInputType.number,
          icon: Icons.attach_money,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 10,
          children: [
            Expanded(
              child: buildTextField(
                controller: quantityController,
                label: "Quantité",
                keyboardType: TextInputType.number,
                icon: Icons.numbers,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add, color: Colors.white),
              label:
                  const Text("Ajouter", style: TextStyle(color: Colors.white)),
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
    );
  }

  void _addItem() {
    final description = descriptionController.text.trim();
    final quantity = double.tryParse(quantityController.text.trim());
    final unitPrice = double.tryParse(unitPriceController.text.trim());

    if (selectedSupplier == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un fournisseur");
      return;
    }

    if (description.isEmpty) {
      showErrorTopSnackBar(context, "Veuillez entrer une description");
      return;
    }

    if (unitPrice == null) {
      showErrorTopSnackBar(context, "Veuillez entrer le prix unitaire");
      return;
    }

    if (quantity == null) {
      showErrorTopSnackBar(context, "Veuillez entrer une quantité");
      return;
    }

    widget.onAddItem(
      description,
      quantity,
      unitPrice,
      selectedSupplier!.id,
      '${selectedSupplier!.firstName} ${selectedSupplier!.lastName}',
    );

    // Reset form
    setState(() {
      descriptionController.clear();
      quantityController.clear();
      unitPriceController.clear();
      selectedSupplier = null;
      _dropdownKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
    });
  }

  @override
  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    super.dispose();
  }
}
