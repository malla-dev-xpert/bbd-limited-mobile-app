import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/models/package.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WarehouseDetailPage extends StatefulWidget {
  final int warehouseId;
  final String? name;
  final String? adresse;
  final String? storageType;

  const WarehouseDetailPage({
    super.key,
    required this.warehouseId,
    this.name,
    this.adresse,
    this.storageType,
  });

  @override
  State<WarehouseDetailPage> createState() => _WarehouseDetailPageState();
}

class _WarehouseDetailPageState extends State<WarehouseDetailPage> {
  final TextEditingController searchController = TextEditingController();
  final PackageServices _packageServices = PackageServices();
  final AuthService _authService = AuthService();

  List<Packages> _allPackages = [];
  List<Packages> _filteredPackages = [];
  String? _currentFilter;

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  void fetchPackages() async {
    try {
      final packages = await _packageServices.findByWarehouse(
        widget.warehouseId.toInt(),
      );

      setState(() {
        _allPackages = packages;
        _filteredPackages = packages;
      });
    } catch (e) {
      print("Erreur de récupération des colis : $e");
    }
  }

  void filterPackages(String query) {
    setState(() {
      _filteredPackages =
          _allPackages.where((pkg) {
            final searchPackage = pkg.reference!.toLowerCase().contains(
              query.toLowerCase(),
            );

            bool allStatus = true;
            if (_currentFilter == 'receptionnes') {
              allStatus = pkg.status == Status.CREATE;
            } else if (_currentFilter == 'en_attente') {
              allStatus = pkg.status == Status.PENDING;
            }

            return searchPackage && allStatus;
          }).toList();
    });
  }

  Color getStatusColor(Status? status) {
    switch (status) {
      case Status.PENDING:
        return Colors.orange;
      case Status.RECEIVED:
        return Colors.green;
      case Status.DELIVERED:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void handleStatusFilter(String value) {
    setState(() {
      _currentFilter = value;
    });

    filterPackages(searchController.text);
  }

  void onAddPackagePressed() {
    // Tu peux ici ouvrir une modal ou naviguer vers une page d'ajout
    print("Ajouter un colis à l'entrepôt ${widget.warehouseId}");
  }

  @override
  Widget build(BuildContext context) {
    // final bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Détail : ${widget.name}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte d'info entrepôt
            Text("Informations de l'entrepot", textAlign: TextAlign.left),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: const Color(0xFFF3F4F6),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  spacing: 10,
                  children: [
                    Row(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warehouse,
                          size: 20,
                          color: const Color(0xFF7F78AF),
                        ),
                        Expanded(
                          child: Text(
                            widget.name!,
                            style: TextStyle(fontWeight: FontWeight.w600),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.map_rounded,
                          size: 20,
                          color: const Color(0xFF7F78AF),
                        ),
                        Expanded(
                          child: Text(
                            widget.adresse!,
                            style: TextStyle(fontWeight: FontWeight.w600),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.type_specimen_rounded,
                          size: 20,
                          color: const Color(0xFF7F78AF),
                        ),
                        Expanded(
                          child: Text(
                            widget.storageType!,
                            style: TextStyle(fontWeight: FontWeight.w600),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Barre de recherche
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
                      labelText: 'Rechercher un colis...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                FiltreDropdown(onSelected: handleStatusFilter),

                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1E49),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.add, color: Colors.white, size: 24),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 50,
                      minHeight: 50,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Liste des colis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "La liste des colis${_currentFilter == null
                      ? ''
                      : _currentFilter == 'receptionnes'
                      ? ' réceptionnés'
                      : ' en attente'}",

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentFilter != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentFilter = null;
                        _filteredPackages = _allPackages;
                        if (searchController.text.isNotEmpty) {
                          filterPackages(searchController.text);
                        }
                      });
                    },
                    child: const Text("Voir tout"),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  _filteredPackages.isEmpty
                      ? Center(child: Text("Aucun colis trouvé."))
                      : ListView.builder(
                        itemCount: _filteredPackages.length,
                        itemBuilder: (context, index) {
                          final pkg = _filteredPackages[index];
                          return Dismissible(
                            key: Key(pkg.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              padding: const EdgeInsets.only(right: 16),
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              child: Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              try {
                                final user = await _authService.getUserInfo();
                                if (user == null) {
                                  showErrorTopSnackBar(
                                    context,
                                    "Erreur: Utilisateur non connecté",
                                  );
                                  return;
                                }

                                await _packageServices.deletePackage(
                                  pkg.id,
                                  user.id.toInt(),
                                );

                                setState(() {
                                  _allPackages.removeWhere(
                                    (d) => d.id == pkg.id,
                                  );
                                  _filteredPackages = List.from(_allPackages);
                                });

                                showSuccessTopSnackBar(
                                  context,
                                  "Colis supprimé avec succès",
                                );
                              } catch (e) {
                                showErrorTopSnackBar(
                                  context,
                                  "Erreur lors de la suppression",
                                );
                              }
                            },
                            child: ListTile(
                              onTap:
                                  () => _showPackageDetailsBottomSheet(
                                    context,
                                    pkg,
                                  ),
                              leading: Icon(
                                Icons.inventory,
                                color: getStatusColor(pkg.status),
                              ),
                              title: Text(pkg.reference!),
                              subtitle: Text("Dimensions: ${pkg.dimensions}"),
                              trailing: Text(
                                "Poids: ${pkg.weight!} kg",
                                style: TextStyle(
                                  color: const Color(0xFF7F78AF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class FiltreDropdown extends StatelessWidget {
  final Function(String) onSelected;

  const FiltreDropdown({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF7F78AF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: PopupMenuButton<String>(
        icon: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, color: Colors.white),
            SizedBox(width: 8),
            Text('Filtrer', style: TextStyle(color: Colors.white)),
            SizedBox(width: 8),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onSelected: onSelected,
        itemBuilder:
            (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'receptionnes',
                child: Text('Colis réceptionnés'),
              ),
              const PopupMenuItem<String>(
                value: 'en_attente',
                child: Text('Colis en attente'),
              ),
            ],
      ),
    );
  }
}

Widget _detailRow(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$label :", style: TextStyle(fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            value ?? '',
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

void _showPackageDetailsBottomSheet(BuildContext context, Packages pkg) {
  final PackageServices packageServices = PackageServices();
  final AuthService authService = AuthService();

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder:
        (context) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Wrap(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Détails du colis",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.grey[800],
                    ),
                    child: IconButton(
                      onPressed: () => {Navigator.of(context).pop()},
                      icon: Icon(Icons.clear, color: Colors.white, size: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              _detailRow("Référence", pkg.reference),
              _detailRow("Dimensions", pkg.dimensions),
              _detailRow("Poids", "${pkg.weight} kg"),
              _detailRow(
                "Date de reception",
                DateFormat.yMMMMEEEEd().format(pkg.createdAt!),
              ),
              _detailRow("Client", pkg.partnerName ?? "Non trouver"),
              _detailRow("Téléphone", pkg.partnerPhoneNumber ?? "Non trouver"),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(),
                  Text(
                    "La liste des articles",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),

                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child:
                        pkg.items == null || pkg.items!.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Pas d’articles pour ce colis."),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed:
                                        () =>
                                            _showAddItemsModal(context, pkg.id),
                                    icon: Icon(Icons.add, color: Colors.white),
                                    label: Text(
                                      "Ajouter un article",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7F78AF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              shrinkWrap: true,
                              itemCount: pkg.items!.length,
                              itemBuilder: (context, index) {
                                final item = pkg.items![index];
                                return ListTile(
                                  leading: Icon(Icons.label),
                                  title: Text(item.description),
                                  trailing: Text("x${item.quantity}"),
                                );
                              },
                            ),
                  ),
                ],
              ),

              const SizedBox(height: 60),
              pkg.items != null && pkg.items!.isNotEmpty
                  ? ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.check, color: Colors.white),
                    label: Text(
                      "Confirmer la réception",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      final user = await authService.getUserInfo();

                      try {
                        await packageServices.receivePackage(
                          pkg.id,
                          user?.id.toInt(),
                          pkg.warehouseId,
                        );
                        Navigator.of(context).pop();
                        showSuccessTopSnackBar(
                          context,
                          "Réception confirmée !",
                        );
                      } catch (e) {
                        showErrorTopSnackBar(
                          context,
                          "Erreur lors de la réception",
                        );
                      }
                      // Navigator.of(context).pop();
                      // showSuccessTopSnackBar(context, "Réception confirmée !");
                    },
                  )
                  : Text(""),
              const SizedBox(height: 70),
            ],
          ),
        ),
  );
}

void _showAddItemsModal(BuildContext context, int packageId) {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final List<Map<String, dynamic>> localItems = [];

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Ajouter des articles au colis",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),

                  // Description input
                  TextFormField(
                    controller: descriptionController,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Description du colis',
                      prefixIcon: const Icon(
                        Icons.description,
                        color: Colors.black,
                      ), // Change icon color to black
                      fillColor: Colors.white, // Set background color to white
                      filled: true, // Enable filled background
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer la description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Quantity input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: quantityController,
                          autocorrect: false,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Quantité de colis',
                            prefixIcon: const Icon(
                              Icons.numbers,
                              color: Colors.black,
                            ), // Change icon color to black
                            fillColor:
                                Colors.white, // Set background color to white
                            filled: true, // Enable filled background
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer la quantité';
                            }
                            return null;
                          },
                        ),
                      ),

                      // Ajouter button
                      ElevatedButton.icon(
                        onPressed: () {
                          final description = descriptionController.text.trim();
                          final quantity = double.tryParse(
                            quantityController.text.trim(),
                          );

                          if (description.isNotEmpty && quantity != null) {
                            setState(() {
                              localItems.add({
                                'description': description,
                                'quantity': quantity,
                              });
                              descriptionController.clear();
                              quantityController.clear();
                            });
                          }
                        },
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text(
                          "Ajouter",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7F78AF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  const SizedBox(height: 10),

                  // Liste des articles ajoutés
                  if (localItems.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: localItems.length,
                        itemBuilder: (context, index) {
                          final item = localItems[index];
                          return ListTile(
                            title: Text(item['description']),
                            subtitle: Text("Quantité : ${item['quantity']}"),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  localItems.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "Aucun article ajouté.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Annuler",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      if (localItems.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () async {
                            // TODO: Appel API pour enregistrer les articles
                            Navigator.pop(context);
                            showSuccessTopSnackBar(
                              context,
                              "Articles ajoutés avec succès !",
                            );
                          },
                          icon: Icon(Icons.check_circle, color: Colors.white),
                          label: Text(
                            "Confirmer",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
