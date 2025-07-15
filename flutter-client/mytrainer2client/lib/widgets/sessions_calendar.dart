import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';

import '../providers/training_sessions_provider.dart';

/// Collapsible calendar that shrinks to a single‑row “nav bar” when not in use.
///
/// * When collapsed it acts like a tiny week navigator pinned at the top.
/// * Tap anywhere on the calendar to toggle between collapsed ⇄ expanded.
/// * After a day is chosen in the expanded view, it auto‑collapses.
/// * Public API (selected, onSelect, onPageChanged) is **unchanged** so
///   `HomePage` and the rest of the app keep working as before.
class SessionsCalendar extends StatefulWidget {
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
  State<SessionsCalendar> createState() => _SessionsCalendarState();
}

class _SessionsCalendarState extends State<SessionsCalendar>
    with SingleTickerProviderStateMixin {
  // start in collapsed “nav bar” mode
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final counts = context.watch<TrainingSessionsProvider>().counts;

    // Build one TableCalendar; its appearance is driven by _expanded.
    final calendar = TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: widget.selected,
      selectedDayPredicate: (d) => isSameDay(d, widget.selected),
      onDaySelected: (d, _) {
        widget.onSelect(d);

        // Auto‑collapse after the user has picked a day from the full view.
        if (_expanded) {
          setState(() => _expanded = false);
        }
      },
      onPageChanged: widget.onPageChanged,

      // Collapse to a single row (week view) when not expanded.
      calendarFormat: _expanded ? CalendarFormat.month : CalendarFormat.week,

      // Hide the header in collapsed mode to save vertical space.
      headerVisible: _expanded,

      // A slightly tighter row when collapsed.
      rowHeight: _expanded ? 48 : 40,

      calendarBuilders: CalendarBuilders(
        markerBuilder: (_, date, __) {
          final cnt = counts[DateUtils.dateOnly(date)] ?? 0;
          if (cnt == 0) return const SizedBox.shrink();
          return Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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

    // Wrap the calendar in an AnimatedSize and a GestureDetector so height
    // changes are animated and the whole widget is tappable.
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: calendar,
      ),
    );
  }
}
