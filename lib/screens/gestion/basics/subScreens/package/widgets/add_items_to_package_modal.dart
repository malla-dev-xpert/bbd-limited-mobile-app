import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/confirm_btn.dart';

class AddItemsToPackageModal extends StatefulWidget {
  final int clientId;
  final List<int> alreadyInPackageIds;
  final Function(List<Items>) onValidate;

  const AddItemsToPackageModal({
    Key? key,
    required this.clientId,
    required this.onValidate,
    this.alreadyInPackageIds = const [],
  }) : super(key: key);

  @override
  State<AddItemsToPackageModal> createState() => _AddItemsToPackageModalState();
}

class _AddItemsToPackageModalState extends State<AddItemsToPackageModal> {
  List<Items> _items = [];
  Set<int> _selectedItemIds = {};
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await ItemServices().findItemsByClient(widget.clientId);
      setState(() {
        _items = items
            .where((item) => !widget.alreadyInPackageIds.contains(item.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      showErrorTopSnackBar(
          context, "Erreur lors du chargement des articles reçus");
    }
  }

  void _handleValidate() {
    setState(() => _isSubmitting = true);
    final selectedItems =
        _items.where((item) => _selectedItemIds.contains(item.id)).toList();
    widget.onValidate(selectedItems);
    setState(() => _isSubmitting = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Articles reçus",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(
                        child: Text("Aucun article reçu disponible."))
                    : Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: _items.map((item) {
                            return CheckboxListTile(
                              value: _selectedItemIds.contains(item.id),
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedItemIds.add(item.id!);
                                  } else {
                                    _selectedItemIds.remove(item.id);
                                  }
                                });
                              },
                              title:
                                  Text(item.description ?? "Sans description"),
                              subtitle: Text("Quantité: " +
                                  (item.quantity?.toString() ?? "-")),
                            );
                          }).toList(),
                        ),
                      ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 200,
                child: confirmationButton(
                  isLoading: _isSubmitting,
                  onPressed: (_selectedItemIds.isEmpty || _isSubmitting)
                      ? () {}
                      : _handleValidate,
                  label: "Ajouter au colis",
                  subLabel: "Ajout...",
                  icon: Icons.add,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
