import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';

/// Option for single-select filter (e.g. provider).
class FilterOption<T> {
  final T? value;
  final String label;

  const FilterOption({this.value, required this.label});
}

/// Modern modal bottom sheet for selecting one option from a list with search.
/// Uses Design System; no hardcoded spacing or font sizes.
class FilterSheet<T> extends StatelessWidget {
  final String title;
  final String searchHint;
  final String allOptionLabel;
  final String noResultsLabel;
  final List<FilterOption<T>> options;
  final T? selectedValue;
  final ValueChanged<T?> onSelected;
  final bool showAllOption;

  const FilterSheet({
    super.key,
    required this.title,
    required this.searchHint,
    required this.options,
    required this.onSelected,
    this.selectedValue,
    this.showAllOption = true,
    this.allOptionLabel = 'Tous',
    this.noResultsLabel = 'Aucun résultat',
  });

  /// Shows the filter sheet and returns the selected value when applied.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String searchHint,
    required List<FilterOption<T>> options,
    T? initialValue,
    bool showAllOption = true,
    String allOptionLabel = 'Tous',
    String noResultsLabel = 'Aucun résultat',
  }) async {
    T? result = initialValue;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: FilterSheet<T>(
          title: title,
          searchHint: searchHint,
          options: options,
          selectedValue: initialValue,
          showAllOption: showAllOption,
          allOptionLabel: allOptionLabel,
          noResultsLabel: noResultsLabel,
          onSelected: (v) {
            result = v;
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text(
                title,
                style: AppTextSize.titleStyle(context, color: const Color(0xFF1A1E49)),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _FilterSheetBody<T>(
                searchHint: searchHint,
                allOptionLabel: allOptionLabel,
                noResultsLabel: noResultsLabel,
                options: options,
                selectedValue: selectedValue,
                onSelected: onSelected,
                showAllOption: showAllOption,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _FilterSheetBody<T> extends StatefulWidget {
  final String searchHint;
  final String allOptionLabel;
  final String noResultsLabel;
  final List<FilterOption<T>> options;
  final T? selectedValue;
  final ValueChanged<T?> onSelected;
  final bool showAllOption;

  const _FilterSheetBody({
    required this.searchHint,
    required this.allOptionLabel,
    required this.noResultsLabel,
    required this.options,
    required this.onSelected,
    required this.showAllOption,
    this.selectedValue,
  });

  @override
  State<_FilterSheetBody<T>> createState() => _FilterSheetBodyState<T>();
}

class _FilterSheetBodyState<T> extends State<_FilterSheetBody<T>> {
  late TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FilterOption<T>> get _filteredOptions {
    if (_query.isEmpty) return widget.options;
    return widget.options
        .where((o) => o.label.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOptions;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: widget.searchHint,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
          style: AppTextSize.bodyStyle(context),
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView(
            shrinkWrap: true,
            children: [
              if (widget.showAllOption)
                _OptionTile<T>(
                  option: FilterOption<T>(value: null, label: widget.allOptionLabel),
                  isSelected: widget.selectedValue == null,
                  onTap: () => widget.onSelected(null),
                ),
              ...filtered.map(
                (opt) => _OptionTile<T>(
                  option: opt,
                  isSelected: widget.selectedValue == opt.value,
                  onTap: () => widget.onSelected(opt.value),
                ),
              ),
              if (filtered.isEmpty && _query.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Text(
                      widget.noResultsLabel,
                      style: AppTextSize.bodyStyle(context, color: Colors.grey),
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

class _OptionTile<T> extends StatelessWidget {
  final FilterOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A1E49);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.08) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 22,
                color: isSelected ? primaryColor : Colors.grey.shade400,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  option.label,
                  style: AppTextSize.bodyStyle(
                    context,
                    color: isSelected ? primaryColor : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
