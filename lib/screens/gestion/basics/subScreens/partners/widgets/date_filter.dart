import 'package:flutter/material.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class DateFilterWidget extends StatelessWidget {
  final bool showDateFilter;
  final TextEditingController dateDebutController;
  final TextEditingController dateFinController;
  final VoidCallback onDateDebutSelected;
  final VoidCallback onDateFinSelected;
  final VoidCallback onClearDateFilter;

  const DateFilterWidget({
    Key? key,
    required this.showDateFilter,
    required this.dateDebutController,
    required this.dateFinController,
    required this.onDateDebutSelected,
    required this.onDateFinSelected,
    required this.onClearDateFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isTablet =
        MediaQuery.of(context).size.width > 600; // Seuil pour tablette

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: showDateFilter ? (isTablet ? 180 : 260) : 0,
      padding: showDateFilter ? const EdgeInsets.all(16) : EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      curve: Curves.easeInOut,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: showDateFilter
            ? SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  key: const ValueKey('date-filter-visible'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate('filter_by_date_title'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1E49),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red[600]),
                          onPressed: onClearDateFilter,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Affichage adaptatif
                    if (isTablet)
                      Row(
                        children: [
                          Expanded(
                            child: _DatePickerField(
                              controller: dateDebutController,
                              label: AppLocalizations.of(context)
                                  .translate('start_date'),
                              onTap: onDateDebutSelected,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DatePickerField(
                              controller: dateFinController,
                              label: AppLocalizations.of(context)
                                  .translate('end_date'),
                              onTap: onDateFinSelected,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _DatePickerField(
                            controller: dateDebutController,
                            label: AppLocalizations.of(context)
                                .translate('start_date'),
                            onTap: onDateDebutSelected,
                          ),
                          const SizedBox(height: 12),
                          _DatePickerField(
                            controller: dateFinController,
                            label: AppLocalizations.of(context)
                                .translate('end_date'),
                            onTap: onDateFinSelected,
                          ),
                        ],
                      ),
                  ],
                ),
              )
            : const SizedBox.shrink(key: ValueKey('date-filter-hidden')),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback onTap;

  const _DatePickerField({
    Key? key,
    required this.controller,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              Icons.calendar_month,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            onPressed: onTap,
            splashRadius: 20,
          ),
        ),
      ),
    );
  }
}
