import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/components/text_input.dart';

class PackageItemForm extends StatefulWidget {
  final Function(String description, double quantity) onAddItem;

  const PackageItemForm({Key? key, required this.onAddItem}) : super(key: key);

  @override
  _PackageItemFormState createState() => _PackageItemFormState();
}

class _PackageItemFormState extends State<PackageItemForm> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Ajouter des articles au colis"),
        const SizedBox(height: 5),
        buildTextField(
          controller: descriptionController,
          label: "Description de l'article",
          icon: Icons.description,
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
              icon: Icon(Icons.add, color: Colors.white),
              label: Text("Ajouter", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7F78AF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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

    if (description.isEmpty) {
      showErrorTopSnackBar(context, "Veuillez entrer une description");
      return;
    }

    if (quantity == null) {
      showErrorTopSnackBar(context, "Veuillez entrer une quantité");
      return;
    }

    widget.onAddItem(description, quantity);
    descriptionController.clear();
    quantityController.clear();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    super.dispose();
  }
}
