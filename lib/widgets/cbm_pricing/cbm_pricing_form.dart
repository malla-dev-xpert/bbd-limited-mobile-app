import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/cbm_pricing.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class CbmPricingForm extends StatefulWidget {
  final CbmPricing? cbmPricing;
  final Function(double cbmValue, double price, String? currency) onSubmit;
  final bool isLoading;
  final bool isEditing;

  const CbmPricingForm({
    Key? key,
    this.cbmPricing,
    required this.onSubmit,
    this.isLoading = false,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<CbmPricingForm> createState() => _CbmPricingFormState();
}

class _CbmPricingFormState extends State<CbmPricingForm> {
  final _formKey = GlobalKey<FormState>();
  final _cbmValueController = TextEditingController();
  final _priceController = TextEditingController();
  final _currencyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.cbmPricing != null) {
      _cbmValueController.text = widget.cbmPricing!.cbmValue.toString();
      _priceController.text = widget.cbmPricing!.price.toString();
      _currencyController.text = widget.cbmPricing!.currency ?? '';
    }
  }

  @override
  void dispose() {
    _cbmValueController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String translationKey) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).translate(translationKey);
    }
    if (double.tryParse(value) == null) {
      return AppLocalizations.of(context).translate('invalid_number');
    }
    return null;
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        double.parse(_cbmValueController.text),
        double.parse(_priceController.text),
        _currencyController.text.isEmpty
            ? null
            : _currencyController.text.trim(),
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
            controller: _cbmValueController,
            label: AppLocalizations.of(context).translate('cbm_value'),
            icon: Icons.square_foot,
            validator: (v) => _validateRequired(v, 'cbm_value_required'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          buildTextField(
            controller: _priceController,
            label: AppLocalizations.of(context).translate('price'),
            icon: Icons.payments,
            validator: (v) => _validateRequired(v, 'price_required'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          buildTextField(
            controller: _currencyController,
            label: AppLocalizations.of(context).translate('currency_optional'),
            icon: Icons.money,
            keyboardType: TextInputType.text,
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
              icon: widget.isEditing == false ? Icons.check_circle : Icons.edit,
              subLabel: widget.isEditing == false
                  ? AppLocalizations.of(context).translate('saving')
                  : AppLocalizations.of(context).translate('updating'),
            ),
          ),
        ],
      ),
    );
  }
}
