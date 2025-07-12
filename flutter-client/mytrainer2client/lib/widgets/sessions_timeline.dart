import 'package:flutter/material.dart';

import '../models/session.dart';
import '../providers/session_store.dart';
import 'session_card.dart';
import 'session_group_card.dart';

class SessionsTimeline extends StatelessWidget {
  const SessionsTimeline({super.key, required this.day});
  final DateTime day;

  /* layout constants */
  static const double _pxPerMin = 1.2;
  static const double _timeW    = 60;
  static const double _gap      = 4;
  static const double _minColW  = 56;
  static const int    _maxCols  = 4; // 3 cards + pill

  @override
  Widget build(BuildContext context) {
    // SessionStore is still the single source of truth for the day slice.
    return ValueListenableBuilder<List<Session>>(
      valueListenable: SessionStore().listenable,
      builder: (_, list, __) {
        final dayEvents = list
            .where((e) => DateUtils.isSameDay(e.start, day))
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));

        final clusters = _clusters(dayEvents);
        final fullHeight = (24 * 60 * _pxPerMin);

        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              height: fullHeight,
              child: Row(
                children: [_timeColumn(), Expanded(child: _paint(clusters))],
              ),
            ),
          ),
        );
      },
    );
  }

  /* time ruler & grid */

  Widget _timeColumn() => Column(
    children: List.generate(24, (h) {
      return SizedBox(
        height: 60 * _pxPerMin,
        width:  _timeW,
        child: Align(
          alignment: Alignment.topCenter,
          child: Text('${h.toString().padLeft(2, '0')}:00',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      );
    }),
  );

  Widget _grid() => Column(
    children: List.generate(24, (_) {
      return Container(
        height: 60 * _pxPerMin,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
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
    final map    = <Session, int>{};

    for (final ev in cluster) {
      bool placed = false;
      for (var c = 0; c < freeAt.length; c++) {
        if (!ev.start.isBefore(freeAt[c])) {
          map[ev]   = c;
          freeAt[c] = ev.end;
          placed    = true;
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

  Widget _paint(List<List<Session>> clusters) {
    return LayoutBuilder(builder: (_, constr) {
      final fullW    = constr.maxWidth;
      final children = <Widget>[_grid(), _nowLine()];

      for (final cluster in clusters) {
        cluster.sort((a, b) => a.start.compareTo(b.start));

        final colMap  = _columns(cluster);
        final colUsed =
        colMap.values.fold(0, (m, v) => v >= m ? v + 1 : m);

        final pillNeeded  = colUsed > _maxCols;
        final totalCols   = pillNeeded ? _maxCols : colUsed;
        final visibleCols = pillNeeded ? _maxCols - 1 : colUsed;

        final colW =
        ((fullW - (totalCols - 1) * _gap) / totalCols).floorToDouble();
        final compact = colW < _minColW;

        int   shown   = 0;
        final hidden  = <Session>[];

        /* visible cards */
        for (final ev in cluster) {
          if (shown >= visibleCols) {
            hidden.add(ev);
            continue;
          }
          final left  = compact ? 0.0 : shown * (colW + _gap);
          final width = compact ? fullW : colW;

          children.add(_card(ev,
              palette: shown,
              left: left,
              width: width,
              compact: compact));
          shown++;
        }

        /* pill */
        if (hidden.isNotEmpty) {
          final start = hidden
              .map((e) => e.start)
              .reduce((a, b) => a.isBefore(b) ? a : b);
          final end = hidden
              .map((e) => e.end)
              .reduce((a, b) => a.isAfter(b) ? a : b);

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

  double _y(DateTime d) => ((d.hour * 60 + d.minute) * _pxPerMin).toDouble();

  Widget _nowLine() {
    if (!DateUtils.isSameDay(day, DateTime.now())) return const SizedBox();
    final y = _y(DateTime.now());
    return Positioned(
      top: y,
      left: 0,
      right: 0,
      child: Row(children: [
        Container(width: _timeW, height: 1),
        Expanded(child: Container(height: 1, color: Colors.red)),
      ]),
    );
  }
}
