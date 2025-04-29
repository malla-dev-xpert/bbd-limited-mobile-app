import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:bbd_limited/models/partner.dart';

class PartnerEditForm extends StatefulWidget {
  final Partner partner;
  final Function(Partner) onSubmit;

  const PartnerEditForm({
    Key? key,
    required this.partner,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _PartnerEditFormState createState() => _PartnerEditFormState();
}

class _PartnerEditFormState extends State<PartnerEditForm> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _adresseController;
  late String? _accountType;
  late Country? _selectedCountry;

  final _formKey = GlobalKey<FormState>();
  final List<String> _accountTypeList = ['CLIENT', 'FOURNISSEUR'];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.partner.firstName,
    );
    _lastNameController = TextEditingController(text: widget.partner.lastName);
    _phoneController = TextEditingController(text: widget.partner.phoneNumber);
    _emailController = TextEditingController(text: widget.partner.email);
    _adresseController = TextEditingController(text: widget.partner.adresse);
    _accountType = widget.partner.accountType;
    _selectedCountry =
        widget.partner.country != null
            ? Country.tryParse(widget.partner.country!)
            : null;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre et champs de formulaire...
              // ... (similaire au code original mais mieux organisé)
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final updatedPartner = Partner(
        id: widget.partner.id,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        adresse: _adresseController.text,
        accountType: _accountType ?? widget.partner.accountType,
        country: _selectedCountry?.name ?? widget.partner.country,
      );

      widget.onSubmit(updatedPartner);
    }
  }
}
