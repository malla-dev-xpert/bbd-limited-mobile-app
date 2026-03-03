import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:intl/intl.dart';

/// Bottom sheet pour sélectionner les articles sur lesquels appliquer une option
class ItemSelectionBottomSheet extends StatefulWidget {
  final List<Items> items;
  final Set<int>? initiallySelectedItemIds;
  final String title;
  final String? subtitle;
  final String currencySymbol;

  const ItemSelectionBottomSheet({
    Key? key,
    required this.items,
    this.initiallySelectedItemIds,
    required this.title,
    this.subtitle,
    this.currencySymbol = '¥',
  }) : super(key: key);

  @override
  State<ItemSelectionBottomSheet> createState() =>
      _ItemSelectionBottomSheetState();

  static Future<Set<int>?> show(
    BuildContext context, {
    required List<Items> items,
    Set<int>? initiallySelectedItemIds,
    required String title,
    String? subtitle,
    String currencySymbol = '¥',
  }) async {
    return await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemSelectionBottomSheet(
        items: items,
        initiallySelectedItemIds: initiallySelectedItemIds,
        title: title,
        subtitle: subtitle,
        currencySymbol: currencySymbol,
      ),
    );
  }
}

class _ItemSelectionBottomSheetState extends State<ItemSelectionBottomSheet> {
  late Set<int> _selectedItemIds;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '');

  @override
  void initState() {
    super.initState();
    _selectedItemIds = widget.initiallySelectedItemIds?.toSet() ??
        widget.items
            .where((item) => item.id != null)
            .map((item) => item.id!)
            .toSet();
  }

  void _toggleItem(int itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedItemIds = widget.items
          .where((item) => item.id != null)
          .map((item) => item.id!)
          .toSet();
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedItemIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.9;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1E49),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTextSize.titleStyle(context,
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle!,
                              style: AppTextSize.bodyStyle(context,
                                  color: Colors.white.withOpacity(0.8)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _selectAll,
                      icon: const Icon(Icons.select_all, color: Colors.white),
                      label: Text(
                        localizations.translate('select_all'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _deselectAll,
                      icon: const Icon(Icons.deselect, color: Colors.white),
                      label: Text(
                        localizations.translate('deselect_all'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedItemIds.length} / ${widget.items.where((item) => item.id != null).length} ${localizations.translate('items_selected')}',
                    style: AppTextSize.bodyStyle(context,
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Items list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                if (item.id == null) return const SizedBox.shrink();

                final isSelected = _selectedItemIds.contains(item.id);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF1A1E49)
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _toggleItem(item.id!),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleItem(item.id!),
                            activeColor: const Color(0xFF1A1E49),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.description ??
                                      localizations.translate('unnamed_item'),
                                  style: AppTextSize.subtitleStyle(context,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? const Color(0xFF1A1E49)
                                          : Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${localizations.translate('quantity')}: ${item.quantity ?? 0} | '
                                  '${localizations.translate('unit_price')}: ${_currencyFormat.format(item.unitPrice ?? 0)} ${widget.currencySymbol} | '
                                  '${localizations.translate('total')}: ${_currencyFormat.format(item.totalPrice ?? 0)} ${widget.currencySymbol}',
                                  style: AppTextSize.captionStyle(context,
                                      color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF1A1E49),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF1A1E49)),
                    ),
                    child: Text(
                      localizations.translate('cancel'),
                      style: const TextStyle(
                        color: Color(0xFF1A1E49),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_selectedItemIds),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1E49),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      localizations.translate('validate'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
