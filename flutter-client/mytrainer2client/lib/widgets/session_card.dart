import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/copy_workout_request.dart';
import '../models/session.dart';
import '../providers/auth_provider.dart';
import '../providers/session_store.dart';
import '../providers/training_sessions_provider.dart';
import '../theme/app_density.dart';
import 'copy_workout_sheet.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.paletteIndex,
    this.compact = false,
  });

  final Session session;
  final int paletteIndex;
  final bool compact;

  static final _r = AppDensity.radius(16);
  static final _stripe = AppDensity.space(4);
  static final _minH = AppDensity.space(38);

  Color get _accent => const Color(0xff0a84ff);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = _accent.withOpacity(0.18);
    final fmt = DateFormat.Hm();
    final title = session.clients.join(', ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 92;
        final ultraNarrow = constraints.maxWidth < 72;
        final tightHeight = constraints.maxHeight < 84;
        final compactCard = compact || narrow;

        return ClipRRect(
          borderRadius: BorderRadius.circular(_r),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _detail(context),
              onLongPress: () => _actions(context),
              child: Container(
                constraints: BoxConstraints(minHeight: _minH),
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    colors.surface.withOpacity(0.92),
                    bg,
                  ),
                  borderRadius: BorderRadius.circular(_r),
                  border: Border.all(color: _accent.withOpacity(0.42)),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: _stripe,
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(_r),
                        ),
                      ),
                    ),
                    SizedBox(width: AppDensity.space(5)),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          0,
                          compactCard
                              ? AppDensity.space(7)
                              : AppDensity.space(9),
                          compactCard
                              ? AppDensity.space(5)
                              : AppDensity.space(8),
                          compactCard
                              ? AppDensity.space(7)
                              : AppDensity.space(9),
                        ),
                        child: compactCard
                            ? _compactContent(
                                context,
                                title: title,
                                start: fmt.format(session.start),
                                end: fmt.format(session.end),
                                ultraNarrow: ultraNarrow,
                                tightHeight: tightHeight,
                              )
                            : _regularContent(
                                context,
                                title: title,
                                range:
                                    '${fmt.format(session.start)} – ${fmt.format(session.end)}',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _regularContent(
    BuildContext context, {
    required String title,
    required String range,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: AppDensity.space(3)),
        Container(
          padding: AppDensity.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.14),
            borderRadius: AppDensity.circular(999),
          ),
          child: Text(
            range,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _accent,
                ),
          ),
        ),
      ],
    );
  }

  Widget _compactContent(
    BuildContext context, {
    required String title,
    required String start,
    required String end,
    required bool ultraNarrow,
    required bool tightHeight,
  }) {
    final compactTitle = _compactTitle(title);
    final text = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          compactTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        SizedBox(
          height: tightHeight ? AppDensity.space(2) : AppDensity.space(4),
        ),
        if (ultraNarrow)
          Text(
            '$start\n$end',
            maxLines: 2,
            overflow: TextOverflow.fade,
            style: text.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: _accent,
              height: 1.0,
            ),
          )
        else
          Container(
            padding: AppDensity.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: AppDensity.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _accent,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: AppDensity.space(2)),
                Text(
                  end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _accent.withOpacity(0.78),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _compactTitle(String title) {
    final match =
        RegExp(r'^Session\s+#?(\d+)$', caseSensitive: false).firstMatch(title);
    if (match != null) {
      return '#${match.group(1)}';
    }
    if (title.length <= 10) return title;
    return title.split(' ').first;
  }

  void _detail(BuildContext ctx) {
    Navigator.pushNamed(ctx, '/session', arguments: session.id);
  }

  void _actions(BuildContext ctx) {
    final isTrainer = ctx.read<AuthProvider>().isTrainer;
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Theme.of(ctx).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDensity.radius(28)),
        ),
      ),
      builder: (_) => SafeArea(
        child: Wrap(children: [
          SizedBox(height: AppDensity.space(10)),
          Center(
            child: Container(
              width: AppDensity.space(36),
              height: AppDensity.space(4),
              decoration: BoxDecoration(
                color:
                    Theme.of(ctx).colorScheme.outlineVariant.withOpacity(0.9),
                borderRadius: AppDensity.circular(999),
              ),
            ),
          ),
          SizedBox(height: AppDensity.space(10)),
          if (isTrainer)
            ListTile(
              leading: const Icon(Icons.content_copy_rounded),
              title: const Text('Copy workout'),
              onTap: () async {
                Navigator.pop(ctx);
                final request = await showModalBottomSheet<CopyWorkoutRequest>(
                  context: ctx,
                  isScrollControlled: true,
                  backgroundColor: Theme.of(ctx).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppDensity.radius(28)),
                    ),
                  ),
                  builder: (_) => CopyWorkoutSheet(
                    initialName: session.clients.isEmpty
                        ? 'Copied workout'
                        : session.clients.first,
                  ),
                );
                if (request == null || !ctx.mounted) return;
                try {
                  await ctx
                      .read<TrainingSessionsProvider>()
                      .copy(sourceId: session.id, request: request);
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Workout copied')),
                  );
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed to copy workout: $e')),
                  );
                }
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () => _detail(ctx),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete'),
            onTap: () {
              SessionStore().remove(ctx, session.id);
              Navigator.pop(ctx);
            },
          ),
        ]),
      ),
    );
  }
}
