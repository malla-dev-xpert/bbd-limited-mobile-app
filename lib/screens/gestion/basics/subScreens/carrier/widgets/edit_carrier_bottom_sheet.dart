import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/carrier_services.dart';
import 'package:bbd_limited/models/carrier.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class EditCarrierBottomSheet extends StatefulWidget {
  final Carrier carrier;
  final Function()? onCarrierUpdated;

  const EditCarrierBottomSheet({
    Key? key,
    required this.carrier,
    this.onCarrierUpdated,
  }) : super(key: key);

  @override
  State<EditCarrierBottomSheet> createState() => _EditCarrierBottomSheetState();
}

class _EditCarrierBottomSheetState extends State<EditCarrierBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final CarrierServices _carrierServices = CarrierServices();
  final AuthService _authService = AuthService();

  late TextEditingController _nameController;
  late TextEditingController _contactController;

  bool isFormLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.carrier.name ?? '');
    _contactController =
        TextEditingController(text: widget.carrier.contact ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    loc.translate('edit_carrier'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
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
                      label: loc.translate('container_form_carrier_name'),
                      icon: Icons.local_shipping,
                      validator: (v) => v == null || v.isEmpty
                          ? loc.translate('required_field')
                          : null,
                    ),
                    const SizedBox(height: 10),
                    buildTextField(
                      controller: _contactController,
                      label: loc.translate('container_form_carrier_contact'),
                      icon: Icons.contact_phone,
                    ),
                    const SizedBox(height: 24),
                    confirmationButton(
                      isLoading: isFormLoading,
                      onPressed: _updateCarrier,
                      label: loc.translate('save'),
                      icon: Icons.check_circle_rounded,
                      subLabel: loc.translate('saving'),
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

  Future<void> _updateCarrier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isFormLoading = true);

    try {
      final user = await _authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('please_login'),
        );
        return;
      }

      final dto = CarrierDto(
        name: _nameController.text.trim(),
        contact: _contactController.text.trim(),
        services: widget.carrier.services ?? [],
      );

      final result = await _carrierServices.updateCarrier(
        widget.carrier.id!,
        dto,
        user.id,
      );

      if (result == "CONTACT_EXIST") {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('carrier_contact_already_used'),
        );
        return;
      } else if (result == "UPDATED") {
        if (mounted) Navigator.of(context).pop(true);
        showSuccessTopSnackBar(
          context,
          AppLocalizations.of(context).translate('carrier_updated_success'),
        );
        widget.onCarrierUpdated?.call();
      }
    } catch (e) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('carrier_update_error'),
      );
    } finally {
      if (mounted) setState(() => isFormLoading = false);
    }
  }
}
