import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:intl/intl.dart';

/// Preset for quick date range selection.
enum DateRangePreset {
  today,
  last7Days,
  thisMonth,
  custom,
}

/// Result of date range selection (optional range + preset used).
class DateRangeResult {
  final DateTime? start;
  final DateTime? end;
  final DateRangePreset preset;

  const DateRangeResult({this.start, this.end, required this.preset});

  bool get hasRange => start != null && end != null;
}

/// Reusable date range selector with shortcuts and optional date picker.
/// Uses Design System; no hardcoded spacing or font sizes.
class DateRangeSelector extends StatefulWidget {
  final DateRangeResult? initialValue;
  final ValueChanged<DateRangeResult> onChanged;
  final VoidCallback? onApply;
  final VoidCallback? onReset;

  const DateRangeSelector({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.onApply,
    this.onReset,
  });

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  late DateRangePreset _preset;
  DateTime? _start;
  DateTime? _end;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _preset = widget.initialValue?.preset ?? DateRangePreset.custom;
    _start = widget.initialValue?.start;
    _end = widget.initialValue?.end;
  }

  void _applyPreset(DateRangePreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? start;
    DateTime? end;

    switch (preset) {
      case DateRangePreset.today:
        start = today;
        end = today.add(const Duration(days: 1));
        break;
      case DateRangePreset.last7Days:
        start = today.subtract(const Duration(days: 6));
        end = today.add(const Duration(days: 1));
        break;
      case DateRangePreset.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1);
        break;
      case DateRangePreset.custom:
        break;
    }

    setState(() {
      _preset = preset;
      _start = start;
      _end = end;
    });
    widget.onChanged(DateRangeResult(start: start, end: end, preset: preset));
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _start = picked;
        _preset = DateRangePreset.custom;
        if (_end != null && _end!.isBefore(picked)) _end = picked.add(const Duration(days: 1));
      });
      widget.onChanged(DateRangeResult(start: _start, end: _end, preset: DateRangePreset.custom));
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end ?? _start ?? DateTime.now(),
      firstDate: _start ?? DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _end = picked;
        _preset = DateRangePreset.custom;
        if (_start != null && _start!.isAfter(picked)) _start = picked.subtract(const Duration(days: 1));
      });
      widget.onChanged(DateRangeResult(start: _start, end: _end, preset: DateRangePreset.custom));
    }
  }

  void _reset() {
    setState(() {
      _preset = DateRangePreset.custom;
      _start = null;
      _end = null;
    });
    widget.onChanged(const DateRangeResult(preset: DateRangePreset.custom));
    widget.onReset?.call();
  }

  String _formatDate(DateTime? d) => d == null ? '—' : _dateFormat.format(d);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return const SizedBox.shrink();
    final isTablet = DeviceBreakpoints.isTablet(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          loc.translate('filter_by_date_title'),
          style: AppTextSize.titleStyle(context, color: const Color(0xFF1A1E49)),
        ),
        SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _PresetChip(
              label: loc.translate('filter_date_today'),
              isSelected: _preset == DateRangePreset.today,
              onTap: () => _applyPreset(DateRangePreset.today),
            ),
            _PresetChip(
              label: _translateLast7Days(loc),
              isSelected: _preset == DateRangePreset.last7Days,
              onTap: () => _applyPreset(DateRangePreset.last7Days),
            ),
            _PresetChip(
              label: loc.translate('this_month'),
              isSelected: _preset == DateRangePreset.thisMonth,
              onTap: () => _applyPreset(DateRangePreset.thisMonth),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        if (isTablet)
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: loc.translate('start_date'),
                  value: _formatDate(_start),
                  onTap: _pickStartDate,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DateField(
                  label: loc.translate('end_date'),
                  value: _formatDate(_end),
                  onTap: _pickEndDate,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _DateField(
                label: loc.translate('start_date'),
                value: _formatDate(_start),
                onTap: _pickStartDate,
              ),
              SizedBox(height: AppSpacing.md),
              _DateField(
                label: loc.translate('end_date'),
                value: _formatDate(_end),
                onTap: _pickEndDate,
              ),
            ],
          ),
        SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _reset,
              child: Text(loc.translate('reset')),
            ),
            SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: () => widget.onApply?.call(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A1E49),
              ),
              child: Text(loc.translate('apply')),
            ),
          ],
        ),
      ],
    );
  }

  String _translateLast7Days(AppLocalizations loc) {
    return loc.translate('filter_last_7_days');
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A1E49);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: AppTextSize.body(context),
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : primaryColor,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: primaryColor,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? primaryColor : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
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
          suffixIcon: Icon(
            Icons.calendar_month,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        child: Text(
          value,
          style: AppTextSize.bodyStyle(context),
        ),
      ),
    );
  }
}
