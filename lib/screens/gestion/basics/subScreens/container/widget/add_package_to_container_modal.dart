import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/models/embarquement.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/core/services/package_services.dart';

Future<List<Packages>?> showAddPackagesToContainerDialog(
  BuildContext context,
  int containerId,
  PackageServices packageServices,
) async {
  return showDialog<List<Packages>>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: _AddPackagesDialogContent(
            containerId: containerId,
            packageServices: packageServices,
          ),
        ),
      );
    },
  );
}

class _AddPackagesDialogContent extends StatefulWidget {
  final int containerId;
  final PackageServices packageServices;

  const _AddPackagesDialogContent({
    required this.containerId,
    required this.packageServices,
  });

  @override
  __AddPackagesDialogContentState createState() =>
      __AddPackagesDialogContentState();
}

class __AddPackagesDialogContentState extends State<_AddPackagesDialogContent> {
  late Future<List<Packages>> _availablePackages;
  final List<Packages> _selectedPackages = [];
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _availablePackages = widget.packageServices.findAllPackageReceived();
  }

  void _togglePackageSelection(Packages package) {
    setState(() {
      if (_selectedPackages.contains(package)) {
        _selectedPackages.remove(package);
      } else {
        _selectedPackages.add(package);
      }
    });
  }

  Future<void> _addPackagesToContainer() async {
    if (_selectedPackages.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.getUserInfo();
      final request = EmbarquementRequest(
        containerId: widget.containerId.toInt(),
        packageId: _selectedPackages.map((p) => p.id!).toList(),
      );
      final result =
          await widget.packageServices.embarquerColis(request, user!.id);

      if (result == "SUCCESS") {
        showSuccessTopSnackBar(context, "Colis embarqués avec succès");

        Navigator.of(context).pop(_selectedPackages);
      } else {
        String errorMessage;
        switch (result) {
          case "PACKAGE_ALREADY_IN_ANOTHER_CONTAINER":
            errorMessage =
                "Un ou plusieurs colis sont déjà dans un autre conteneur";
            break;
          case "CONTAINER_NOT_AVAILABLE":
            errorMessage = "Le conteneur n'est pas disponible";
            break;
          case "CONTAINER_NOT_IN_PENDING":
            errorMessage =
                "Le conteneur n'est pas dans le bon statut pour l'embarquement";
            break;
          case "NETWORK_ERROR":
            errorMessage = "Problème de connexion internet";
            break;
          default:
            errorMessage = "Erreur lors de l'embarquement: $result";
        }
        showErrorTopSnackBar(context, errorMessage);
      }
    } catch (e) {
      showErrorTopSnackBar(context, "Erreur: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Ajouter des colis',
                  style: TextStyle(
                    fontSize: 20,
                    letterSpacing: -1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<Packages>>(
            future: _availablePackages,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Erreur de chargement'));
              }

              if (snapshot.data!.isEmpty) {
                return const Center(child: Text('Aucun colis disponible'));
              }

              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final package = snapshot.data![index];
                  final isSelected = _selectedPackages.contains(package);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) => _togglePackageSelection(package),
                    title: Text(package.ref ?? ''),
                    subtitle: Text('${package.itemQuantity ?? 0} cartons'),
                    secondary: Icon(
                      Icons.inventory_2,
                      color: Colors.green[400],
                    ),
                    checkColor: Colors.white,
                    activeColor: Colors.green,
                  );
                },
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading || _selectedPackages.isEmpty
                    ? null
                    : _addPackagesToContainer,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.grey.shade300;
                    }
                    return _selectedPackages.isNotEmpty
                        ? Colors.green
                        : Colors.grey;
                  }),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  enableFeedback: true,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Ajouter (${_selectedPackages.length})',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
