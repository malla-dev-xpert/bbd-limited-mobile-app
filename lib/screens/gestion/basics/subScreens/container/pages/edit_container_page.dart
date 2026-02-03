import 'package:flutter/material.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/edit_container_modal.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/components/confirm_btn.dart';

class EditContainerPage extends StatefulWidget {
  final Containers container;
  final Function() onContainerUpdated;

  const EditContainerPage({
    super.key,
    required this.container,
    required this.onContainerUpdated,
  });

  @override
  State<EditContainerPage> createState() => _EditContainerPageState();
}

class _EditContainerPageState extends State<EditContainerPage> {
  final GlobalKey<EditContainerModalState> _formKey =
      GlobalKey<EditContainerModalState>();
  int _currentStep = 0;

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return AppLocalizations.of(context)!.translate('container_edit');
      case 1:
        return AppLocalizations.of(context)!
            .translate('container_form_location_fee');
      case 2:
        return AppLocalizations.of(context)!
            .translate('container_form_other_fees');
      case 3:
        return AppLocalizations.of(context)!
            .translate('container_items_step_title');
      default:
        return AppLocalizations.of(context)!.translate('container_edit');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getStepTitle()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _formKey.currentState?.goToPreviousStep();
                },
              )
            : null,
      ),
      backgroundColor: Colors.white,
      body: EditContainerModal(
        key: _formKey,
        container: widget.container,
        onContainerUpdated: widget.onContainerUpdated,
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
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
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
                child: confirmationButton(
                  isLoading: _formKey.currentState?.isLoadingState ?? false,
                  onPressed: _currentStep < 3
                      ? () {
                          _formKey.currentState?.goToNextStep();
                        }
                      : () {
                          _formKey.currentState?.submitForm();
                        },
                  label: _currentStep < 2
                      ? AppLocalizations.of(context)!.translate('next')
                      : AppLocalizations.of(context)!
                              .translate('container_form_save') ??
                          'Enregistrer',
                  icon: _currentStep < 3 ? Icons.arrow_forward : Icons.check,
                  subLabel: _currentStep < 3
                      ? ""
                      : AppLocalizations.of(context)!
                              .translate('container_form_saving') ??
                          'Enregistrement...',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
