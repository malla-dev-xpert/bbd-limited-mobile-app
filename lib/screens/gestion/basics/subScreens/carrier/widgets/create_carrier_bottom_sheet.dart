import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/carrier_services.dart';
import 'package:bbd_limited/models/carrier.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class CreateCarrierBottomSheet extends StatefulWidget {
  final Function()? onCarrierCreated;

  const CreateCarrierBottomSheet({Key? key, this.onCarrierCreated})
      : super(key: key);

  @override
  State<CreateCarrierBottomSheet> createState() =>
      _CreateCarrierBottomSheetState();
}

class _CreateCarrierBottomSheetState extends State<CreateCarrierBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final CarrierServices _carrierServices = CarrierServices();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

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
                    AppLocalizations.of(context).translate('add_new_carrier'),
                    style: AppTextSize.headlineStyle(context).copyWith(letterSpacing: -1),
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
                    buildTextField(
                      controller: _nameController,
                      label: AppLocalizations.of(context)
                          .translate('container_form_carrier_name'),
                      icon: Icons.local_shipping,
                      validator: (v) => v == null || v.isEmpty
                          ? AppLocalizations.of(context)
                              .translate('required_field')
                          : null,
                    ),
                    const SizedBox(height: 10),
                    buildTextField(
                      controller: _contactController,
                      label: AppLocalizations.of(context)
                          .translate('container_form_carrier_contact'),
                      icon: Icons.contact_phone,
                    ),
                    const SizedBox(height: 24),
                    confirmationButton(
                      isLoading: isFormLoading,
                      onPressed: _saveCarrier,
                      label: AppLocalizations.of(context).translate('save'),
                      icon: Icons.check_circle_rounded,
                      subLabel:
                          AppLocalizations.of(context).translate('saving'),
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

  Future<void> _saveCarrier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isFormLoading = true);
    final AuthService authService = AuthService();

    try {
      final user = await authService.getUserInfo();

      if (user == null) {
        showErrorTopSnackBar(
            context, AppLocalizations.of(context).translate('please_login'));
        return;
      }

      final dto = CarrierDto(
        name: _nameController.text.trim(),
        contact: _contactController.text.trim(),
        services: [], // Par défaut vide
      );

      final success = await _carrierServices.createCarrier(dto, user.id);

      if (success == "CONTACT_REQUIRED") {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('required_field'),
        );
        return;
      } else if (success == "CONTACT_EXIST") {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('carrier_contact_already_used'),
        );
        return;
      } else if (success == "SUCCESS") {
        Navigator.of(context).pop(true);
        showSuccessTopSnackBar(
          context,
          AppLocalizations.of(context).translate('carrier_added_success'),
        );

        if (widget.onCarrierCreated != null) {
          widget.onCarrierCreated!();
        }
      }
    } catch (e) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('carrier_registration_error'),
      );
    } finally {
      if (mounted) {
        setState(() => isFormLoading = false);
      }
    }
  }
}
