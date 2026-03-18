import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/session.dart';
import '../screens/training_session_detail_page.dart';
import '../theme/app_density.dart';

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

  static final double _r = AppDensity.radius(10);
  static final double _rowH = AppDensity.space(24);
  static final double _rowGap = AppDensity.space(5);
  static final double _padV = AppDensity.space(4);
  static final double _padH = AppDensity.space(4);

  /// one visual row incl. gap — timeline uses this
  static double get rowHeight => _rowH + _rowGap;

  Color get _accent => const Color(0xff0a84ff);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = _accent.withOpacity(0.16);

    final innerHeight = (height - (_padV * 2)).clamp(_rowH, double.infinity);

    /* how many rows fit vertically inside pill? */
    final int rowsThatFit = ((innerHeight + _rowGap) / (_rowH + _rowGap))
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
            color: Color.alphaBlend(
              colors.surface.withOpacity(0.92),
              bg,
            ),
            borderRadius: BorderRadius.circular(_r),
            border: Border.all(color: _accent.withOpacity(0.48)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: _padH, vertical: _padV),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < visibleSessions.length; i++) ...[
                _miniRow(context, visibleSessions[i]),
                if (i != visibleSessions.length - 1) SizedBox(height: _rowGap),
              ],
              if (overflow) ...[
                if (visibleSessions.isNotEmpty) SizedBox(height: _rowGap),
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
    final fmt = DateFormat.Hm();
    return InkWell(
      onTap: () => _openDetails(ctx, s.id),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: _rowH,
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _accent.withOpacity(0.45)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                s.clients.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              fmt.format(s.start),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                    color: _accent,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
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
          color: _accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _accent.withOpacity(0.45)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: Theme.of(ctx).textTheme.titleMedium),
      ),
    );
  }

  /* ─ dialogs ─ */

  void _showListDialog(BuildContext ctx) {
    // Calculate the height needed for the list and the custom header.
    const double dragHandleBlock = 28;
    const double headerBlock = 72;
    const double sheetBottomPad = 24;
    const double sepGap = 10; // separator gap between tiles
    final int rows = hidden.length;
    final double listHeight = rows * 48 + (rows - 1) * sepGap + sheetBottomPad;
    final double totalHeight = dragHandleBlock + headerBlock + listHeight;
    final double maxH = MediaQuery.of(ctx).size.height * 0.9;
    final bool needsScroll = totalHeight > maxH;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Theme.of(ctx).colorScheme.surface,
      builder: (_) => Material(
        color: Theme.of(ctx).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: needsScroll ? maxH : totalHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppDensity.space(10)),
              Center(
                child: Container(
                  width: AppDensity.space(36),
                  height: AppDensity.space(4),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx)
                        .colorScheme
                        .outlineVariant
                        .withOpacity(0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDensity.space(18),
                  AppDensity.space(14),
                  AppDensity.space(18),
                  AppDensity.space(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overlapping sessions',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${hidden.length} sessions in this time slot',
                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  physics:
                      needsScroll ? null : const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    AppDensity.space(18),
                    AppDensity.space(8),
                    AppDensity.space(18),
                    AppDensity.space(20),
                  ),
                  itemCount: hidden.length,
                  separatorBuilder: (_, __) => const SizedBox(height: sepGap),
                  itemBuilder: (_, i) => _dialogTile(ctx, hidden[i]),
                ),
              ),
            ],
          ),
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
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withOpacity(0.32)),
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: double.infinity,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.clients.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${fmt.format(s.start)} – ${fmt.format(s.end)}',
                style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                      color: _accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 12),
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
