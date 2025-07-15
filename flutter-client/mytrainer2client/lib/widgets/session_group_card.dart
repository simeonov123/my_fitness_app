import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/session.dart';
import '../screens/training_session_detail_page.dart';

/// Overflow (“group”) card shown on the timeline.
///
/// • No vertical stripe — only accent border/background.
/// • Shows as many *mini* rows as fit in its vertical span; last visible row
///   becomes “+N” when there are more.
/// • Tapping a mini‑row opens the details page; tapping the pill background or
///   “+N” shows a bottom‑sheet list that is sized **exactly** to its content
///   (up to 90 % of the screen, then scrolls).
class SessionGroupCard extends StatelessWidget {
  const SessionGroupCard({
    super.key,
    required this.hidden,
    required this.paletteIndex,
    required this.height,
  });

  final List<Session> hidden;
  final int paletteIndex;
  final double height;

  /* ─ styling constants ─ */

  static const double _r = 10; // pill radius
  static const double _rowH = 28; // mini‑row height
  static const double _rowGap = 6; // gap between mini‑rows

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
    final bg = _accent.withOpacity(.16);

    /* how many rows fit vertically inside pill? */
    final int rowsThatFit = ((height + _rowGap) / (_rowH + _rowGap))
        .floor()
        .clamp(1, hidden.length);

    final bool overflow = hidden.length > rowsThatFit;
    final int rowsForSessions = overflow ? rowsThatFit - 1 : rowsThatFit;
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

  /* ─ mini‑row for a single hidden session ─ */
  Widget _miniRow(BuildContext ctx, Session s) {
    return InkWell(
      onTap: () => _openDetails(ctx, s.id),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: _rowH,
        decoration: BoxDecoration(
          color: _accent.withOpacity(.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _accent.withOpacity(.6)),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 6),
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
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: _rowH,
        decoration: BoxDecoration(
          color: _accent.withOpacity(.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _accent.withOpacity(.6)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: Theme.of(ctx).textTheme.titleMedium),
      ),
    );
  }

  /* ─ dialogs ─ */

  void _showListDialog(BuildContext ctx) {
    // Calculate the height needed for the list (rows + gaps + padding).
    const double vPad = 24 * 2; // top + bottom padding inside sheet
    const double sepGap = 10; // separator gap between tiles
    final int rows = hidden.length;
    final double listHeight =
        rows * _rowH + (rows - 1) * sepGap + vPad; // total desired height
    final double maxH = MediaQuery.of(ctx).size.height * 0.9;
    final bool needsScroll = listHeight > maxH;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: needsScroll ? maxH : listHeight,
        decoration: BoxDecoration(
          color: Theme.of(ctx).dialogBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView.separated(
          physics: needsScroll ? null : const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          itemCount: hidden.length,
          separatorBuilder: (_, __) => const SizedBox(height: sepGap),
          itemBuilder: (_, i) => _dialogTile(ctx, hidden[i]),
        ),
      ),
    );
  }

  Widget _dialogTile(BuildContext ctx, Session s) {
    final fmt = DateFormat.Hm();
    return InkWell(
      onTap: () {
        Navigator.pop(ctx); // close bottom‑sheet
        _openDetails(ctx, s.id); // then open details
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: _rowH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _accent.withOpacity(.6)),
        ),
        child: Row(
          children: [
            Container(width: 4, color: _accent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                s.clients.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${fmt.format(s.start)} – ${fmt.format(s.end)}',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
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
