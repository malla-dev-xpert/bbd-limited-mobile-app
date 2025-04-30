import 'dart:developer';

import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/package.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/warehouses.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/warehouse_services.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/widgets/client_dropdown.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/widgets/package_info_form.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/packages/widgets/warehouse_dropdown.dart';

class EditPackageModal extends StatefulWidget {
  final Packages package;
  final Function() onPackageUpdated;

  const EditPackageModal({
    super.key,
    required this.package,
    required this.onPackageUpdated,
  });

  @override
  State<EditPackageModal> createState() => _EditPackageModalState();
}

class _EditPackageModalState extends State<EditPackageModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _refController;
  late final TextEditingController _dimensionController;
  late final TextEditingController _weightController;
  late final TextEditingController _nameController;

  bool _isLoading = false;
  final PackageServices _packageServices = PackageServices();
  final PartnerServices _partnerServices = PartnerServices();
  final WarehouseServices _warehouseServices = WarehouseServices();
  final AuthService _authService = AuthService();

  List<Partner> _clients = [];
  Partner? _selectedClient;
  List<Warehouses> _warehouses = [];
  Warehouses? _selectedWarehouse;

  @override
  void initState() {
    super.initState();
    _refController = TextEditingController(text: widget.package.reference);
    _dimensionController = TextEditingController(
      text: widget.package.dimensions,
    );
    _weightController = TextEditingController(
      text: widget.package.weight?.toString(),
    );
    _nameController = TextEditingController(text: widget.package.name);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final clients = await _partnerServices.fetchPartnersByType(
        'CLIENT',
        page: 0,
      );
      final warehouses = await _warehouseServices.findAllWarehouses(page: 0);

      // Trouver le client actuellement sélectionné (si disponible)
      if (widget.package.partnerName != null) {
        _selectedClient = clients.firstWhere(
          (c) => c.firstName + ' ' + c.lastName == widget.package.partnerName,
          orElse: () => clients.first,
        );
      }

      // Trouver l'entrepôt actuellement sélectionné (si disponible)
      if (widget.package.warehouseName != null) {
        _selectedWarehouse = warehouses.firstWhere(
          (w) => w.name == widget.package.warehouseName,
          orElse: () => warehouses.first,
        );
      }

      setState(() {
        _clients = clients;
        _warehouses = warehouses;
      });
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(context, "Erreur lors du chargement des données");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un client");
      return;
    }
    if (_selectedWarehouse == null) {
      showErrorTopSnackBar(context, "Veuillez sélectionner un entrepôt");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context, "Erreur: Utilisateur non connecté");
        return;
      }

      final updatedPackage = widget.package.copyWith(
        name: _nameController.text,
        reference: _refController.text,
        dimensions: _dimensionController.text,
        weight: double.tryParse(_weightController.text),
        partnerId: _selectedClient!.id,
        warehouseId: _selectedWarehouse!.id,
      );

      await _packageServices.updatePackage(
        widget.package.id,
        user.id,
        updatedPackage,
      );

      widget.onPackageUpdated();
      if (mounted) {
        Navigator.pop(context);
        showSuccessTopSnackBar(context, "Colis modifié avec succès !");
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          "Erreur lors de la modification: ${e.toString()}",
        );
        log(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Modifier le colis",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PackageInfoForm(
                refController: _refController,
                weightController: _weightController,
                dimensionController: _dimensionController,
                // nameController: _nameController,
              ),
              const SizedBox(height: 16),
              ClientDropdown(
                clients: _clients,
                selectedClient: _selectedClient,
                onChanged: (client) => setState(() => _selectedClient = client),
              ),
              const SizedBox(height: 16),
              WarehouseDropdown(
                warehouses: _warehouses,
                selectedWarehouse: _selectedWarehouse,
                onChanged:
                    (warehouse) =>
                        setState(() => _selectedWarehouse = warehouse),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: confirmationButton(
                  isLoading: _isLoading,
                  onPressed: _submitForm,
                  label: "Enregistrer les modifications",
                  icon: Icons.edit_document,
                  subLabel: "Modification...",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refController.dispose();
    _dimensionController.dispose();
    _weightController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
