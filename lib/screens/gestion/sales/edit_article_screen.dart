import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';

/// Page complète d'édition d'un article.
/// Remplace le bottom sheet d'édition.
class EditArticleScreen extends StatefulWidget {
  final Items item;
  final Achat achat;

  const EditArticleScreen({
    super.key,
    required this.item,
    required this.achat,
  });

  @override
  State<EditArticleScreen> createState() => _EditArticleScreenState();
}

class _EditArticleScreenState extends State<EditArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _invoiceController;
  late TextEditingController _descriptionController;
  late TextEditingController _cartonController;
  late TextEditingController _quantityPerCartonController;
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _salesRateController;
  late TextEditingController _weightController;
  late TextEditingController _totalWeightController;
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _cbnIndividualController;
  late TextEditingController _cbnTotalController;

  List<Partner> _suppliers = [];
  Partner? _selectedSupplier;
  bool _loadingSuppliers = true;
  String? _errorSuppliers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _invoiceController = TextEditingController(text: item.invoiceNumber ?? '');
    _descriptionController =
        TextEditingController(text: item.description ?? '');
    _cartonController =
        TextEditingController(text: item.carton?.toString() ?? '');
    _quantityPerCartonController =
        TextEditingController(text: item.quantityPerCarton?.toString() ?? '');
    _quantityController =
        TextEditingController(text: item.quantity?.toString() ?? '');
    _unitPriceController =
        TextEditingController(text: item.unitPrice?.toString() ?? '');
    _salesRateController =
        TextEditingController(text: item.salesRate?.toString() ?? '');
    _weightController =
        TextEditingController(text: item.weight?.toString() ?? '');
    _totalWeightController = TextEditingController();
    _lengthController =
        TextEditingController(text: item.cartonLength?.toString() ?? '');
    _widthController =
        TextEditingController(text: item.cartonWidth?.toString() ?? '');
    _heightController =
        TextEditingController(text: item.cartonHeight?.toString() ?? '');
    _cbnIndividualController = TextEditingController();
    _cbnTotalController = TextEditingController();
    _quantityController.addListener(_updateDerivedFields);
    _cartonController.addListener(_updateTotalQuantity);
    _cartonController.addListener(_updateDerivedFields);
    _cartonController.addListener(_updateCbn);
    _quantityPerCartonController.addListener(_updateTotalQuantity);
    _weightController.addListener(_updateDerivedFields);
    _lengthController.addListener(_updateCbn);
    _widthController.addListener(_updateCbn);
    _heightController.addListener(_updateCbn);
    _updateTotalQuantity();
    _updateDerivedFields();
    _loadSuppliers();
  }

  void _updateTotalQuantity() {
    final carton = int.tryParse(_cartonController.text) ?? 0;
    final qpc = int.tryParse(_quantityPerCartonController.text) ?? 0;
    _quantityController.removeListener(_updateDerivedFields);
    _quantityController.text = (carton * qpc).toString();
    _quantityController.addListener(_updateDerivedFields);
    _updateDerivedFields();
  }

  void _updateDerivedFields() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final weight =
        double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;
    final totalWeight = weight * quantity;
    _totalWeightController.text = totalWeight.toStringAsFixed(2);
  }

  /// Dimensions L, l, H en centimètres → volume en m³ = (L × l × H) / 1000000.
  void _updateCbn() {
    final lCm =
        double.tryParse(_lengthController.text.replaceAll(',', '.')) ?? 0.0;
    final wCm =
        double.tryParse(_widthController.text.replaceAll(',', '.')) ?? 0.0;
    final hCm =
        double.tryParse(_heightController.text.replaceAll(',', '.')) ?? 0.0;
    // cm³ → m³ : diviser par 1 000 000
    final cbnIndividualM3 = (lCm * wCm * hCm) / 1000000;
    final carton = int.tryParse(_cartonController.text) ?? 0;
    final cbnTotalM3 = cbnIndividualM3 * carton;
    _cbnIndividualController.text = '${cbnIndividualM3.toStringAsFixed(4)} m³';
    _cbnTotalController.text = '${cbnTotalM3.toStringAsFixed(4)} m³';
  }

  Future<void> _loadSuppliers() async {
    try {
      final list = await PartnerServices().findSuppliers();
      if (!mounted) return;
      setState(() {
        _suppliers = list;
        _loadingSuppliers = false;
        if (list.isNotEmpty) {
          _selectedSupplier = list.cast<Partner?>().firstWhere(
                (s) => s?.id == widget.item.supplierId,
                orElse: () => list.first,
              );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorSuppliers =
            AppLocalizations.of(context).translate('error_loading_suppliers');
        _loadingSuppliers = false;
      });
    }
  }

  String _supplierDisplay(Partner p) {
    final first = p.firstName;
    final last = p.lastName.trim();
    return '$first${last.isNotEmpty ? ' $last' : ''}'.trim();
  }

  @override
  void dispose() {
    _quantityController.removeListener(_updateDerivedFields);
    _cartonController.removeListener(_updateTotalQuantity);
    _cartonController.removeListener(_updateDerivedFields);
    _cartonController.removeListener(_updateCbn);
    _quantityPerCartonController.removeListener(_updateTotalQuantity);
    _weightController.removeListener(_updateDerivedFields);
    _lengthController.removeListener(_updateCbn);
    _widthController.removeListener(_updateCbn);
    _heightController.removeListener(_updateCbn);
    _invoiceController.dispose();
    _descriptionController.dispose();
    _cartonController.dispose();
    _quantityPerCartonController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _salesRateController.dispose();
    _weightController.dispose();
    _totalWeightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _cbnIndividualController.dispose();
    _cbnTotalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final user = await AuthService().getUserInfo();
    if (user == null) {
      showErrorTopSnackBar(context,
          AppLocalizations.of(context).translate('user_not_connected'));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final carton = int.tryParse(_cartonController.text) ?? 0;
      final quantityPerCarton =
          int.tryParse(_quantityPerCartonController.text) ?? 0;
      final totalQuantity = carton * quantityPerCarton;
      final unitPrice =
          double.tryParse(_unitPriceController.text.replaceAll(',', '.')) ??
              0.0;
      final weight =
          double.tryParse(_weightController.text.replaceAll(',', '.'));
      final lengthCm =
          double.tryParse(_lengthController.text.replaceAll(',', '.')) ?? 0.0;
      final widthCm =
          double.tryParse(_widthController.text.replaceAll(',', '.')) ?? 0.0;
      final heightCm =
          double.tryParse(_heightController.text.replaceAll(',', '.')) ?? 0.0;
      // Dimensions en cm → CBN en m³ = (L × l × H) / 1000000
      final cbnIndividualM3 = (lengthCm * widthCm * heightCm) / 1000000;
      final cbnTotalM3 = cbnIndividualM3 * carton;
      final weightIndividual = weight ?? 0.0;
      final totalWeightValue = weightIndividual * totalQuantity;

      final updated = Items(
        id: widget.item.id,
        description: _descriptionController.text,
        carton: carton,
        quantityPerCarton: quantityPerCarton,
        quantity: totalQuantity,
        unitPrice: unitPrice,
        totalPrice: totalQuantity * unitPrice,
        supplierId: _selectedSupplier?.id,
        supplierName: _selectedSupplier != null
            ? _supplierDisplay(_selectedSupplier!)
            : widget.item.supplierName,
        supplierPhone: _selectedSupplier?.phoneNumber,
        packageId: widget.item.packageId,
        salesRate:
            double.tryParse(_salesRateController.text.replaceAll(',', '.')) ??
                widget.item.salesRate,
        status: widget.item.status,
        invoiceNumber: _invoiceController.text.trim().isEmpty
            ? null
            : _invoiceController.text.trim(),
        weight: weight,
        totalWeight: totalWeightValue,
        cartonLength: lengthCm,
        cartonWidth: widthCm,
        cartonHeight: heightCm,
        cbn: cbnIndividualM3,
        cbnTotal: cbnTotalM3,
      );

      final result = await ItemServices().updateItem(
        itemId: widget.item.id!,
        userId: user.id,
        item: updated,
        clientId: widget.achat.clientId ?? widget.item.clientId,
      );
      if (result.success == true && mounted) {
        showSuccessTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('purchase_history_item_modified_success'),
        );
        Navigator.pop(context, updated);
      }
    } on ItemUpdateException catch (e) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context);
      String msg = e.message;
      if (e.errorCode == 'ITEM_NOT_FOUND')
        msg = loc.translate('purchase_history_item_not_found');
      else if (e.errorCode == 'USER_NOT_FOUND')
        msg = loc.translate('purchase_history_user_not_found');
      else if (e.errorCode == 'CLIENT_MISMATCH')
        msg = loc.translate('purchase_history_client_mismatch');
      else if (e.errorCode == 'SUPPLIER_NOT_FOUND')
        msg = loc.translate('purchase_history_supplier_not_found');
      showErrorTopSnackBar(context, msg);
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('purchase_history_error_occurred')
              .replaceAll('{error}', e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(loc.translate('purchase_history_edit_item_title')),
        backgroundColor: const Color(0xFF1A1E49),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loadingSuppliers
          ? const Center(child: CircularProgressIndicator())
          : _errorSuppliers != null
              ? Center(child: Text(_errorSuppliers!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buildTextField(
                          controller: _invoiceController,
                          label: loc.translate('invoice_number'),
                          icon: Icons.receipt_long,
                        ),
                        const SizedBox(height: 12),
                        buildTextField(
                          controller: _descriptionController,
                          label: loc
                              .translate('purchase_history_edit_description'),
                          icon: Icons.description,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.translate('carton'),
                          style: AppTextSize.bodyStyle(context,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: buildTextField(
                                controller: _cartonController,
                                label: loc.translate('carton'),
                                icon: Icons.inventory_2,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: buildTextField(
                                controller: _quantityPerCartonController,
                                label: loc.translate('quantity_per_carton'),
                                icon: Icons.format_list_numbered,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _readOnlyField(
                          controller: _quantityController,
                          label: loc.translate('total_quantity'),
                          hint: loc.translate('calculated_automatically'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.translate('weight'),
                          style: AppTextSize.bodyStyle(context,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: buildTextField(
                                controller: _weightController,
                                label:
                                    '${loc.translate('weight')} (individuel)',
                                icon: Icons.scale,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _readOnlyField(
                                controller: _totalWeightController,
                                label: '${loc.translate('weight')} total',
                                hint: loc.translate('calculated_automatically'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'CBN / CBM (m³)',
                          style: AppTextSize.bodyStyle(context,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dimensions en centimètres',
                          style: AppTextSize.captionStyle(context, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: buildTextField(
                                controller: _lengthController,
                                label: 'Longueur (cm)',
                                icon: Icons.straighten,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: buildTextField(
                                controller: _widthController,
                                label: 'Largeur (cm)',
                                icon: Icons.straighten,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: buildTextField(
                                controller: _heightController,
                                label: 'Hauteur (cm)',
                                icon: Icons.straighten,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _readOnlyField(
                                controller: _cbnIndividualController,
                                label: 'CBN (individuel) m³',
                                hint: loc.translate('calculated_automatically'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _readOnlyField(
                                controller: _cbnTotalController,
                                label: 'CBN total m³',
                                hint: loc.translate('calculated_automatically'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        buildTextField(
                          controller: _unitPriceController,
                          label:
                              loc.translate('purchase_history_edit_unit_price'),
                          icon: Icons.attach_money,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                        const SizedBox(height: 12),
                        buildTextField(
                          controller: _salesRateController,
                          label: loc
                              .translate('purchase_history_edit_purchase_rate'),
                          icon: Icons.percent,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                        const SizedBox(height: 12),
                        DropDownCustom<Partner>(
                          items: _suppliers,
                          selectedItem: _selectedSupplier,
                          onChanged: (v) =>
                              setState(() => _selectedSupplier = v),
                          itemToString: _supplierDisplay,
                          hintText:
                              loc.translate('purchase_history_edit_supplier'),
                          prefixIcon: Icons.person,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(loc
                                    .translate('purchase_history_edit_cancel')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: confirmationButton(
                                icon: Icons.save,
                                label:
                                    loc.translate('purchase_history_edit_save'),
                                isLoading: _isSaving,
                                subLabel: 'Modification...',
                                onPressed: _save,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _readOnlyField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(Icons.calculate, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
