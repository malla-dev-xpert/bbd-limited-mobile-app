import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/create_container_form.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/components/confirm_btn.dart';

class CreateContainerPage extends StatefulWidget {
  const CreateContainerPage({super.key});

  @override
  State<CreateContainerPage> createState() => _CreateContainerPageState();
}

class _CreateContainerPageState extends State<CreateContainerPage> {
  final GlobalKey<CreateContainerFormState> _formKey =
      GlobalKey<CreateContainerFormState>();
  int _currentStep = 0;

  String _getStepTitle() {
    final isEmployeD = _formKey.currentState?.isEmployeD ?? false;
    switch (_currentStep) {
      case 0:
        return AppLocalizations.of(context)!.translate('container_create');
      case 1:
        return isEmployeD
            ? AppLocalizations.of(context)!
                .translate('container_form_fees_step')
            : AppLocalizations.of(context)!
                .translate('container_form_location_fee');
      case 2:
        return isEmployeD
            ? AppLocalizations.of(context)!
                .translate('container_items_step_title')
            : AppLocalizations.of(context)!
                .translate('container_form_other_fees');
      case 3:
        return AppLocalizations.of(context)!
            .translate('container_items_step_title');
      default:
        return AppLocalizations.of(context)!.translate('container_create');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _getStepTitle(),
          style: AppTextSize.headlineStyle(context, color: Colors.white, fontWeight: FontWeight.w600).copyWith(letterSpacing: 0.5),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _formKey.currentState?.goToPreviousStep();
                },
              )
            : null,
      ),
      body: CreateContainerForm(
        key: _formKey,
        onStepChanged: (step) {
          setState(() {
            _currentStep = step;
          });
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _formKey.currentState?.goToPreviousStep();
                    },
                    icon: const Icon(Icons.arrow_back),
                    label:
                        Text(AppLocalizations.of(context)!.translate('back')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                flex: _currentStep == 0 ? 1 : 1,
                child: Builder(
                  builder: (context) {
                    final maxStep =
                        _formKey.currentState?.maxStepIndex ?? 3;
                    return confirmationButton(
                      isLoading:
                          _formKey.currentState?.isLoadingState ?? false,
                      onPressed: _currentStep < maxStep
                          ? () {
                              _formKey.currentState?.goToNextStep();
                            }
                          : () {
                              _formKey.currentState?.submitForm();
                            },
                      label: _currentStep < maxStep
                          ? AppLocalizations.of(context)!.translate('next')
                          : AppLocalizations.of(context)!
                              .translate('container_form_save'),
                      icon: _currentStep < maxStep
                          ? Icons.arrow_forward
                          : Icons.check,
                      subLabel: _currentStep < maxStep
                          ? ""
                          : AppLocalizations.of(context)!
                              .translate('container_form_saving'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
