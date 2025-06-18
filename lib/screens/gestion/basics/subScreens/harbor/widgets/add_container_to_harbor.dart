import 'package:bbd_limited/core/services/auth_services.dart';
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _availableContainers =
        widget.containerServices.findAllContainerNotInHarbor();
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
      final user = await _authService.getUserInfo();
      final request = HarborEmbarquementRequest(
        harborId: widget.harborId.toInt(),
        containerId: _selectedContainers.map((p) => p.id!).toList(),
      );
      final result = await widget.containerServices
          .embarquerContainerToHarbor(request, user!.id);

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
              const Text(
                'Ajouter des conteneurs',
                style: TextStyle(
                  fontSize: 20,
                  letterSpacing: -1,
                  fontWeight: FontWeight.bold,
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
          child: FutureBuilder<List<Containers>>(
            future: _availableContainers,
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
                onPressed: _isLoading || _selectedContainers.isEmpty
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
                              'Ajouter (${_selectedContainers.length})',
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
