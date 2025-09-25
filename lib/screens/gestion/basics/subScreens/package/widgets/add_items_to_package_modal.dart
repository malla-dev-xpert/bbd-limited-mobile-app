import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/widgets/rounded_button.dart';

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
      showErrorTopSnackBar(context,
          AppLocalizations.of(context).translate('add_items_loading_error'));
    }
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
                Text(
                  AppLocalizations.of(context)
                      .translate('add_items_modal_title'),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
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
                    ? Center(
                        child: Text(AppLocalizations.of(context)
                            .translate('add_items_no_items_available')))
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
                              title: Text(item.description ??
                                  AppLocalizations.of(context)
                                      .translate('add_items_no_description')),
                              subtitle: Text(AppLocalizations.of(context)
                                      .translate('add_items_quantity_label') +
                                  ": " +
                                  (item.quantity?.toString() ?? "-")),
                            );
                          }).toList(),
                        ),
                      ),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppLocalizations.of(context).translate('cancel'),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RoundedButton(
                      text: AppLocalizations.of(context)
                          .translate('add_selected_items'),
                      onPressed: _selectedItemIds.isEmpty
                          ? () {}
                          : () {
                              final selectedItems = _items
                                  .where((item) =>
                                      _selectedItemIds.contains(item.id))
                                  .toList();
                              widget.onValidate(selectedItems);
                              Navigator.pop(context);
                            },
                      loading: false,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
