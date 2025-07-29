import 'dart:async';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/core/services/exchange_rate_service.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/new_versement.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/edit_paiement_modal.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/paiement_list.dart';
import 'package:bbd_limited/screens/gestion/accounts/versement_detail_screen.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccountHomeScreen extends StatefulWidget {
  @override
  State<AccountHomeScreen> createState() => _AccountHomeScreenState();
}

class _AccountHomeScreenState extends State<AccountHomeScreen> {
  final TextEditingController searchController = TextEditingController();
  final VersementServices _versementServices = VersementServices();
  final AuthService _authService = AuthService();
  final ExchangeRateService _exchangeRateService = ExchangeRateService();

  List<Versement> _allVersements = [];
  List<Versement> _filteredVersements = [];
  final List<VersementType> _types = VersementType.values;
  VersementType? _currentTypeFilter;
  double _totalVersementsUSD = 0.0;

  bool _isLoading = false;
  bool _refreshLoading = false;
  bool _hasMoreData = true;
  int currentPage = 0;

  TextEditingController _montantController = TextEditingController();
  TextEditingController _dateDebutController = TextEditingController();
  TextEditingController _dateFinController = TextEditingController();

  DateTime? _selectedDateDebut;
  DateTime? _selectedDateFin;
  bool _showDateFilter = false;

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'CNY');
  final GlobalKey _filterIconKey = GlobalKey();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _montantController = TextEditingController();
    _dateDebutController = TextEditingController();
    _dateFinController = TextEditingController();
    fetchPaiements();
    _refreshController.stream.listen((_) {
      fetchPaiements(reset: true);
    });
  }

  @override
  void dispose() {
    _montantController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    _refreshController.close();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _calculateTotalVersementsUSD() async {
    if (_allVersements.isEmpty) {
      setState(() {
        _totalVersementsUSD = 0.0;
      });
      return;
    }

    double totalUSD = 0.0;
    for (var versement in _allVersements) {
      if (versement.montantVerser != null && versement.deviseCode != null) {
        if (versement.deviseCode == 'CNY') {
          totalUSD += versement.montantVerser!;
        } else {
          final rate =
              await _exchangeRateService.getExchangeRate(versement.deviseCode!);
          totalUSD += versement.montantVerser! / rate;
        }
      }
    }

    setState(() {
      _totalVersementsUSD = totalUSD;
    });
  }

  Future<void> fetchPaiements({bool reset = false}) async {
    if (_isLoading || (!reset && !_hasMoreData)) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        _refreshLoading = true;
        currentPage = 0;
        _hasMoreData = true;
        _allVersements = [];
      }
    });
    try {
      final paiement = await _versementServices.getAll(page: currentPage);

      setState(() {
        _allVersements.addAll(paiement);
        _filteredVersements = List.from(_allVersements);

        if (paiement.isEmpty || paiement.length < 30) {
          _hasMoreData = false;
        } else {
          currentPage++;
        }
      });
      await _calculateTotalVersementsUSD();
    } catch (e) {
      showErrorTopSnackBar(context, "Erreur de récupération des paiements.");
    } finally {
      setState(() {
        _isLoading = false;
        _refreshLoading = false;
      });
    }
  }

  void filterPackages(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _filteredVersements = _allVersements.where((pmt) {
          // Text filter
          final searchText = query.isEmpty ||
              (pmt.reference?.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              (pmt.partnerName?.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              (pmt.montantVerser?.toString().contains(query) ?? false);

          // Type filter
          bool typeMatch = _currentTypeFilter == null ||
              (pmt.type != null && pmt.type == _currentTypeFilter!.name);

          // Date filter
          bool dateMatch = true;
          if (_selectedDateDebut != null || _selectedDateFin != null) {
            DateTime? datePaiement;

            try {
              datePaiement = pmt.createdAt;
            } catch (e) {
              datePaiement = null;
            }

            if (datePaiement == null) {
              dateMatch = false;
            } else {
              if (_selectedDateDebut != null) {
                dateMatch = dateMatch &&
                    datePaiement.isAfter(
                        _selectedDateDebut!.subtract(const Duration(days: 1)));
              }
              if (_selectedDateFin != null) {
                dateMatch = dateMatch &&
                    datePaiement.isBefore(
                        _selectedDateFin!.add(const Duration(days: 1)));
              }
            }
          }

          return searchText && typeMatch && dateMatch;
        }).toList();
      });
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _selectedDateDebut ?? DateTime.now()
          : _selectedDateFin ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _selectedDateDebut = picked;
          _dateDebutController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _selectedDateFin = picked;
          _dateFinController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
      filterPackages(searchController.text);
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateDebut = null;
      _selectedDateFin = null;
      _dateDebutController.clear();
      _dateFinController.clear();
      _showDateFilter = false;
    });
    filterPackages(searchController.text);
  }

  Future<void> _openNewVersementBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return const NewVersementModal(isVersementScreen: true);
      },
    );

    if (result == true) {
      fetchPaiements(reset: true);
    }
  }

  void _showEditPaiementModal(BuildContext context, Versement versement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return EditPaiementModal(
          versement: versement,
          onPaiementUpdated: () => fetchPaiements(reset: true),
        );
      },
    );
  }

  Future<void> _delete(Versement versement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text(
          "Voulez-vous vraiment supprimer le paiement ${versement.reference}?",
        ),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text(
              "Supprimer",
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = await _authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context, "Erreur: Utilisateur non connecté");
        return;
      }

      if (versement.id == null) {
        showErrorTopSnackBar(context, "Erreur: Le paiement n'existe pas");
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _versementServices.delete(versement.id!, user.id);

      Navigator.of(context).pop();

      if (result == "ACHATS_NOT_DELETED") {
        showErrorTopSnackBar(
          context,
          "Impossible de supprimer le paiement, il y a des achats associés à ce paiement",
        );
      } else if (result == "DELETED") {
        setState(() {
          _allVersements.removeWhere((d) => d.id == versement.id);
          _filteredVersements.removeWhere((d) => d.id == versement.id);
        });
        showSuccessTopSnackBar(context, "Paiement supprimé avec succès");
      } else {
        showErrorTopSnackBar(context, "Erreur inconnue lors de la suppression");
      }
    } catch (e) {
      Navigator.of(context).pop();
      showErrorTopSnackBar(
        context,
        "Erreur lors de la suppression: ${e.toString()}",
      );
    }
  }

  String _typeToLabel(VersementType type) {
    switch (type) {
      case VersementType.General:
        return "Général";
      case VersementType.Dette:
        return "Dette";
      case VersementType.Commande:
        return "Commande";
      case VersementType.CompteBancaire:
        return "Compte Bancaire";
      case VersementType.Autres:
        return "Autres";
    }
  }

  Widget _buildDateFilter() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showDateFilter ? 180 : 0,
      padding: _showDateFilter ? const EdgeInsets.all(16) : EdgeInsets.zero,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      curve: Curves.easeInOut,
      child: OverflowBox(
        maxHeight: 180, // Hauteur maximale
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showDateFilter
              ? SingleChildScrollView(
                  // Ajout du défilement si nécessaire
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    key: const ValueKey('date-filter-visible'),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Filtrer par date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey[600]),
                            onPressed: _clearDateFilter,
                            splashRadius: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: 80,
                          maxHeight: MediaQuery.of(context).size.height * 0.3,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _DatePickerField(
                                context: context,
                                controller: _dateDebutController,
                                label: 'Date début',
                                onTap: () => _selectDate(context, true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DatePickerField(
                                context: context,
                                controller: _dateFinController,
                                label: 'Date fin',
                                onTap: () => _selectDate(context, false),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('date-filter-hidden')),
        ),
      ),
    );
  }

  Widget _buildPaymentList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            !_isLoading &&
            _hasMoreData) {
          fetchPaiements();
        }
        return false;
      },
      child: _filteredVersements.isEmpty
          ? const Center(child: Text("Aucun paiement trouvé."))
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredVersements.length +
                  (_hasMoreData && _isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _filteredVersements.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final paiement = _filteredVersements[index];
                return PaiementListItem(
                    versement: paiement,
                    onEdit: () => _showEditPaiementModal(context, paiement),
                    onDelete: () => _delete(paiement),
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VersementDetailScreen(
                              versement: paiement,
                              onVersementUpdated: () =>
                                  fetchPaiements(reset: true),
                            ),
                          ),
                        ));
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1E49),
        onPressed: () => _openNewVersementBottomSheet(context),
        heroTag: 'accounts_fab',
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 10,
                      children: [
                        const Text(
                          "Gestion des versements",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        IconButton(
                          onPressed: _refreshLoading
                              ? null
                              : () => fetchPaiements(reset: true),
                          tooltip: 'Rafraîchir',
                          icon: _refreshLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey),
                                  ),
                                )
                              : const Icon(Icons.refresh, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Stats cards
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: Colors.blue[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _StatItem(
                                  title: 'Total des versements',
                                  value: _allVersements.length.toString(),
                                  valueStyle: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1E49),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: Colors.amber[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _StatItem(
                                  title: 'Montant total',
                                  value: currencyFormat
                                      .format(_totalVersementsUSD),
                                  valueStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1E49),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search and filter
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: filterPackages,
                                controller: searchController,
                                autocorrect: false,
                                decoration: InputDecoration(
                                  hintText:
                                      'Rechercher par référence ou client...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(32),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        setState(() {
                                          _showDateFilter = !_showDateFilter;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(14.0),
                                        child: Icon(
                                          _showDateFilter
                                              ? Icons.calendar_today
                                              : Icons.date_range,
                                          size: 26,
                                          color: const Color(0xFF1A1E49),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: Colors.transparent,
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: InkWell(
                                      key: _filterIconKey,
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () async {
                                        final RenderBox button = _filterIconKey
                                            .currentContext!
                                            .findRenderObject() as RenderBox;
                                        final RenderBox overlay =
                                            Overlay.of(context)
                                                    .context
                                                    .findRenderObject()
                                                as RenderBox;
                                        final Offset position =
                                            button.localToGlobal(Offset.zero,
                                                ancestor: overlay);
                                        final selected =
                                            await showMenu<VersementType?>(
                                          context: context,
                                          position: RelativeRect.fromLTRB(
                                            position.dx,
                                            position.dy + button.size.height,
                                            position.dx + button.size.width,
                                            overlay.size.height -
                                                (position.dy +
                                                    button.size.height),
                                          ),
                                          color: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          items: [
                                            const PopupMenuItem<VersementType?>(
                                              value: null,
                                              child: Text(
                                                'Tous les types',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ),
                                            ..._types.map(
                                              (type) =>
                                                  PopupMenuItem<VersementType?>(
                                                value: type,
                                                child: Text(
                                                  _typeToLabel(type),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                        if (selected != null ||
                                            selected == null) {
                                          setState(() {
                                            _currentTypeFilter = selected;
                                          });
                                          filterPackages(searchController.text);
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(14.0),
                                        child: Icon(
                                          Icons.filter_list,
                                          size: 26,
                                          color: Color(0xFF1A1E49),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        _buildDateFilter(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // List header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "La liste des versements",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_currentTypeFilter != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _currentTypeFilter = null;
                                _filteredVersements = _allVersements;
                                if (searchController.text.isNotEmpty) {
                                  filterPackages(searchController.text);
                                }
                              });
                            },
                            child: const Text("Voir tout"),
                          ),
                      ],
                    ),
                    // Payment list
                    Flexible(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1A1E49),
                                strokeWidth: 3,
                              ),
                            )
                          : _buildPaymentList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final BuildContext context;
  final TextEditingController controller;
  final String label;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.context,
    required this.controller,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).hintColor,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              Icons.calendar_month,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            onPressed: onTap,
            splashRadius: 20,
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final TextStyle valueStyle;

  const _StatItem({
    required this.title,
    required this.value,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text(value, style: valueStyle),
      ],
    );
  }
}
