import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';
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

  final bool _isLoading = false;

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
            ? Country.tryParse(widget.partner.country)
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Modifier un partenaire',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: buildTextField(
                            controller: _firstNameController,
                            label: "Nom",
                            icon: Icons.person,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: buildTextField(
                            controller: _lastNameController,
                            label: "Prénom",
                            icon: Icons.person_4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: buildTextField(
                            controller: _phoneController,
                            label: "Téléphone",
                            icon: Icons.phone,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: buildTextField(
                            controller: _emailController,
                            label: "Email",
                            icon: Icons.mail,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    buildTextField(
                      controller: _adresseController,
                      label: "Adresse",
                      icon: Icons.maps_home_work,
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: true,
                          countryListTheme: CountryListThemeData(
                            flagSize: 25,
                            backgroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 16),
                            bottomSheetHeight: 300,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          onSelect: (Country country) {
                            setState(() {
                              _selectedCountry = country;
                            });
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _selectedCountry != null
                                ? Row(
                                  children: [
                                    Text(
                                      _selectedCountry!.flagEmoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_selectedCountry!.name),
                                  ],
                                )
                                : const Text('Choisir un pays'),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: CustomDropdown<String>(
                        hintText: _accountType,
                        items: _accountTypeList,
                        onChanged: (value) {
                          setState(() {
                            _accountType = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : confirmationButton(
                          isLoading: _isLoading,
                          onPressed: _submitForm,
                          label: "Modifier",
                          icon: Icons.edit_note_rounded,
                          subLabel: "Modification...",
                        ),
                  ],
                ),
              ],
            ),
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
