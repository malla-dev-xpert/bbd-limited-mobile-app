import 'package:flutter/material.dart';
import 'select_customer_and_versement_step.dart';
import 'purchase_items_step.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/versement.dart';

class PurchaseWizardDialog extends StatefulWidget {
  const PurchaseWizardDialog({Key? key}) : super(key: key);

  @override
  State<PurchaseWizardDialog> createState() => _PurchaseWizardDialogState();
}

class _PurchaseWizardDialogState extends State<PurchaseWizardDialog> {
  int _currentStep = 0;
  Partner? _selectedCustomer;
  Versement? _selectedVersement;

  // Pour la deuxième étape
  List<Map<String, dynamic>> _items = [];

  void _onCustomerAndVersementSelected(Partner customer, Versement versement) {
    setState(() {
      _selectedCustomer = customer;
      _selectedVersement = versement;
      _currentStep = 1;
    });
  }

  void _onItemsChanged(List<Map<String, dynamic>> items) {
    setState(() {
      _items = items;
    });
  }

  void _onFinish() {
    Navigator.of(context).pop();
    // TODO: Ajouter la logique de soumission finale si besoin
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _currentStep == 0
            ? SelectCustomerAndVersementStep(
                onNext: _onCustomerAndVersementSelected,
                onCancel: () => Navigator.of(context).pop(),
              )
            : PurchaseItemsStep(
                customer: _selectedCustomer!,
                versement: _selectedVersement!,
                initialItems: _items,
                onItemsChanged: _onItemsChanged,
                onBack: () => setState(() => _currentStep = 0),
                onFinish: _onFinish,
              ),
      ),
    );
  }
}
