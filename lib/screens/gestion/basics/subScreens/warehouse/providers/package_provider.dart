import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/harbor_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/models/harbor.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';

class PackageProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final PackageServices _packageServices = PackageServices();
  final PartnerServices _partnerServices = PartnerServices();
  final ContainerServices _containerServices = ContainerServices();
  final HarborServices _harborServices = HarborServices();
  final ItemServices _itemServices = ItemServices();

  List<Partner> _clients = [];
  List<Containers> _container = [];
  List<Harbor> _harbors = [];
  bool _isLoading = false;
  Partner? _selectedClient;
  Containers? _selectedContainer;
  Harbor? _selectedDepartureHarbor;
  Harbor? _selectedArrivalHarbor;
  int _currentStep = 0;

  String _expeditionType = 'Bateau';
  DateTime? _startDate;
  DateTime? _estimatedArrivalDate;

  // Items
  Set<int> _selectedItemIds = {};
  List<Items> _eligibleItems = [];
  bool _isLoadingItems = false;

  // Getters
  List<Partner> get clients => _clients;
  List<Containers> get container => _container;
  List<Harbor> get harbors => _harbors;
  bool get isLoading => _isLoading;
  Partner? get selectedClient => _selectedClient;
  Containers? get selectedContainer => _selectedContainer;
  Harbor? get selectedDepartureHarbor => _selectedDepartureHarbor;
  Harbor? get selectedArrivalHarbor => _selectedArrivalHarbor;
  int get currentStep => _currentStep;
  String get expeditionType => _expeditionType;
  DateTime? get startDate => _startDate;
  DateTime? get estimatedArrivalDate => _estimatedArrivalDate;
  Set<int> get selectedItemIds => _selectedItemIds;
  List<Items> get eligibleItems => _eligibleItems;
  bool get isLoadingItems => _isLoadingItems;

  // Setters
  set selectedClient(Partner? value) {
    _selectedClient = value;
    if (value != null) {
      loadEligibleItems(value.id);
    } else {
      _eligibleItems = [];
      _selectedItemIds.clear();
      notifyListeners();
    }
  }

  set selectedContainer(Containers? value) {
    _selectedContainer = value;
    notifyListeners();
  }

  set selectedDepartureHarbor(Harbor? value) {
    _selectedDepartureHarbor = value;
    notifyListeners();
  }

  set selectedArrivalHarbor(Harbor? value) {
    _selectedArrivalHarbor = value;
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

  set startDate(DateTime? value) {
    _startDate = value;
    notifyListeners();
  }

  set estimatedArrivalDate(DateTime? value) {
    _estimatedArrivalDate = value;
    notifyListeners();
  }

  set selectedItemIds(Set<int> value) {
    _selectedItemIds = value;
    notifyListeners();
  }

  void addSelectedItemId(int itemId) {
    _selectedItemIds.add(itemId);
    notifyListeners();
  }

  void removeSelectedItemId(int itemId) {
    _selectedItemIds.remove(itemId);
    notifyListeners();
  }

  void clearSelectedItemIds() {
    _selectedItemIds.clear();
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

  Future<void> loadHarbors() async {
    _isLoading = true;
    notifyListeners();

    try {
      final harbors = await _harborServices.findAll(page: 0);
      _harbors = harbors;
    } catch (e) {
      // L'erreur sera gérée par le widget qui utilise le provider
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadEligibleItems(int clientId) async {
    _isLoadingItems = true;
    notifyListeners();

    try {
      final items = await _itemServices.findItemsByClient(clientId);
      _eligibleItems = items;
      _selectedItemIds.clear();
    } catch (e) {
      _eligibleItems = [];
      _selectedItemIds.clear();
      // L'erreur sera gérée par le widget qui utilise le provider
      rethrow;
    } finally {
      _isLoadingItems = false;
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

      if (_selectedDepartureHarbor == null || _selectedArrivalHarbor == null) {
        showErrorTopSnackBar(context, "Ports non sélectionnés");
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
        "startCountry": _selectedDepartureHarbor!.name,
        "destinationCountry": _selectedArrivalHarbor!.name,
        "startHarborId": _selectedDepartureHarbor!.id,
        "destinationHarborId": _selectedArrivalHarbor!.id,
        "containerId": containerId,
        "warehouseId": warehouseId,
        "itemIds": _selectedItemIds.toList(),
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
      } else if (result != null && result.startsWith("ERROR:")) {
        showErrorTopSnackBar(context, "Erreur serveur: ${result.substring(6)}");
        return false;
      } else if (result == "NETWORK_ERROR") {
        showErrorTopSnackBar(context, "Erreur de connexion réseau");
        return false;
      } else {
        showErrorTopSnackBar(
            context, "Une erreur inattendue s'est produite: $result");
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
    _selectedDepartureHarbor = null;
    _selectedArrivalHarbor = null;
    _startDate = null;
    _estimatedArrivalDate = null;
    _selectedItemIds.clear();
    _eligibleItems = [];
    _isLoadingItems = false;
    notifyListeners();
  }
}
