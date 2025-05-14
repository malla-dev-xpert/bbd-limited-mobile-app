import 'package:flutter/material.dart';
import 'package:bbd_limited/components/text_input.dart';

class ContainerInfoForm extends StatefulWidget {
  final TextEditingController refController;
  final TextEditingController size;
  final bool initialAvailability;

  const ContainerInfoForm({
    Key? key,
    required this.refController,
    required this.size,
    this.initialAvailability = false,
  }) : super(key: key);

  @override
  ContainerInfoFormState createState() => ContainerInfoFormState();
}

class ContainerInfoFormState extends State<ContainerInfoForm> {
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.initialAvailability;
  }

  bool get isAvailable => _isAvailable;

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
            validator:
                (v) =>
                    v == null || v.isEmpty
                        ? 'Veuillez entrer la référence'
                        : null,
          ),
          const SizedBox(height: 10),
          buildTextField(
            controller: widget.size,
            label: "Taille du conteneur",
            icon: Icons.height,
            validator:
                (v) =>
                    v == null || v.isEmpty
                        ? 'Veuillez entrer la référence'
                        : null,
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
