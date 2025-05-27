import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:country_picker/country_picker.dart';

class PackageProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final PackageServices _packageServices = PackageServices();
  final PartnerServices _partnerServices = PartnerServices();
  final ContainerServices _containerServices = ContainerServices();

  List<Partner> _clients = [];
  List<Containers> _container = [];
  bool _isLoading = false;
  Partner? _selectedClient;
  Containers? _selectedContainer;
  int _currentStep = 0;

  String _expeditionType = 'Bateau';
  Country? _departureCountry;
  Country? _arrivalCountry;
  DateTime? _startDate;
  DateTime? _estimatedArrivalDate;

  // Getters
  List<Partner> get clients => _clients;
  List<Containers> get container => _container;
  bool get isLoading => _isLoading;
  Partner? get selectedClient => _selectedClient;
  Containers? get selectedContainer => _selectedContainer;
  int get currentStep => _currentStep;
  String get expeditionType => _expeditionType;
  Country? get departureCountry => _departureCountry;
  Country? get arrivalCountry => _arrivalCountry;
  DateTime? get startDate => _startDate;
  DateTime? get estimatedArrivalDate => _estimatedArrivalDate;

  // Setters
  set selectedClient(Partner? value) {
    _selectedClient = value;
    notifyListeners();
  }

  set selectedContainer(Containers? value) {
    _selectedContainer = value;
    notifyListeners();
  }

  set currentStep(int value) {
    _currentStep = value;
    notifyListeners();
  }

  set expeditionType(String value) {
    _expeditionType = value;
    notifyListeners();
  }

  set departureCountry(Country? value) {
    _departureCountry = value;
    notifyListeners();
  }

  set arrivalCountry(Country? value) {
    _arrivalCountry = value;
    notifyListeners();
  }

  set startDate(DateTime? value) {
    _startDate = value;
    notifyListeners();
  }

  set estimatedArrivalDate(DateTime? value) {
    _estimatedArrivalDate = value;
    notifyListeners();
  }

  Future<void> loadClients() async {
    if (_clients.isNotEmpty || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final data = await _partnerServices.findCustomers(page: 0);
      _clients = data;
    } catch (e) {
      // L'erreur sera gérée par le widget qui utilise le provider
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadContainers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final containers = await _containerServices.findAll(page: 0);
      _container = containers;
    } catch (e) {
      // L'erreur sera gérée par le widget qui utilise le provider
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPackage({
    required String ref,
    required double? weight,
    required double? cbn,
    required double quantity,
    required int warehouseId,
    required int containerId,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context, "Utilisateur non connecté");
        return false;
      }

      if (_selectedClient == null) {
        showErrorTopSnackBar(context, "Client non sélectionné");
        return false;
      }

      if (_departureCountry == null || _arrivalCountry == null) {
        showErrorTopSnackBar(context, "Pays non sélectionnés");
        return false;
      }

      if (_startDate == null || _estimatedArrivalDate == null) {
        showErrorTopSnackBar(context, "Dates non sélectionnées");
        return false;
      }

      final dto = Packages.fromJson({
        "ref": ref.trim(),
        "weight": weight,
        "itemQuantity": quantity,
        "cbn": cbn,
        "startDate": _startDate?.toUtc().toIso8601String(),
        "arrivalDate": _estimatedArrivalDate?.toUtc().toIso8601String(),
        "expeditionType": _expeditionType,
        "startCountry": _departureCountry!.name,
        "destinationCountry": _arrivalCountry!.name,
      });

      final result = await _packageServices.create(
        dto: dto,
        clientId: _selectedClient!.id,
        userId: user.id,
        warehouseId: warehouseId,
        containerId: containerId,
      );

      if (result == "SUCCESS") {
        showSuccessTopSnackBar(context, "Colis créé avec succès !");
        return true;
      } else {
        showErrorTopSnackBar(context, "Une erreur inattendue s'est produite");
        return false;
      }
    } catch (e) {
      showErrorTopSnackBar(context, "Erreur: ${e.toString()}");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _clients = [];
    _isLoading = false;
    _selectedClient = null;
    _currentStep = 0;
    _expeditionType = 'Bateau';
    _departureCountry = null;
    _arrivalCountry = null;
    _startDate = null;
    _estimatedArrivalDate = null;
    notifyListeners();
  }
}
