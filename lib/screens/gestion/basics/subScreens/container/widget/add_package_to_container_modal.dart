// add_packages_dialog.dart
import 'dart:developer';

import 'package:bbd_limited/models/embarquement.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/package.dart';
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
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
      final request = EmbarquementRequest(
        containerId: widget.containerId.toInt(),
        packageId: _selectedPackages.map((p) => p.id).toList(),
      );
      final result = await widget.packageServices.embarquerColis(request);

      if (result == "SUCCESS") {
        showSuccessTopSnackBar(context, "Colis embarqués avec succès");

        Navigator.of(context).pop(_selectedPackages);
      } else if (result == "NETWORK_ERROR") {
        showErrorTopSnackBar(context, "Erreur de connexion");
      } else if (result == "TIMEOUT_ERROR") {
        showErrorTopSnackBar(context, "Temps d'execution trop long");
      } else {
        showErrorTopSnackBar(context, "Erreur lors de l'embarquement");
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
              Text(
                'Ajouter des colis',
                style: TextStyle(
                  fontSize: 20,
                  letterSpacing: -1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<Packages>>(
            future: _availablePackages,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Erreur de chargement'));
              }

              if (snapshot.data!.isEmpty) {
                return Center(child: Text('Aucun colis disponible'));
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
                    title: Text(package.reference ?? ''),
                    subtitle: Text('${package.items?.length ?? 0} articles'),
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
        Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Annuler'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    _isLoading || _selectedPackages.isEmpty
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
                    EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  enableFeedback: true,
                ),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 200),
                  child:
                      _isLoading
                          ? SizedBox(
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
                              Icon(Icons.add, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Ajouter (${_selectedPackages.length})',
                                style: TextStyle(fontSize: 14),
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
