import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/models/embarquement.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

Future<List<Containers>?> showAddContainerToHarborDialog(
  BuildContext context,
  int harborID,
  ContainerServices containerServices,
) async {
  return showDialog<List<Containers>>(
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
          child: _AddContainerToHarborDialogContent(
            harborId: harborID,
            containerServices: containerServices,
          ),
        ),
      );
    },
  );
}

class _AddContainerToHarborDialogContent extends StatefulWidget {
  final int harborId;
  final ContainerServices containerServices;

  const _AddContainerToHarborDialogContent({
    required this.harborId,
    required this.containerServices,
  });

  @override
  _AddContainerToHarborDialogContentState createState() =>
      _AddContainerToHarborDialogContentState();
}

class _AddContainerToHarborDialogContentState
    extends State<_AddContainerToHarborDialogContent> {
  late Future<List<Containers>> _availableContainers;
  final List<Containers> _selectedContainers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _availableContainers = widget.containerServices.findAll();
  }

  void _toggleContainerSelection(Containers container) {
    setState(() {
      if (_selectedContainers.contains(container)) {
        _selectedContainers.remove(container);
      } else {
        _selectedContainers.add(container);
      }
    });
  }

  Future<void> _addContainerToHarbor() async {
    if (_selectedContainers.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final request = HarborEmbarquementRequest(
        harborId: widget.harborId.toInt(),
        containerId: _selectedContainers.map((p) => p.id!).toList(),
      );
      final result = await widget.containerServices.embarquerContainerToHarbor(
        request,
      );

      if (result == "SUCCESS") {
        showSuccessTopSnackBar(context, "Conteneurs embarqués avec succès");

        Navigator.of(context).pop(_selectedContainers);
      } else {
        String errorMessage;
        switch (result) {
          case "CONTAINER_ALREADY_IN_ANOTHER_HARBOR":
            errorMessage =
                "Un ou plusieurs conteneur sont déjà dans un autre port";
            break;
          case "HARBOR_NOT_AVAILABLE":
            errorMessage = "Le port n'est pas disponible";
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
              Text(
                'Ajouter des conteneurs',
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
          child: FutureBuilder<List<Containers>>(
            future: _availableContainers,
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
                  final container = snapshot.data![index];
                  final isSelected = _selectedContainers.contains(container);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) => _toggleContainerSelection(container),
                    title: Text(container.reference ?? ''),
                    subtitle: Text('${container.packages?.length ?? 0} colis'),
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
                    _isLoading || _selectedContainers.isEmpty
                        ? null
                        : _addContainerToHarbor,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.grey.shade300;
                    }
                    return _selectedContainers.isNotEmpty
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
                                'Ajouter (${_selectedContainers.length})',
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
