import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/services/payment_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/payment_type_dialog.dart';

class SupplierPaymentScreen extends StatefulWidget {
  final Items item;
  final Partner supplier;

  const SupplierPaymentScreen({
    Key? key,
    required this.item,
    required this.supplier,
  }) : super(key: key);

  @override
  State<SupplierPaymentScreen> createState() => _SupplierPaymentScreenState();
}

class _SupplierPaymentScreenState extends State<SupplierPaymentScreen> {
  final PaymentServices paymentServices = PaymentServices();
  final AchatServices achatServices = AchatServices();
  final AuthService authService = AuthService();
  final TextEditingController _amountController = TextEditingController();
  bool _payFullAmount = false;
  bool isLoading = false;
  bool isLoadingAchat = true;
  late double _totalPrice;
  late double _alreadyPaid;
  late double _remainingAmount;
  Achat? achat;

  @override
  void initState() {
    super.initState();
    _totalPrice = widget.item.totalPrice ?? 0.0;
    _alreadyPaid = widget.item.amountPaid ?? 0.0;
    _remainingAmount = _calculateRemainingAmount();

    if (_remainingAmount > 0) {
      _payFullAmount = true;
      _amountController.text = _remainingAmount.toStringAsFixed(2);
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
      if (mounted) {
        setState(() {
          isLoadingAchat = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingAchat = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
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

  void _onPayFullAmountChanged(bool value) {
    setState(() {
      _payFullAmount = value;
      if (value) {
        _amountController.text = _remainingAmount.toStringAsFixed(2);
      } else {
        _amountController.clear();
      }
    });
  }

  double _calculateRemainingAmount() {
    final remaining = _totalPrice - _alreadyPaid;
    return remaining > 0 ? remaining : 0.0;
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final Color accentColor = Colors.orange[900]!;

    return Row(
      children: [
        Icon(icon, color: accentColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmPayment() async {
    final amountText = _amountController.text.trim();
    if (!_payFullAmount && amountText.isEmpty) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('please_enter_amount'),
      );
      return;
    }

    final parsedAmountText =
        _payFullAmount ? _remainingAmount.toStringAsFixed(2) : amountText;
    final sanitizedAmountText = parsedAmountText.replaceAll(',', '.');
    final amount = double.tryParse(sanitizedAmountText);
    if (amount == null || amount <= 0) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('invalid_amount'),
      );
      return;
    }

    if (amount > _remainingAmount) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('amount_exceeds_total'),
      );
      return;
    }

    // Afficher le dialog pour choisir le type de paiement
    final paymentResult = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => PaymentTypeDialog(),
    );

    if (paymentResult == null) {
      return; // L'utilisateur a annulé
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

      final DateTime paymentDate = (paymentResult['date'] as DateTime);

      final paymentResponse = await paymentServices.processSupplierPayment(
        itemId: widget.item.id!.toInt(),
        amount: amount,
        paymentDate: paymentDate,
        paidBy: user.id,
      );

      showSuccessTopSnackBar(
        context,
        paymentResponse.message ??
            AppLocalizations.of(context).translate('payment_success'),
      );
      Navigator.pop(context, true);
    } catch (e) {
      showErrorTopSnackBar(
        context,
        '${AppLocalizations.of(context).translate('payment_error')}: ${e.toString()}',
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('supplier_payment'),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate('purchase_number'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (isLoadingAchat)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  else
                                    Text(
                                      achat?.id != null
                                          ? '${achat!.id}'
                                          : 'N/A',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.business,
                                color: Colors.blue[600], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate('supplier'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.supplier.firstName} ${widget.supplier.lastName}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: Colors.blue[600], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)
                                        .translate('purchase_date'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (isLoadingAchat)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  else
                                    Text(
                                      achat?.createdAt != null
                                          ? DateFormat('dd/MM/yyyy')
                                              .format(achat!.createdAt!)
                                          : 'N/A',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                ],
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryItem(
                                icon: Icons.calculate_outlined,
                                label: AppLocalizations.of(context)
                                    .translate('total'),
                                value: '${_formatAmount(_totalPrice)} ¥',
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryItem(
                                icon: Icons.payments_outlined,
                                label: AppLocalizations.of(context)
                                    .translate('total_amount_paid'),
                                value: '${_formatAmount(_alreadyPaid)} ¥',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Switch pour payer le montant total
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('pay_full_amount'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch(
                          value: _payFullAmount,
                          onChanged: _onPayFullAmountChanged,
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Champ pour saisir le montant
                  TextFormField(
                    controller: _amountController,
                    enabled: !_payFullAmount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)
                          .translate('amount_not_paid'),
                      prefixIcon:
                          Icon(Icons.currency_yen, color: Colors.grey[600]),
                      filled: true,
                      fillColor:
                          _payFullAmount ? Colors.grey[100] : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  // Espace en bas pour le bouton fixe
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
                  onPressed: _confirmPayment,
                  label:
                      AppLocalizations.of(context).translate('confirm_payment'),
                  icon: Icons.check_circle,
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
