import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/training_session.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/training_sessions_provider.dart';

import '../widgets/bottom_nav_bar.dart';
import '../widgets/sessions_calendar.dart';
import '../widgets/sessions_timeline.dart';
import '../widgets/training_session_form_dialog.dart';
import '../theme/app_density.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  /* ───────── backend sync helpers ───────── */

  Future<void> _refreshForMonth() async {
    final monthFirst = DateTime(_focusedDay.year, _focusedDay.month, 1);

    if (!mounted) return;
    final prov = context.read<TrainingSessionsProvider>();
    await prov.loadCounts(monthFirst: monthFirst);
  }

  Future<void> _refreshForDay() async {
    if (!mounted) return;
    final prov = context.read<TrainingSessionsProvider>();
    await prov.loadDay(day: _selectedDay);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NavigationProvider>().setIndex(0);
    });
    _refreshForMonth().then((_) => _refreshForDay());
  }

  Future<void> _openCreateSessionDialog([DateTime? day]) async {
    final selectedDay = day ?? _selectedDay;
    final prov = context.read<TrainingSessionsProvider>();
    final dto = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => TrainingSessionFormDialog(
        initialDay: DateUtils.dateOnly(selectedDay),
        initialStartTime: day,
      ),
    );
    if (dto == null || !mounted) return;

    TrainingSession created;
    try {
      created = await prov.create(dto: dto);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create session: $e')),
      );
      return;
    }
    if (!mounted) return;

    setState(() {
      _selectedDay = created.start;
      _focusedDay = created.start;
    });
    await _refreshForMonth();
    await _refreshForDay();
  }

  /* ───────── UI ───────── */

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final dayList = context.watch<TrainingSessionsProvider>().dayList;
    final totalClients =
        dayList.expand((session) => session.clientIds).toSet().length;
    final summaryLabel = _dailySummary(
      day: _selectedDay,
      sessionCount: dayList.length,
      clientCount: totalClients,
    );

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: _appBar(auth),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshForMonth();
          await _refreshForDay();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppDensity.space(14),
            AppDensity.space(10),
            AppDensity.space(14),
            AppDensity.space(18),
          ),
          children: [
            _CalendarHero(
              monthLabel: _monthLabel(_focusedDay),
              dayLabel: _selectedDay.day.toString(),
              weekdayLabel: _weekdayLabel(_selectedDay),
              yearLabel: _selectedDay.year.toString(),
              summaryLabel: summaryLabel,
              onToday: () async {
                final today = DateUtils.dateOnly(DateTime.now());
                setState(() {
                  _selectedDay = today;
                  _focusedDay = today;
                });
                await _refreshForMonth();
                await _refreshForDay();
              },
            ),
            SizedBox(height: AppDensity.space(10)),
            SessionsCalendar(
              focused: _focusedDay,
              selected: _selectedDay,
              onSelect: (day) async {
                setState(() {
                  _selectedDay = day;
                  _focusedDay = day;
                });
                await _refreshForDay();
              },
              onLongPressDay: (day) async {
                HapticFeedback.mediumImpact();
                setState(() {
                  _selectedDay = day;
                  _focusedDay = day;
                });
                await _refreshForDay();
                if (!mounted) return;
                await _openCreateSessionDialog(day);
              },
              onPageChanged: (focused) async {
                setState(() => _focusedDay = focused);
                await _refreshForMonth();
              },
            ),
            SizedBox(height: AppDensity.space(14)),
            Container(
              padding: EdgeInsets.fromLTRB(
                AppDensity.space(14),
                AppDensity.space(13),
                AppDensity.space(14),
                AppDensity.space(14),
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppDensity.circular(24),
                border: Border.all(
                  color: colors.outlineVariant.withOpacity(0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withOpacity(0.08),
                    blurRadius: AppDensity.space(18),
                    offset: Offset(0, AppDensity.space(8)),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _timelineLabel(_selectedDay),
                              style: text.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: AppDensity.space(3)),
                            Text(
                              'Tap a day to review sessions. Press and hold a day to create one immediately.',
                              style: text.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: AppDensity.space(8)),
                      FilledButton.tonalIcon(
                        onPressed: () => _openCreateSessionDialog(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('New'),
                      ),
                    ],
                  ),
                  SizedBox(height: AppDensity.space(14)),
                  SizedBox(
                    height: AppDensity.space(560),
                    child: SessionsTimeline(
                      day: _selectedDay,
                      onLongPressTime: (startAt) async {
                        HapticFeedback.mediumImpact();
                        await _openCreateSessionDialog(startAt);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      /* ───────── new-session FAB ───────── */

      bottomNavigationBar: const BottomNavBar(),
    );
  }

  /* ───────── App-bar ───────── */

  AppBar _appBar(AuthProvider auth) => AppBar(
        title: const Text('Calendar'),
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.vpn_key),
              tooltip: 'Copy access token',
              onPressed: () async {
                final token = await auth.getValidToken();
                if (token == null) return;
                await Clipboard.setData(ClipboardData(text: token));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Access token copied')),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
          ),
        ],
      );
}

String _monthLabel(DateTime day) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return months[day.month - 1];
}

String _weekdayLabel(DateTime day) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return weekdays[day.weekday - 1];
}

String _timelineLabel(DateTime day) {
  final today = DateUtils.dateOnly(DateTime.now());
  final selected = DateUtils.dateOnly(day);
  if (selected == today) return 'Today';
  if (selected == today.add(const Duration(days: 1))) return 'Tomorrow';
  if (selected == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return '${_weekdayLabel(day)}, ${_monthLabel(day)} ${day.day}';
}

class _CalendarHero extends StatelessWidget {
  const _CalendarHero({
    required this.monthLabel,
    required this.dayLabel,
    required this.weekdayLabel,
    required this.yearLabel,
    required this.summaryLabel,
    required this.onToday,
  });

  final String monthLabel;
  final String dayLabel;
  final String weekdayLabel;
  final String yearLabel;
  final String summaryLabel;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withOpacity(0.14),
            colors.surface,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthLabel,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$weekdayLabel • $yearLabel',
                  style: text.titleSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  summaryLabel,
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FilledButton.tonal(
                onPressed: onToday,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colors.outlineVariant.withOpacity(0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      dayLabel,
                      style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
                    Text(
                      weekdayLabel.substring(0, 3).toUpperCase(),
                      style: text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _dailySummary({
  required DateTime day,
  required int sessionCount,
  required int clientCount,
}) {
  final dayLabel = _timelineLabel(day).toLowerCase();
  final sessionsLabel =
      sessionCount == 1 ? '1 session' : '$sessionCount sessions';
  final clientsLabel = clientCount == 1 ? '1 client' : '$clientCount clients';
  return '$dayLabel you have $sessionsLabel with a total of $clientsLabel.';
}
