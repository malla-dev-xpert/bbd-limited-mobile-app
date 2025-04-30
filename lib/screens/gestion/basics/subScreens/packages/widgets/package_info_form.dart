import 'package:flutter/material.dart';
import 'package:bbd_limited/components/text_input.dart';

class PackageInfoForm extends StatelessWidget {
  final TextEditingController refController;
  final TextEditingController weightController;
  final TextEditingController dimensionController;

  const PackageInfoForm({
    Key? key,
    required this.refController,
    required this.weightController,
    required this.dimensionController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildTextField(
          controller: refController,
          label: "Libellé du colis",
          icon: Icons.description,
          validator:
              (v) =>
                  v == null || v.isEmpty ? 'Veuillez entrer le libellé' : null,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 10,
          children: [
            Expanded(
              child: buildTextField(
                controller: weightController,
                label: "Le poids du colis",
                keyboardType: TextInputType.number,
                icon: Icons.numbers_rounded,
                validator:
                    (v) =>
                        v == null || v.isEmpty
                            ? 'Le poids du colis est requis'
                            : null,
              ),
            ),
            Expanded(
              child: buildTextField(
                controller: dimensionController,
                label: "La dimension du colis",
                icon: Icons.line_weight,
                validator:
                    (v) =>
                        v == null || v.isEmpty
                            ? 'La dimension du colis est requise'
                            : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
