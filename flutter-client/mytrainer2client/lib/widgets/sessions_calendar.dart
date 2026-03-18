import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/training_sessions_provider.dart';
import '../theme/app_density.dart';

class SessionsCalendar extends StatelessWidget {
  const SessionsCalendar({
    super.key,
    required this.focused,
    required this.selected,
    required this.onSelect,
    this.onPageChanged,
    this.onLongPressDay,
  });

  final DateTime focused;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<DateTime>? onPageChanged;
  final ValueChanged<DateTime>? onLongPressDay;

  @override
  Widget build(BuildContext context) {
    final counts = context.watch<TrainingSessionsProvider>().counts;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final rowHeight = compact ? AppDensity.space(44) : AppDensity.space(50);
        final weekdayFontSize = compact ? 12.5 : 13.5;
        final dayFontSize = compact ? 16.0 : 17.0;
        final markerFontSize = compact ? 9.0 : 10.0;

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppDensity.circular(24),
            border: Border.all(
              color: colors.outlineVariant.withOpacity(0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(0.08),
                blurRadius: AppDensity.space(20),
                offset: Offset(0, AppDensity.space(8)),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focused,
            selectedDayPredicate: (day) => isSameDay(day, selected),
            onDaySelected: (day, _) => onSelect(day),
            onDayLongPressed: (day, _) => onLongPressDay?.call(day),
            onPageChanged: onPageChanged,
            headerVisible: false,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            availableGestures: AvailableGestures.horizontalSwipe,
            calendarFormat: CalendarFormat.month,
            sixWeekMonthsEnforced: true,
            daysOfWeekHeight:
                compact ? AppDensity.space(24) : AppDensity.space(28),
            rowHeight: rowHeight,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: true,
              isTodayHighlighted: true,
              canMarkersOverflow: false,
              defaultTextStyle: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                    fontSize: dayFontSize,
                  ) ??
                  const TextStyle(),
              weekendTextStyle: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                    fontSize: dayFontSize,
                  ) ??
                  const TextStyle(),
              outsideTextStyle: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.outline,
                    fontSize: dayFontSize,
                  ) ??
                  const TextStyle(),
              selectedTextStyle: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onPrimary,
                    fontSize: dayFontSize,
                  ) ??
                  const TextStyle(),
              todayTextStyle: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                    fontSize: dayFontSize,
                  ) ??
                  const TextStyle(),
              selectedDecoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: colors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              markersAnchor: 1.16,
              markerMargin: EdgeInsets.symmetric(
                horizontal: AppDensity.space(1.2),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant,
                    fontSize: weekdayFontSize,
                  ) ??
                  const TextStyle(),
              weekendStyle: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant,
                    fontSize: weekdayFontSize,
                  ) ??
                  const TextStyle(),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (_, date, __) {
                final count = counts[DateUtils.dateOnly(date)] ?? 0;
                if (count == 0) return const SizedBox.shrink();

                final selectedDay = isSameDay(date, selected);
                final today = isSameDay(date, DateTime.now());
                return Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: AppDensity.space(3),
                      right: AppDensity.space(5),
                    ),
                    child: Container(
                      width: AppDensity.space(17),
                      height: AppDensity.space(17),
                      decoration: BoxDecoration(
                        color: selectedDay
                            ? colors.onPrimary
                            : today
                                ? colors.primary
                                : colors.primary.withOpacity(0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow.withOpacity(0.12),
                            blurRadius: AppDensity.space(5),
                            offset: Offset(0, AppDensity.space(2)),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$count',
                        style: text.labelSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: selectedDay
                                  ? colors.primary
                                  : colors.onPrimary,
                              fontSize: markerFontSize,
                            ) ??
                            const TextStyle(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
