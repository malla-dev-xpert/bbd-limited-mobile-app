import 'package:flutter/material.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/date_picker.dart';

class PackageInfoForm extends StatefulWidget {
  final TextEditingController refController;
  final TextEditingController weightController;
  final TextEditingController dimensionController;
  final DateTime? initialDate;
  final Function(DateTime?)? onDateChanged;

  const PackageInfoForm({
    Key? key,
    required this.refController,
    required this.weightController,
    required this.dimensionController,
    this.initialDate,
    this.onDateChanged,
  }) : super(key: key);

  @override
  State<PackageInfoForm> createState() => _PackageInfoFormState();
}

class _PackageInfoFormState extends State<PackageInfoForm> {
  DateTime? myDate;

  @override
  void initState() {
    super.initState();
    myDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildTextField(
          controller: widget.refController,
          label: "Libellé du colis",
          icon: Icons.description,
          validator:
              (v) =>
                  v == null || v.isEmpty ? 'Veuillez entrer le libellé' : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: buildTextField(
                controller: widget.weightController,
                label: "Poids du colis",
                keyboardType: TextInputType.number,
                icon: Icons.numbers_rounded,
                validator:
                    (v) => v == null || v.isEmpty ? 'Poids requis' : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: buildTextField(
                controller: widget.dimensionController,
                label: "Dimensions",
                icon: Icons.line_weight,
                validator:
                    (v) =>
                        v == null || v.isEmpty ? 'Dimensions requises' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DatePickerField(
          label: "Date de réception",
          selectedDate: myDate,
          onDateSelected: (date) {
            setState(() {
              myDate = date;
            });
            widget.onDateChanged?.call(date);
          },
        ),
      ],
    );
  }
}
