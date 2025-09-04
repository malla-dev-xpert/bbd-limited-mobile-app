import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/devises.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class DeviseForm extends StatefulWidget {
  final Devise? devise;
  final Function(String name, String code, double? rate) onSubmit;
  final bool isLoading;
  final bool isEditing;
  final String? nameError;
  final String? codeError;

  const DeviseForm({
    Key? key,
    this.devise,
    required this.onSubmit,
    this.isLoading = false,
    this.isEditing = false,
    this.nameError,
    this.codeError,
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
      return AppLocalizations.of(context).translate('devise_name_required');
    }
    if (value.length > _maxNameLength) {
      return AppLocalizations.of(context).translate('devise_name_too_long');
    }
    return null;
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).translate('devise_code_required');
    }
    if (!RegExp(_currencyCodePattern).hasMatch(value)) {
      return AppLocalizations.of(context).translate('devise_code_invalid');
    }
    return null;
  }

  String? _validateRate(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Rate is optional
    }
    final rate = double.tryParse(value);
    if (rate == null) {
      return AppLocalizations.of(context).translate('exchange_rate_invalid');
    }
    if (rate < 0) {
      return AppLocalizations.of(context).translate('exchange_rate_negative');
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
            label: AppLocalizations.of(context).translate('devise_name'),
            icon: Icons.attach_money,
            validator: _validateName,
            errorText:
                widget.nameError, // Ajout pour afficher l'erreur spécifique
          ),
          const SizedBox(height: 16),
          buildTextField(
            controller: _codeController,
            label: AppLocalizations.of(context).translate('devise_code'),
            icon: Icons.abc,
            validator: _validateCode,
            keyboardType: TextInputType.text,
            errorText:
                widget.codeError, // Ajout pour afficher l'erreur spécifique
          ),
          const SizedBox(height: 16),
          buildTextField(
            controller: _rateController,
            label: AppLocalizations.of(context).translate('exchange_rate'),
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
                label: widget.isEditing == false
                    ? AppLocalizations.of(context).translate('save')
                    : AppLocalizations.of(context).translate('edit'),
                icon:
                    widget.isEditing == false ? Icons.check_circle : Icons.edit,
                subLabel: widget.isEditing == false
                    ? AppLocalizations.of(context).translate('saving')
                    : AppLocalizations.of(context).translate('updating')),
          ),
        ],
      ),
    );
  }
}
