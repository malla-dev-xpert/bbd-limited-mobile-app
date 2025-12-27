import 'package:bbd_limited/core/localization/app_localizations.dart';

enum DateFilterOption {
  today,
  yesterday,
  thisWeek,
  customDate,
  all, // Aucun filtre
}

extension DateFilterOptionExtension on DateFilterOption {
  String getDisplayName(AppLocalizations localizations) {
    switch (this) {
      case DateFilterOption.today:
        return localizations.translate('filter_date_today');
      case DateFilterOption.yesterday:
        return localizations.translate('filter_date_yesterday');
      case DateFilterOption.thisWeek:
        return localizations.translate('filter_date_this_week');
      case DateFilterOption.customDate:
        return localizations.translate('filter_date_custom');
      case DateFilterOption.all:
        return localizations.translate('filter_date_all');
    }
  }

  /// Retourne la plage de dates correspondante
  DateRange? getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (this) {
      case DateFilterOption.today:
        return DateRange(start: today, end: today.add(const Duration(days: 1)));
      case DateFilterOption.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateRange(start: yesterday, end: today);
      case DateFilterOption.thisWeek:
        // Semaine du lundi au dimanche
        final weekday = now.weekday;
        final monday = today.subtract(Duration(days: weekday - 1));
        final nextMonday = monday.add(const Duration(days: 7));
        return DateRange(start: monday, end: nextMonday);
      case DateFilterOption.customDate:
      case DateFilterOption.all:
        return null;
    }
  }
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}

