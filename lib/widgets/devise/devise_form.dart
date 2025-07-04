import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/devises.dart';
import 'package:bbd_limited/components/text_input.dart';

class DeviseForm extends StatefulWidget {
  final Devise? devise;
  final Function(String name, String code, double? rate) onSubmit;
  final bool isLoading;
  final bool isEditing;

  const DeviseForm({
    Key? key,
    this.devise,
    required this.onSubmit,
    this.isLoading = false,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<DeviseForm> createState() => _DeviseFormState();
}

class _DeviseFormState extends State<DeviseForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _rateController = TextEditingController();

  // Constants for validation
  static const int _maxNameLength = 50;
  static const String _currencyCodePattern = r'^[A-Z]{3}$';

  @override
  void initState() {
    super.initState();
    if (widget.devise != null) {
      _nameController.text = widget.devise!.name;
      _codeController.text = widget.devise!.code;
      if (widget.devise!.rate != null) {
        _rateController.text = widget.devise!.rate.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom est requis';
    }
    if (value.length > _maxNameLength) {
      return 'Le nom ne doit pas dépasser $_maxNameLength caractères';
    }
    return null;
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le code est requis';
    }
    if (!RegExp(_currencyCodePattern).hasMatch(value)) {
      return 'Le code doit être composé de 3 lettres majuscules';
    }
    return null;
  }

  String? _validateRate(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Rate is optional
    }
    final rate = double.tryParse(value);
    if (rate == null) {
      return 'Le taux doit être un nombre valide';
    }
    if (rate < 0) {
      return 'Le taux ne peut pas être négatif';
    }
    return null;
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final rate = _rateController.text.isEmpty
          ? null
          : double.tryParse(_rateController.text);
      widget.onSubmit(
        _nameController.text.trim(),
        _codeController.text.trim().toUpperCase(),
        rate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildTextField(
            controller: _nameController,
            label: 'Nom de la devise',
            icon: Icons.attach_money,
            validator: _validateName,
          ),
          const SizedBox(height: 16),
          buildTextField(
            controller: _codeController,
            label: 'Code',
            icon: Icons.abc,
            validator: _validateCode,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),
          buildTextField(
            controller: _rateController,
            label: 'Taux de change',
            icon: Icons.percent,
            validator: _validateRate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: confirmationButton(
                isLoading: widget.isLoading,
                onPressed: _handleSubmit,
                label: widget.isEditing == false ? "Enregistrer" : "Modifier",
                icon:
                    widget.isEditing == false ? Icons.check_circle : Icons.edit,
                subLabel: widget.isEditing == false
                    ? "Enregistrement..."
                    : "Modification..."),
          ),
        ],
      ),
    );
  }
}
