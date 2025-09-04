import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:country_picker/country_picker.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class CreateSupplierBottomSheet extends StatefulWidget {
  final Function()? onSupplierCreated;

  const CreateSupplierBottomSheet({Key? key, this.onSupplierCreated})
      : super(key: key);

  @override
  State<CreateSupplierBottomSheet> createState() =>
      _CreateSupplierBottomSheetState();
}

class _CreateSupplierBottomSheetState extends State<CreateSupplierBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final PartnerServices _partnerServices = PartnerServices();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();

  Country? _selectedCountry;
  bool _isLoading = false;
  bool isFormLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('add_new_supplier'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  IconButton(
                    onPressed: () => {Navigator.pop(context)},
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: buildTextField(
                            controller: _firstNameController,
                            label: AppLocalizations.of(context)
                                .translate('partner_first_name'),
                            icon: Icons.person,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: buildTextField(
                            controller: _lastNameController,
                            label: AppLocalizations.of(context)
                                .translate('partner_last_name'),
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
                            label: AppLocalizations.of(context)
                                .translate('partner_phone'),
                            icon: Icons.phone,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: buildTextField(
                            controller: _emailController,
                            label: AppLocalizations.of(context)
                                .translate('partner_email'),
                            icon: Icons.mail,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    buildTextField(
                      controller: _adresseController,
                      label: AppLocalizations.of(context)
                          .translate('partner_address'),
                      icon: Icons.maps_home_work,
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: true,
                          countryListTheme: const CountryListThemeData(
                            flagSize: 25,
                            backgroundColor: Colors.white,
                            textStyle: TextStyle(fontSize: 16),
                            bottomSheetHeight: 300,
                            borderRadius: BorderRadius.only(
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
                                : Text(AppLocalizations.of(context)
                                    .translate('partner_country')),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : confirmationButton(
                            isLoading: isFormLoading,
                            onPressed: _saveSupplier,
                            label:
                                AppLocalizations.of(context).translate('save'),
                            icon: Icons.check_circle_rounded,
                            subLabel: AppLocalizations.of(context)
                                .translate('saving'),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSupplier() async {
    setState(() => isFormLoading = true);
    final AuthService authService = AuthService();

    try {
      final user = await authService.getUserInfo();

      if (_firstNameController.text.isEmpty) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('please_enter_name'));
        return;
      }

      if (user == null) {
        showErrorTopSnackBar(
            context, AppLocalizations.of(context).translate('please_login'));
        return;
      }

      final success = await _partnerServices.create(
        _firstNameController.text.trim(),
        _lastNameController.text.trim(), // Peut être vide
        _phoneController.text.trim(), // Peut être vide
        _emailController.text.trim(), // Peut être vide
        _selectedCountry != null
            ? _selectedCountry!.name
            : '', // Peut être vide
        _adresseController.text.trim(), // Peut être vide
        'FOURNISSEUR',
        user.id,
      );

      if (success == "USER_NOT_FOUND") {
        showErrorTopSnackBar(
            context, AppLocalizations.of(context).translate('please_login'));
        return;
      } else if (success == "EMAIL_EXIST") {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('partner_email_exists'));
        return;
      } else if (success == "PHONE_EXIST") {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('partner_phone_exists'),
        );
        return;
      } else if (success == "CREATED") {
        Navigator.of(context).pop(true);
        setState(() {
          isFormLoading = false;
          _firstNameController.clear();
          _lastNameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _adresseController.clear();
          _selectedCountry = null;
          showSuccessTopSnackBar(
              context,
              AppLocalizations.of(context)
                  .translate('supplier_created_success'));
        });

        if (widget.onSupplierCreated != null) {
          widget.onSupplierCreated!();
        }
      }
    } catch (e) {
      showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('supplier_registration_error'));
    } finally {
      setState(() => isFormLoading = false);
    }
  }
}
