import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/components/text_input.dart';

class CashWithdrawalForm extends StatefulWidget {
  final int partnerId;
  final int versementId;
  final String deviseCode;
  final Function(double montant, String note) onSubmit;

  const CashWithdrawalForm({
    Key? key,
    required this.partnerId,
    required this.versementId,
    required this.deviseCode,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<CashWithdrawalForm> createState() => _CashWithdrawalFormState();
}

class _CashWithdrawalFormState extends State<CashWithdrawalForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _montantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.99,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        "Retrait d'argent",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                buildTextField(
                  icon: Icons.monetization_on,
                  controller: _montantController,
                  label: "Montant (CNY)",
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Montant requis";
                    final montant = double.tryParse(value);
                    if (montant == null || montant <= 0)
                      return "Montant invalide";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Raison du retrait",
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.grey[50]!,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Raison requise";
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                confirmationButton(
                  isLoading: false,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSubmit(
                        double.parse(_montantController.text),
                        _noteController.text,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  label: "Valider",
                  subLabel: "Enregistrement...",
                  icon: Icons.check,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
