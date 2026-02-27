import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/core/services/carrier_services.dart';
import 'package:bbd_limited/core/services/harbor_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/models/carrier.dart';
import 'package:bbd_limited/models/harbor.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/create_carrier_bottom_sheet.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/harbor/widgets/add_harbor.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/widgets/create_supplier_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:intl/intl.dart';

class ContainerInfoForm extends StatefulWidget {
  final TextEditingController refController;
  final TextEditingController size;
  final bool initialAvailability;
  final Partner? selectedSupplier;
  final int? initialDepartureHarborId;
  final int? initialArrivalHarborId;
  final DateTime? initialDepartureDate;
  final DateTime? initialArrivalDate;

  /// Date de chargement (optionnelle).
  final DateTime? initialLoadingDate;
  final int? initialCarrierId;
  final Function(bool)? onAvailabilityChanged;
  final Function(Partner?)? onSupplierChanged;
  final Function(Carrier?)? onCarrierChanged;

  const ContainerInfoForm({
    Key? key,
    required this.refController,
    required this.size,
    this.initialAvailability = false,
    this.selectedSupplier,
    this.initialDepartureHarborId,
    this.initialArrivalHarborId,
    this.initialDepartureDate,
    this.initialArrivalDate,
    this.initialLoadingDate,
    this.initialCarrierId,
    this.onAvailabilityChanged,
    this.onSupplierChanged,
    this.onCarrierChanged,
  }) : super(key: key);

  @override
  ContainerInfoFormState createState() => ContainerInfoFormState();
}

class ContainerInfoFormState extends State<ContainerInfoForm> {
  late bool _isAvailable;
  List<Carrier> carriers = [];
  Carrier? selectedCarrier;
  List<Partner> suppliers = [];
  Partner? selectedSupplier;
  List<Harbor> harbors = [];
  Harbor? selectedDepartureHarbor;
  Harbor? selectedArrivalHarbor;
  bool get isAvailable => _isAvailable;
  int? get departureHarborId => selectedDepartureHarbor?.id;
  int? get arrivalHarborId => selectedArrivalHarbor?.id;
  DateTime? _departureDate;
  DateTime? _arrivalDate;
  DateTime? _loadingDate;
  DateTime? get departureDate => _departureDate;
  DateTime? get arrivalDate => _arrivalDate;
  DateTime? get loadingDate => _loadingDate;
  final PartnerServices _partnerServices = PartnerServices();
  final HarborServices _harborServices = HarborServices();
  final CarrierServices _carrierServices = CarrierServices();
  String? _selectedSize;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.initialAvailability;
    _departureDate = widget.initialDepartureDate;
    _arrivalDate = widget.initialArrivalDate;
    _loadingDate = widget.initialLoadingDate;
    _loadSuppliers();
    _loadHarbors();
    _loadCarriers();
    selectedSupplier = widget.selectedSupplier;
    if (widget.size.text.isNotEmpty) {
      _selectedSize = widget.size.text;
    }
  }

  Future<void> _loadSuppliers() async {
    final data = await _partnerServices.findSuppliers(page: 0);
    setState(() {
      suppliers = data;
    });
  }

  Future<void> _loadHarbors() async {
    try {
      final data = await _harborServices.findAll();
      setState(() {
        final wasEmpty = harbors.isEmpty;
        harbors = data;
        if (wasEmpty) {
          if (widget.initialDepartureHarborId != null) {
            final found = data
                .where((h) => h.id == widget.initialDepartureHarborId)
                .toList();
            selectedDepartureHarbor = found.isEmpty ? null : found.first;
          }
          if (widget.initialArrivalHarborId != null) {
            final found = data
                .where((h) => h.id == widget.initialArrivalHarborId)
                .toList();
            selectedArrivalHarbor = found.isEmpty ? null : found.first;
          }
        }
      });
    } catch (_) {
      setState(() => harbors = []);
    }
  }

  Future<void> _showAddHarborModal() async {
    final added = await showAddHarborModal(context);
    if (added == true) {
      await _loadHarbors();
    }
  }

  Future<void> _loadCarriers() async {
    try {
      final data = await _carrierServices.getAllCarriers(page: 0);
      setState(() {
        carriers = data;
        if (widget.initialCarrierId != null) {
          final found =
              data.where((c) => c.id == widget.initialCarrierId).toList();
          selectedCarrier = found.isEmpty ? null : found.first;
        }
      });
    } catch (_) {
      setState(() => carriers = []);
    }
  }

  void _showCreateCarrierBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateCarrierBottomSheet(),
    ).then((_) {
      _loadCarriers();
    });
  }

  void _showCreateSupplierBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateSupplierBottomSheet(),
    ).then((_) {
      _loadSuppliers();
    });
  }

  Widget _buildDateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[700], size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date != null ? DateFormat.yMd().format(date) : '—',
                        style: TextStyle(
                          fontSize: 16,
                          color: date != null
                              ? Colors.grey[800]
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSizeButton(String size) {
    final bool isSelected = _selectedSize == size;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          elevation: isSelected ? 4 : 1,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedSize = size;
                widget.size.text = size;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.grey[100],
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: Text(
                size,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildTextField(
            controller: widget.refController,
            label: AppLocalizations.of(context)!
                .translate('container_form_reference'),
            icon: Icons.description,
            validator: (v) => v == null || v.isEmpty
                ? AppLocalizations.of(context)!
                    .translate('container_form_validation_reference')
                : null,
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                  child: Text(
                      AppLocalizations.of(context)!
                          .translate('container_form_size'),
                      style: const TextStyle(fontSize: 18)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSizeButton(
                        "20 ${AppLocalizations.of(context)!.translate('container_size_feet')}"),
                    _buildSizeButton(
                        "40 ${AppLocalizations.of(context)!.translate('container_size_feet')}"),
                    _buildSizeButton(
                        "45 ${AppLocalizations.of(context)!.translate('container_size_feet')}"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                flex: 3,
                child: DropDownCustom<Harbor>(
                  items: harbors,
                  selectedItem: selectedDepartureHarbor,
                  onChanged: (h) {
                    setState(() => selectedDepartureHarbor = h);
                  },
                  itemToString: (h) =>
                      '${h.name ?? ''}${(h.location ?? '').isNotEmpty ? ' - ${h.location}' : ''}',
                  hintText: AppLocalizations.of(context)!
                      .translate('choose_departure_port'),
                  prefixIcon: Icons.sailing,
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  onPressed: _showAddHarborModal,
                  icon: const Icon(Icons.add),
                  tooltip: AppLocalizations.of(context)!
                      .translate('container_form_add_port'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                flex: 3,
                child: DropDownCustom<Harbor>(
                  items: harbors,
                  selectedItem: selectedArrivalHarbor,
                  onChanged: (h) {
                    setState(() => selectedArrivalHarbor = h);
                  },
                  itemToString: (h) =>
                      '${h.name ?? ''}${(h.location ?? '').isNotEmpty ? ' - ${h.location}' : ''}',
                  hintText: AppLocalizations.of(context)!
                      .translate('choose_arrival_port'),
                  prefixIcon: Icons.pin_drop,
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  onPressed: _showAddHarborModal,
                  icon: const Icon(Icons.add),
                  tooltip: AppLocalizations.of(context)!
                      .translate('container_form_add_port'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildDateTile(
            label: AppLocalizations.of(context)!.translate('departure_date'),
            date: _departureDate,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _departureDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _departureDate = picked);
              }
            },
            icon: Icons.event,
          ),
          const SizedBox(height: 10),
          _buildDateTile(
            label: AppLocalizations.of(context)!
                .translate('estimated_arrival_date'),
            date: _arrivalDate,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _arrivalDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _arrivalDate = picked);
              }
            },
            icon: Icons.event,
          ),
          const SizedBox(height: 10),
          _buildDateTile(
            label: AppLocalizations.of(context)!.translate('loading_date'),
            date: _loadingDate,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _loadingDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _loadingDate = picked);
              }
            },
            icon: Icons.event,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                flex: 3,
                child: DropDownCustom<Partner>(
                  items: suppliers,
                  selectedItem: selectedSupplier,
                  onChanged: (s) {
                    setState(() {
                      selectedSupplier = s;
                    });
                    widget.onSupplierChanged?.call(s);
                  },
                  itemToString: (client) =>
                      '${client.firstName} ${client.lastName} ${client.lastName.isNotEmpty ? '|' : ''} ${client.phoneNumber}',
                  hintText: AppLocalizations.of(context)!
                      .translate('container_form_supplier'),
                  prefixIcon: Icons.person,
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  onPressed: _showCreateSupplierBottomSheet,
                  icon: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: const BorderRadius.all(Radius.circular(32)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                      AppLocalizations.of(context)!
                          .translate('container_form_availability'),
                      style: const TextStyle(fontSize: 18)),
                ),
                Switch(
                  value: _isAvailable,
                  activeColor: Colors.green,
                  activeTrackColor: Colors.green[200],
                  inactiveThumbColor: Colors.grey[400],
                  inactiveTrackColor: Colors.grey[200],
                  onChanged: (value) {
                    setState(() => _isAvailable = value);
                    widget.onAvailabilityChanged?.call(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                flex: 3,
                child: DropDownCustom<Carrier>(
                  items: carriers,
                  selectedItem: selectedCarrier,
                  onChanged: (c) {
                    setState(() {
                      selectedCarrier = c;
                    });
                    widget.onCarrierChanged?.call(c);
                  },
                  itemToString: (c) => '${c.name ?? ''} | ${c.contact ?? ''}',
                  hintText:
                      AppLocalizations.of(context)!.translate('choose_carrier'),
                  prefixIcon: Icons.local_shipping,
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  onPressed: _showCreateCarrierBottomSheet,
                  icon: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
