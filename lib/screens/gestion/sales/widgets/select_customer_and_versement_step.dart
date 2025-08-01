import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';

class SelectCustomerAndVersementStep extends StatefulWidget {
  final void Function(Partner, Versement?) onNext;
  final VoidCallback onCancel;
  const SelectCustomerAndVersementStep(
      {Key? key, required this.onNext, required this.onCancel})
      : super(key: key);

  @override
  State<SelectCustomerAndVersementStep> createState() =>
      _SelectCustomerAndVersementStepState();
}

class _SelectCustomerAndVersementStepState
    extends State<SelectCustomerAndVersementStep>
    with SingleTickerProviderStateMixin {
  final PartnerServices _partnerServices = PartnerServices();
  final VersementServices _versementServices = VersementServices();
  final TextEditingController _searchController = TextEditingController();

  List<Partner> _customers = [];
  List<Partner> _filteredCustomers = [];
  Partner? _selectedCustomer;
  List<Versement> _versements = [];
  Versement? _selectedVersement;
  bool _isLoadingCustomers = true;
  bool isLoadingVersements = false;
  bool _isDebtPurchase = false;
  late final AnimationController _fadeController;
  late final Animation<double> fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _loadCustomers();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoadingCustomers = true);
    try {
      final customers = await _partnerServices.findCustomers(page: 0);
      setState(() {
        _customers = customers;
        _filteredCustomers = customers;
        _isLoadingCustomers = false;
      });
      _fadeController.forward();
    } catch (_) {
      setState(() => _isLoadingCustomers = false);
    }
  }

  Future<void> _loadVersements(int customerId) async {
    setState(() {
      isLoadingVersements = true;
      _versements = [];
      _selectedVersement = null;
      _isDebtPurchase = false;
    });
    try {
      final versements = await _versementServices.getByClient(customerId);
      setState(() {
        _versements = versements;
        isLoadingVersements = false;
        // Si pas de versements, proposer automatiquement l'achat en dette
        if (versements.isEmpty) {
          _isDebtPurchase = true;
        }
      });
      _fadeController.forward(from: 0);
    } catch (_) {
      setState(() => isLoadingVersements = false);
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((customer) {
          final fullName =
              '${customer.firstName} ${customer.lastName}'.toLowerCase();
          final phone = customer.phoneNumber.toLowerCase();
          final email = customer.email.toLowerCase();
          final searchLower = query.toLowerCase();
          return fullName.contains(searchLower) ||
              phone.contains(searchLower) ||
              email.contains(searchLower);
        }).toList();
      }
    });
    _fadeController.forward(from: 0);
  }

  bool get _canProceed {
    if (_selectedCustomer == null) return false;
    if (_versements.isEmpty) return _isDebtPurchase;
    return _selectedVersement != null || _isDebtPurchase;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Header
        Container(
          padding:
              const EdgeInsets.only(top: 18, left: 0, right: 0, bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Nouvel Achat',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sélectionnez un client et un versement pour commencer',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterCustomers,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un client...',
                    prefixIcon:
                        Icon(Icons.search, color: Colors.grey[400], size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                  ),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: _isLoadingCustomers
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: _filteredCustomers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          final isSelected =
                              _selectedCustomer?.id == customer.id;
                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.primaryColor.withOpacity(0.10)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: theme.primaryColor
                                              .withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      theme.primaryColor.withOpacity(0.13),
                                  child: Text(
                                    customer.firstName.isNotEmpty
                                        ? customer.firstName[0].toUpperCase()
                                        : '',
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '${customer.firstName} ${customer.lastName}',
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? theme.primaryColor
                                        : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(customer.phoneNumber,
                                    style: const TextStyle(fontSize: 13)),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle,
                                        color: theme.primaryColor, size: 22)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedCustomer = customer;
                                  });
                                  _loadVersements(customer.id);
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            children: [
              if (_selectedCustomer != null) ...[
                // Section des versements
                if (_versements.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: isLoadingVersements
                        ? const Center(child: CircularProgressIndicator())
                        : DropDownCustom<Versement>(
                            items: _versements,
                            selectedItem: _selectedVersement,
                            onChanged: (versement) {
                              setState(() {
                                _selectedVersement = versement;
                                _isDebtPurchase = false;
                              });
                            },
                            itemToString: (v) =>
                                '${v.reference ?? ''} -  ${v.montantVerser?.toStringAsFixed(0) ?? ''}',
                            hintText: 'Choisir un versement',
                            prefixIcon: Icons.account_balance_wallet,
                          ),
                  ),
                  const SizedBox(height: 12),
                  // Option pour achat en dette
                  Container(
                    decoration: BoxDecoration(
                      color: _isDebtPurchase
                          ? const Color(0xFF7F78AF).withOpacity(0.1)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isDebtPurchase
                            ? const Color(0xFF7F78AF)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Row(
                        children: [
                          Icon(
                            Icons.credit_card,
                            color: _isDebtPurchase
                                ? const Color(0xFF7F78AF)
                                : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Achat en dette',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _isDebtPurchase
                                  ? const Color(0xFF7F78AF)
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Créer un achat sans versement (sera enregistré comme dette)',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isDebtPurchase
                              ? const Color(0xFF7F78AF)
                              : Colors.grey[600],
                        ),
                      ),
                      value: _isDebtPurchase,
                      onChanged: (value) {
                        setState(() {
                          _isDebtPurchase = value ?? false;
                          if (_isDebtPurchase) {
                            _selectedVersement = null;
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                  ),
                ] else if (!isLoadingVersements) ...[
                  // Message quand pas de versements
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7F78AF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF7F78AF).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: const Color(0xFF7F78AF),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aucun versement disponible',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7F78AF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ce client n\'a pas de versement. L\'achat sera créé en dette.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      const Color(0xFF7F78AF).withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: confirmationButton(
                        isLoading: false,
                        onPressed: _canProceed
                            ? () => widget.onNext(_selectedCustomer!,
                                _isDebtPurchase ? null : _selectedVersement)
                            : () {},
                        label: 'Suivant',
                        icon: Icons.arrow_forward,
                        subLabel: 'Chargement...'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
