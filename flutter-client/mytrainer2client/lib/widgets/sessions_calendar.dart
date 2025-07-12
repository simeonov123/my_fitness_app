import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/training_sessions_provider.dart';
import 'package:provider/provider.dart';

/// Month view with numeric badges (sessions-per-day).
///
/// * [selected] – the currently-selected day (highlighted).
/// * [onSelect] – callback when a specific day is tapped.
/// * [onPageChanged] – **new** – called when user swipes / taps arrows to a
///   different month.  Needed so the parent can load counts for that month.
class SessionsCalendar extends StatelessWidget {
  const SessionsCalendar({
    super.key,
    required this.selected,
    required this.onSelect,
    this.onPageChanged,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<DateTime>? onPageChanged;

  @override
  Widget build(BuildContext context) {
    final counts = context.watch<TrainingSessionsProvider>().counts;

    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: selected,
      selectedDayPredicate: (d) => isSameDay(d, selected),
      onDaySelected: (d, _) => onSelect(d),

      // 🔹 propagate month-change so HomePage can refresh counts
      onPageChanged: onPageChanged,

      calendarBuilders: CalendarBuilders(
        markerBuilder: (_, date, __) {
          final cnt = counts[DateUtils.dateOnly(date)] ?? 0;
          if (cnt == 0) return const SizedBox.shrink();
          return Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$cnt',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
