import 'package:flutter/material.dart';
import 'package:bbd_limited/models/expedition.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:intl/intl.dart';

class EditExpeditionBottomSheet extends StatefulWidget {
  final Expedition expedition;
  final Function(Expedition) onSave;

  const EditExpeditionBottomSheet({
    Key? key,
    required this.expedition,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditExpeditionBottomSheet> createState() =>
      _EditExpeditionBottomSheetState();
}

class _EditExpeditionBottomSheetState extends State<EditExpeditionBottomSheet> {
  late TextEditingController _refController;
  late TextEditingController _clientNameController;
  late TextEditingController _clientPhoneController;
  late TextEditingController _weightController;
  late TextEditingController _cbnController;
  late TextEditingController _itemQuantityController;
  late DateTime _startDate;
  late DateTime _arrivalDate;
  late String _expeditionType;
  late String _startCountry;
  late String _destinationCountry;

  @override
  void initState() {
    super.initState();
    _refController = TextEditingController(text: widget.expedition.ref);
    _clientNameController = TextEditingController(
      text: widget.expedition.clientName,
    );
    _clientPhoneController = TextEditingController(
      text: widget.expedition.clientPhone,
    );
    _weightController = TextEditingController(
      text: widget.expedition.weight?.toString(),
    );
    _cbnController = TextEditingController(
      text: widget.expedition.cbn?.toString(),
    );
    _itemQuantityController = TextEditingController(
      text: widget.expedition.itemQuantity?.toString(),
    );
    _startDate = widget.expedition.startDate ?? DateTime.now();
    _arrivalDate =
        widget.expedition.arrivalDate ??
        DateTime.now().add(const Duration(days: 7));
    _expeditionType = widget.expedition.expeditionType ?? 'avion';
    _startCountry = widget.expedition.startCountry ?? '';
    _destinationCountry = widget.expedition.destinationCountry ?? '';
  }

  @override
  void dispose() {
    _refController.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _weightController.dispose();
    _cbnController.dispose();
    _itemQuantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _arrivalDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _arrivalDate = picked;
        }
      });
    }
  }

  void _saveExpedition() {
    final updatedExpedition = widget.expedition.copyWith(
      ref: _refController.text,
      clientName: _clientNameController.text,
      clientPhone: _clientPhoneController.text,
      weight: double.tryParse(_weightController.text),
      cbn: double.tryParse(_cbnController.text),
      itemQuantity: int.tryParse(_itemQuantityController.text)?.toDouble(),
      startDate: _startDate,
      arrivalDate: _arrivalDate,
      expeditionType: _expeditionType,
      startCountry: _startCountry,
      destinationCountry: _destinationCountry,
    );

    widget.onSave(updatedExpedition);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Modifier l\'expédition',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1E49),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    label: 'Référence',
                    controller: _refController,
                    icon: Icons.numbers,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Nom du client',
                    controller: _clientNameController,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Téléphone du client',
                    controller: _clientPhoneController,
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTypeSelector(),
                  const SizedBox(height: 16),
                  _expeditionType.toLowerCase() == 'avion'
                      ? _buildTextField(
                        label: 'Poids (kg)',
                        controller: _weightController,
                        icon: Icons.scale,
                        keyboardType: TextInputType.number,
                      )
                      : _buildTextField(
                        label: 'CBN (m³)',
                        controller: _cbnController,
                        icon: Icons.calculate,
                        keyboardType: TextInputType.number,
                      ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Quantité',
                    controller: _itemQuantityController,
                    icon: Icons.inventory_2,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Pays de départ',
                    controller: TextEditingController(text: _startCountry),
                    icon: Icons.flag,
                    onChanged: (value) => _startCountry = value,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Pays de destination',
                    controller: TextEditingController(
                      text: _destinationCountry,
                    ),
                    icon: Icons.flag,
                    onChanged: (value) => _destinationCountry = value,
                  ),
                  const SizedBox(height: 16),
                  _buildDatePicker(
                    label: 'Date de départ',
                    date: _startDate,
                    onTap: () => _selectDate(context, true),
                  ),
                  const SizedBox(height: 16),
                  _buildDatePicker(
                    label: 'Date d\'arrivée estimée',
                    date: _arrivalDate,
                    onTap: () => _selectDate(context, false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveExpedition,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Enregistrer les modifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _expeditionType,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items: const [
            DropdownMenuItem(value: 'avion', child: Text('Avion')),
            DropdownMenuItem(value: 'bateau', child: Text('Bateau')),
          ],
          onChanged: (String? value) {
            if (value != null) {
              setState(() {
                _expeditionType = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: Colors.grey[600])),
            const Spacer(),
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
