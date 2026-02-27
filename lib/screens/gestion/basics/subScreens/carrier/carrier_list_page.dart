import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/carrier_services.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/models/carrier.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/carrier/widgets/create_carrier_bottom_sheet.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/carrier/widgets/carrier_list_item.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

class CarrierListPage extends StatefulWidget {
  const CarrierListPage({Key? key}) : super(key: key);

  @override
  _CarrierListPageState createState() => _CarrierListPageState();
}

class _CarrierListPageState extends State<CarrierListPage> {
  final TextEditingController searchController = TextEditingController();
  final CarrierServices _carrierServices = CarrierServices();
  final AuthService _authService = AuthService();

  List<Carrier> _allCarriers = [];
  List<Carrier> _filteredCarriers = [];
  bool _isLoading = false;
  int _currentPage = 0;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadCarriers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCarriers({bool reset = false}) async {
    if (_isLoading || (!reset && !_hasMoreData)) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        _currentPage = 0;
        _hasMoreData = true;
        _allCarriers.clear();
      }
    });

    try {
      final carriers =
          await _carrierServices.getAllCarriers(page: _currentPage);

      setState(() {
        _allCarriers.addAll(carriers);
        _applyFilter(searchController.text);

        if (carriers.isEmpty || carriers.length < 20) {
          _hasMoreData = false;
        } else {
          _currentPage++;
        }
      });
    } catch (e, stack) {
      log('_loadCarriers error: $e\n$stack');
      if (mounted) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('carrier_loading_error'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCarriers = List.from(_allCarriers);
      } else {
        _filteredCarriers = _allCarriers.where((carrier) {
          final name = carrier.name?.toLowerCase() ?? '';
          final contact = carrier.contact?.toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              contact.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _deleteCarrier(Carrier carrier) async {
    final localizations = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('confirm_deletion')),
        content: Text(localizations.translate('carrier_delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              localizations.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = await _authService.getUserInfo();
        if (user == null) return;

        setState(() => _isLoading = true);
        final result =
            await _carrierServices.deleteCarrier(carrier.id!, user.id);

        if (result == "SUCCESS") {
          showSuccessTopSnackBar(
            context,
            localizations.translate('carrier_delete_success'),
          );
          _loadCarriers(reset: true);
        } else if (result == "CARRIER_LINKED_TO_CONTAINER") {
          showErrorTopSnackBar(
            context,
            localizations.translate('carrier_delete_error_linked'),
          );
        } else {
          showErrorTopSnackBar(
            context,
            localizations.translate('carrier_delete_error_generic'),
          );
        }
      } catch (e) {
        showErrorTopSnackBar(
          context,
          localizations.translate('carrier_delete_error_generic'),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.translate('home_manage_carriers_title'),
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1E49),
        onPressed: () async {
          final result = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (context) => const CreateCarrierBottomSheet(),
          );
          if (result == true) {
            _loadCarriers(reset: true);
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: buildTextField(
              controller: searchController,
              label: localizations.translate('search'),
              icon: Icons.search,
              onChanged: _applyFilter,
            ),
          ),
          Expanded(
            child: _filteredCarriers.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCarriers.isEmpty
                    ? Center(child: Text(localizations.translate('no_results')))
                    : RefreshIndicator(
                        onRefresh: () => _loadCarriers(reset: true),
                        child: ListView.separated(
                          itemCount:
                              _filteredCarriers.length + (_hasMoreData ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            if (index == _filteredCarriers.length) {
                              _loadCarriers();
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            return CarrierListItem(
                              carrier: _filteredCarriers[index],
                              onDelete: _deleteCarrier,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
