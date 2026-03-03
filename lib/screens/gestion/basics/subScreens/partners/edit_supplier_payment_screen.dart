import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';

class EditSupplierPaymentScreen extends StatefulWidget {
  final Items item;
  final Partner supplier;

  const EditSupplierPaymentScreen({
    Key? key,
    required this.item,
    required this.supplier,
  }) : super(key: key);

  @override
  State<EditSupplierPaymentScreen> createState() =>
      _EditSupplierPaymentScreenState();
}

class _EditSupplierPaymentScreenState extends State<EditSupplierPaymentScreen> {
  final ItemServices itemServices = ItemServices();
  final AuthService authService = AuthService();
  final AchatServices achatServices = AchatServices();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  DateTime? _selectedDate;
  bool isLoading = false;
  Achat? achat;

  @override
  void initState() {
    super.initState();
    // Initialiser avec les valeurs actuelles du paiement
    _amountController.text = (widget.item.amountPaid ?? 0.0).toStringAsFixed(2);
    _selectedDate = widget.item.paiementDate;
    if (_selectedDate != null) {
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    }
    _loadAchat();
  }

  Future<void> _loadAchat() async {
    try {
      final achats = await achatServices.findAll();
      if (achats.isNotEmpty) {
        // Trouver l'achat qui contient cet item
        try {
          achat = achats.firstWhere(
            (a) => a.items?.any((i) => i.id == widget.item.id) ?? false,
          );
        } catch (e) {
          // Si aucun achat ne contient cet item, garder null
          achat = null;
        }
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement
      achat = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatAmount(double? amount) {
    if (amount == null) return "0,00";
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]} ',
        )
        .replaceAll('.', ',');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _confirmUpdate() async {
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (amount == null || amount < 0) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('invalid_amount'),
      );
      return;
    }

    if (_selectedDate == null) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('please_select_date'),
      );
      return;
    }

    final totalPrice = widget.item.totalPrice ?? 0.0;
    if (amount > totalPrice) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('amount_exceeds_total'),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = await authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('user_not_connected'),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Vérifier que l'achat a été chargé et contient un clientId
      if (achat?.clientId == null) {
        // Recharger l'achat si nécessaire
        await _loadAchat();
        if (achat?.clientId == null) {
          showErrorTopSnackBar(
            context,
            AppLocalizations.of(context).translate('error_loading_achat') ??
                'Erreur lors du chargement de l\'achat',
          );
          setState(() {
            isLoading = false;
          });
          return;
        }
      }

      // Créer un item mis à jour avec les nouvelles valeurs de paiement
      final updatedItem = widget.item.copyWith(
        amountPaid: amount,
        paiementDate: _selectedDate,
        paid: amount > 0,
      );

      // Utiliser updateItem pour mettre à jour le paiement avec le clientId
      final result = await itemServices.updateItem(
        itemId: widget.item.id!,
        userId: user.id,
        item: updatedItem,
        clientId: achat!.clientId!,
      );

      if (result.success == true) {
        showSuccessTopSnackBar(
          context,
          AppLocalizations.of(context).translate('payment_updated_success'),
        );
        Navigator.pop(context, true);
      } else {
        showErrorTopSnackBar(
          context,
          result.message ??
              AppLocalizations.of(context).translate('payment_update_error'),
        );
      }
    } catch (e) {
      showErrorTopSnackBar(
        context,
        '${AppLocalizations.of(context).translate('payment_update_error')}: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.item.totalPrice ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('edit_payment'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations de l'article
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shopping_cart,
                                color: Colors.blue[600], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.item.description ?? 'N/A',
                                style: AppTextSize.titleStyle(context,
                                    color: Colors.black87),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate('total'),
                                    style: AppTextSize.bodyStyle(context,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${_formatAmount(totalPrice)} ¥',
                                    style: AppTextSize.titleStyle(context,
                                        color: Colors.orange[900]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Champ pour le montant payé
                  buildTextField(
                    controller: _amountController,
                    label: AppLocalizations.of(context)
                        .translate('total_amount_paid'),
                    icon: Icons.currency_yen,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),

                  // Champ pour la date de paiement
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: buildTextField(
                        controller: _dateController,
                        label:
                            AppLocalizations.of(context).translate('paid_date'),
                        icon: Icons.calendar_today,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // Bouton fixe en bas
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: confirmationButton(
                  isLoading: isLoading,
                  onPressed: _confirmUpdate,
                  label: AppLocalizations.of(context).translate('update'),
                  icon: Icons.save,
                  subLabel:
                      AppLocalizations.of(context).translate('processing'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
