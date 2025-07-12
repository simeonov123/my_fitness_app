import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../providers/session_store.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.paletteIndex,
    this.compact = false,
  });

  final Session session;
  final int     paletteIndex;
  final bool    compact;          // true when card width < _minReadable

  static const _r     = 8.0;      // radius
  static const _stripe= 4.0;      // stripe width
  static const _minH  = 36.0;

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
    final fmt = DateFormat.Hm();
    final txt = compact
        ? fmt.format(session.start)                           // just start time
        : '${fmt.format(session.start)} – ${fmt.format(session.end)}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(_r),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _detail(context),
          onLongPress: () => _actions(context),
          child: Container(
            constraints: const BoxConstraints(minHeight: _minH),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(_r),
              border: Border.all(color: _accent.withOpacity(.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: _stripe, color: _accent),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.clients.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(txt, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* dialogs */

  void _detail(BuildContext ctx) {
    Navigator.pushNamed(ctx, '/session', arguments: session.id);
  }

  void _actions(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Wrap(children: [
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
