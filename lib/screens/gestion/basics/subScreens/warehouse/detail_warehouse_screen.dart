import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/models/package.dart';
import 'package:flutter/material.dart';

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

  List<Packages> _allPackages = [];
  List<Packages> _filteredPackages = [];

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
          _allPackages
              .where(
                (pkg) =>
                    pkg.reference!.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  void onAddPackagePressed() {
    // Tu peux ici ouvrir une modal ou naviguer vers une page d'ajout
    print("Ajouter un colis à l'entrepôt ${widget.warehouseId}");
  }

  @override
  Widget build(BuildContext context) {
    final bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

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
                      children: [
                        Icon(
                          Icons.warehouse,
                          size: 20,
                          color: const Color(0xFF7F78AF),
                        ),
                        Text(
                          widget.name!,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 5,
                      children: [
                        Icon(
                          Icons.map_rounded,
                          size: 20,
                          color: const Color(0xFF7F78AF),
                        ),
                        Text(
                          widget.adresse!,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 5,
                      children: [
                        Icon(
                          Icons.type_specimen_rounded,
                          size: 20,
                          color: const Color(0xFF7F78AF),
                        ),
                        Text(
                          widget.storageType!,
                          style: TextStyle(fontWeight: FontWeight.w600),
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
            Text("La liste des colis"),
            const SizedBox(height: 10),
            Expanded(
              child:
                  _filteredPackages.isEmpty
                      ? Center(child: Text("Aucun colis trouvé."))
                      : ListView.builder(
                        itemCount: _filteredPackages.length,
                        itemBuilder: (context, index) {
                          final pkg = _filteredPackages[index];
                          return ListTile(
                            leading: Icon(Icons.inventory),
                            title: Text(pkg.reference!),
                            subtitle: Text("Dimensions: ${pkg.dimensions}"),
                            trailing: Text(
                              "Poids: ${pkg.weight!} kg",
                              style: TextStyle(
                                color: const Color(0xFF7F78AF),
                                fontWeight: FontWeight.w600,
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
