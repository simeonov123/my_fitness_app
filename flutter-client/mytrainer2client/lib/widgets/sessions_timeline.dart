import 'package:flutter/material.dart';

import '../models/session.dart';
import '../providers/session_store.dart';
import '../theme/app_density.dart';
import 'session_card.dart';
import 'session_group_card.dart';

class SessionsTimeline extends StatelessWidget {
  const SessionsTimeline({
    super.key,
    required this.day,
    this.onLongPressTime,
  });
  final DateTime day;
  final ValueChanged<DateTime>? onLongPressTime;

  /* layout constants */
  static const double _pxPerMin = 1.2;
  static const double _timeW = 52;
  static const double _gap = 3;
  static const double _minColW = 50;
  static const int _maxCols = 4; // 3 cards + pill
  static const int _startHour = 5;
  static const int _visibleHours = 24;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // SessionStore is still the single source of truth for the day slice.
    return ValueListenableBuilder<List<Session>>(
      valueListenable: SessionStore().listenable,
      builder: (_, list, __) {
        final dayEvents = list
            .where((e) => DateUtils.isSameDay(e.start, day))
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));

        final clusters = _clusters(dayEvents);
        const fullHeight = (_visibleHours * 60 * _pxPerMin);

        return ClipRRect(
          borderRadius: AppDensity.circular(20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
            ),
            child: Padding(
              padding: EdgeInsets.only(right: AppDensity.space(6)),
              child: SizedBox(
                height: fullHeight,
                child: Stack(
                  children: [
                    Row(
                      children: [
                        _timeColumn(context),
                        Expanded(
                          child: _TimelinePressSurface(
                            day: day,
                            pxPerMin: _pxPerMin,
                            onLongPressTime: onLongPressTime,
                            child: _paint(context, clusters),
                          ),
                        ),
                      ],
                    ),
                    if (DateUtils.isSameDay(day, DateTime.now()))
                      _nowLine(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /* time ruler & grid */

  Widget _timeColumn(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: List.generate(_visibleHours, (index) {
        final h = (_startHour + index) % 24;
        return SizedBox(
          height: 60 * _pxPerMin,
          width: _timeW,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(
                top: AppDensity.space(2),
                left: AppDensity.space(6),
              ),
              child: Text(
                '${h.toString().padLeft(2, '0')}:00',
                style: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _grid(BuildContext context) => Column(
        children: List.generate(_visibleHours, (_) {
          return Container(
            height: 60 * _pxPerMin,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withOpacity(0.45),
                ),
              ),
            ),
          );
        }),
      );

  /* real-overlap clusters */

  List<List<Session>> _clusters(List<Session> src) {
    final out = <List<Session>>[];
    for (final s in src) {
      if (out.isEmpty) {
        out.add([s]);
        continue;
      }
      final latestEnd =
          out.last.map((e) => e.end).reduce((a, b) => a.isAfter(b) ? a : b);
      if (s.start.isBefore(latestEnd)) {
        out.last.add(s);
      } else {
        out.add([s]);
      }
    }
    return out;
  }

  /* greedy column assignment */

  Map<Session, int> _columns(List<Session> cluster) {
    final freeAt = <DateTime>[];
    final map = <Session, int>{};

    for (final ev in cluster) {
      bool placed = false;
      for (var c = 0; c < freeAt.length; c++) {
        if (!ev.start.isBefore(freeAt[c])) {
          map[ev] = c;
          freeAt[c] = ev.end;
          placed = true;
          break;
        }
      }
      if (!placed) {
        map[ev] = freeAt.length;
        freeAt.add(ev.end);
      }
    }
    return map;
  }

  /* painter */

  Widget _paint(BuildContext context, List<List<Session>> clusters) {
    return LayoutBuilder(builder: (_, constr) {
      final fullW = constr.maxWidth;
      final children = <Widget>[_grid(context)];

      for (final cluster in clusters) {
        cluster.sort((a, b) => a.start.compareTo(b.start));

        final colMap = _columns(cluster);
        final colUsed = colMap.values.fold(0, (m, v) => v >= m ? v + 1 : m);

        final pillNeeded = colUsed > _maxCols;
        final totalCols = pillNeeded ? _maxCols : colUsed;
        final visibleCols = pillNeeded ? _maxCols - 1 : colUsed;

        final colW =
            ((fullW - (totalCols - 1) * _gap) / totalCols).floorToDouble();
        final compact = colW < _minColW;

        int shown = 0;
        final hidden = <Session>[];

        /* visible cards */
        for (final ev in cluster) {
          if (shown >= visibleCols) {
            hidden.add(ev);
            continue;
          }
          final left = compact ? 0.0 : shown * (colW + _gap);
          final width = compact ? fullW : colW;

          children.add(_card(ev,
              palette: shown, left: left, width: width, compact: compact));
          shown++;
        }

        /* pill */
        if (hidden.isNotEmpty) {
          final start = hidden
              .map((e) => e.start)
              .reduce((a, b) => a.isBefore(b) ? a : b);
          final end =
              hidden.map((e) => e.end).reduce((a, b) => a.isAfter(b) ? a : b);

          final spanH =
              (end.difference(start).inMinutes * _pxPerMin).toDouble();
          final pillH = spanH < SessionGroupCard.rowHeight
              ? SessionGroupCard.rowHeight
              : spanH;

          final left = compact ? 0.0 : visibleCols * (colW + _gap);

          children.add(Positioned(
            top: _y(start),
            left: left,
            width: compact ? fullW : colW,
            height: pillH,
            child: SessionGroupCard(
              hidden: hidden,
              paletteIndex: shown,
              height: pillH,
            ),
          ));
        }
      }
      return Stack(children: children);
    });
  }

  /* helpers */

  Positioned _card(Session s,
      {required int palette,
      required double left,
      required double width,
      required bool compact}) {
    final y = _y(s.start);
    final h = (s.durationMinutes * _pxPerMin).toDouble();
    return Positioned(
      top: y,
      left: left,
      width: width,
      height: h,
      child: SessionCard(
        session: s,
        paletteIndex: palette,
        compact: compact,
      ),
    );
  }

  double _y(DateTime d) {
    var hour = d.hour;
    if (hour < _startHour) hour += 24;
    final minutesFromStart = ((hour - _startHour) * 60) + d.minute;
    return (minutesFromStart * _pxPerMin).toDouble();
  }

  Widget _nowLine(BuildContext context) {
    final now = DateTime.now();
    final y = _y(now);
    final label = TimeOfDay.fromDateTime(now).format(context);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Positioned(
      top: y,
      left: 0,
      right: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 2,
            color: colors.error,
          ),
          Positioned(
            left: 8,
            top: -12,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDensity.space(7),
                    vertical: AppDensity.space(3),
                  ),
                  decoration: BoxDecoration(
                    color: colors.error,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withOpacity(0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: text.labelSmall?.copyWith(
                      color: colors.onError,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: AppDensity.space(6)),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors.error,
                    shape: BoxShape.circle,
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

class _TimelinePressSurface extends StatelessWidget {
  const _TimelinePressSurface({
    required this.day,
    required this.pxPerMin,
    required this.child,
    this.onLongPressTime,
  });

  final DateTime day;
  final double pxPerMin;
  final Widget child;
  final ValueChanged<DateTime>? onLongPressTime;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: onLongPressTime == null
          ? null
          : (details) =>
              onLongPressTime!(_timeFromOffset(details.localPosition.dy)),
      child: child,
    );
  }

  DateTime _timeFromOffset(double dy) {
    const visibleMinutes = SessionsTimeline._visibleHours * 60;
    final totalMinutes = (dy / pxPerMin).round().clamp(0, visibleMinutes - 60);
    final roundedMinutes =
        ((totalMinutes / 15).round() * 15).clamp(0, visibleMinutes - 60);
    return DateTime(day.year, day.month, day.day).add(Duration(
      hours: SessionsTimeline._startHour,
      minutes: roundedMinutes,
    ));
  }
}
