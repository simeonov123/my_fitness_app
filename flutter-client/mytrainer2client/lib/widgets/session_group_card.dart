import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/session.dart';
import '../providers/session_store.dart';
import '../screens/training_session_detail_page.dart';

/// Overflow (“group”) card shown on the timeline.
///
/// • No vertical stripe — only accent border/background.
/// • Shows as many *mini* rows as fit between `start` and `end` span.
/// • If rows are hidden, the last visible row becomes “+N”.
/// • Tapping a mini-row   → *opens TrainingSessionDetailPage*.
/// • Tapping empty pill / “+N” → shows scrollable list bottom-sheet; every
///   row there also navigates to the details page.
class SessionGroupCard extends StatelessWidget {
  const SessionGroupCard({
    super.key,
    required this.hidden,
    required this.paletteIndex,
    required this.height,
  });

  final List<Session> hidden;
  final int           paletteIndex;
  final double        height;

  /* ─ styling constants ─ */

  static const double _r       = 8;   // pill radius
  static const double _rowH    = 26;  // mini row height
  static const double _rowGap  = 4;

  /// one visual row incl. gap — timeline uses this
  static double get rowHeight => _rowH + _rowGap;

  Color get _accent {
    const colors = [
      Color(0xff1976d2),
      Color(0xffd32f2f),
      Color(0xff388e3c),
      Color(0xfff57c00),
      Color(0xff7b1fa2),
    ];
    return colors[paletteIndex % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final bg = _accent.withOpacity(.18);

    /* how many rows fit vertically inside pill? */
    final int rowsThatFit =
    ((height + _rowGap) / (_rowH + _rowGap)).floor().clamp(1, hidden.length);

    final bool  overflow        = hidden.length > rowsThatFit;
    final int   rowsForSessions = overflow ? rowsThatFit - 1 : rowsThatFit;
    final List<Session> visibleSessions =
    hidden.take(rowsForSessions).toList(growable: false);
    final int remaining = hidden.length - rowsForSessions;

    return ClipRRect(
      borderRadius: BorderRadius.circular(_r),
      child: InkWell(
        onTap: () => _showListDialog(context), // tap empty pill
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: _accent.withOpacity(.6)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < visibleSessions.length; i++) ...[
                _miniRow(context, visibleSessions[i]),
                if (i != visibleSessions.length - 1)
                  const SizedBox(height: _rowGap),
              ],
              if (overflow) ...[
                if (visibleSessions.isNotEmpty) const SizedBox(height: _rowGap),
                _placeholderRow(context, remaining),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /* ─ mini-row for a single hidden session ─ */
  Widget _miniRow(BuildContext ctx, Session s) {
    return InkWell(
      onTap: () => _openDetails(ctx, s.id),
      child: Container(
        height: _rowH,
        decoration: BoxDecoration(
          color: _accent.withOpacity(.18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _accent.withOpacity(.6)),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          s.clients.join(', '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontSize: 13),
        ),
      ),
    );
  }

  /* ─ placeholder “… / +N” row ─ */
  Widget _placeholderRow(BuildContext ctx, int extra) {
    final label = extra <= 0 ? '…' : '+$extra';
    return InkWell(
      onTap: () => _showListDialog(ctx),
      child: Container(
        height: _rowH,
        decoration: BoxDecoration(
          color: _accent.withOpacity(.18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _accent.withOpacity(.6)),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: Theme.of(ctx).textTheme.titleMedium),
      ),
    );
  }

  /* ─ dialogs ─ */

  void _showListDialog(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).dialogBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView.separated(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            itemCount: hidden.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _dialogTile(ctx, hidden[i]),
          ),
        ),
      ),
    );
  }

  Widget _dialogTile(BuildContext ctx, Session s) {
    final fmt = DateFormat.Hm();
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);          // close bottom-sheet
        _openDetails(ctx, s.id);     // then open details
      },
      child: Container(
        height: _rowH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _accent.withOpacity(.6)),
        ),
        child: Row(
          children: [
            Container(width: 4, color: _accent),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                s.clients.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${fmt.format(s.start)} – ${fmt.format(s.end)}',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  /* ─ navigation helper ─ */

  void _openDetails(BuildContext ctx, int sessionId) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => TrainingSessionDetailPage(sessionId: sessionId),
      ),
    );
  }
}
