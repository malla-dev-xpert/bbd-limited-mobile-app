import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

Future<List<Items>?> showAddItemsToContainerDialog(
  BuildContext context,
  int containerId,
  ContainerServices containerServices,
  ItemServices itemServices,
) async {
  return showDialog<List<Items>>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: _AddItemsDialogContent(
              containerId: containerId,
              containerServices: containerServices,
              itemServices: itemServices,
            ),
          ),
        ),
      );
    },
  );
}

class _AddItemsDialogContent extends StatefulWidget {
  final int containerId;
  final ContainerServices containerServices;
  final ItemServices itemServices;

  const _AddItemsDialogContent({
    required this.containerId,
    required this.containerServices,
    required this.itemServices,
  });

  @override
  State<_AddItemsDialogContent> createState() => _AddItemsDialogContentState();
}

class _AddItemsDialogContentState extends State<_AddItemsDialogContent> {
  late Future<List<Items>> _availableItems;
  final List<Items> _selectedItems = [];
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadAvailableItems();
  }

  Future<void> _loadAvailableItems() async {
    setState(() {
      _availableItems =
          widget.itemServices.findAllNotInContainer().then((list) {
        return list.toList();
      });
    });
  }

  void _toggleItemSelection(Items item) {
    setState(() {
      if (_selectedItems.any((i) => i.id == item.id)) {
        _selectedItems.removeWhere((i) => i.id == item.id);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  Future<void> _addItemsToContainer() async {
    if (_selectedItems.isEmpty) return;
    final itemIds = _selectedItems.map((i) => i.id!).whereType<int>().toList();
    if (itemIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(
            context,
            AppLocalizations.of(context)?.translate('user_not_connected') ??
                'Utilisateur non connecté');
        setState(() => _isLoading = false);
        return;
      }

      final result = await widget.containerServices.addItemsToContainer(
        widget.containerId,
        itemIds,
        userId: user.id.toInt(),
      );

      if (result == "SUCCESS") {
        showSuccessTopSnackBar(
            context,
            AppLocalizations.of(context)
                    ?.translate('container_items_embarked_success') ??
                'Items embarqués avec succès');
        if (mounted) Navigator.of(context).pop(_selectedItems);
      } else {
        String errorMessage;
        switch (result) {
          case "CONTAINER_NOT_AVAILABLE":
            errorMessage = AppLocalizations.of(context)
                    ?.translate('container_not_available') ??
                'Le conteneur n\'est pas disponible';
            break;
          case "ITEM_ALREADY_IN_CONTAINER":
            errorMessage = AppLocalizations.of(context)
                    ?.translate('container_item_already_in_container') ??
                'Un ou plusieurs items sont déjà dans un conteneur';
            break;
          case "CONTAINER_NOT_FOUND":
            errorMessage = AppLocalizations.of(context)
                    ?.translate('container_not_found') ??
                'Conteneur non trouvé';
            break;
          case "CONFLICT_ERROR":
            errorMessage = AppLocalizations.of(context)
                    ?.translate('container_embark_error') ??
                'Erreur lors de l\'embarquement';
            break;
          default:
            errorMessage =
                '${AppLocalizations.of(context)?.translate('container_embark_error') ?? 'Erreur'}: $result';
        }
        showErrorTopSnackBar(context, errorMessage);
      }
    } catch (e) {
      showErrorTopSnackBar(context,
          '${AppLocalizations.of(context)?.translate('error') ?? 'Erreur'}: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  loc?.translate('container_embark_items') ??
                      'Embarquer des items',
                  style: const TextStyle(
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
          child: FutureBuilder<List<Items>>(
            future: _availableItems,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text(
                        loc?.translate('error') ?? 'Erreur de chargement'));
              }
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return Center(
                    child: Text(
                        loc?.translate('container_no_items_available') ??
                            'Aucun item disponible'));
              }
              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  final isSelected = _selectedItems.any((i) => i.id == item.id);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) => _toggleItemSelection(item),
                    title: Text(item.description ?? 'N/A'),
                    subtitle: Text(
                        '${item.quantity ?? 0} unités${item.carton != null ? ', ${item.carton} cartons' : ''}'),
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
                child: Text(loc?.translate('cancel') ?? 'Annuler'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading || _selectedItems.isEmpty
                    ? null
                    : _addItemsToContainer,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.grey.shade300;
                      }
                      return _selectedItems.isNotEmpty
                          ? Colors.green
                          : Colors.grey;
                    },
                  ),
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
                              '${loc?.translate('add') ?? 'Ajouter'} (${_selectedItems.length})',
                              style: const TextStyle(fontSize: 16),
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
