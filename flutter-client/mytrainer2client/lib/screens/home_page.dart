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

    final auth = context.read<AuthProvider>();
    if (!mounted) return;
    final prov = context.read<TrainingSessionsProvider>();
    final token = await auth.getValidToken();
    if (token == null) return;
    if (!mounted) return;

    await prov.loadCounts(token: token, monthFirst: monthFirst);
  }

  Future<void> _refreshForDay() async {
    final auth = context.read<AuthProvider>();
    if (!mounted) return;
    final prov = context.read<TrainingSessionsProvider>();
    final token = await auth.getValidToken();
    if (token == null) return;
    if (!mounted) return;

    await prov.loadDay(token: token, day: _selectedDay);
  }

  @override
  void initState() {
    super.initState();
    _refreshForMonth().then((_) => _refreshForDay());
  }

  /* ───────── UI ───────── */

  @override
  Widget build(BuildContext context) {
    context.read<NavigationProvider>().setIndex(0);

    return Scaffold(
      appBar: _appBar(context.read<AuthProvider>()),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshForMonth();
          await _refreshForDay();
        },
        child: Column(
          children: [
            SessionsCalendar(
              focused: _focusedDay,
              selected: _selectedDay,
              onSelect: (d) async {
                setState(() {
                  _selectedDay = d;
                  _focusedDay = d;
                });
                await _refreshForDay();
              },
              onPageChanged: (focused) async {
                setState(() => _focusedDay = focused);
                await _refreshForMonth();
              },
            ),
            const Divider(height: 0),
            Expanded(child: SessionsTimeline(day: _selectedDay)),
          ],
        ),
      ),

      /* ───────── new-session FAB ───────── */

      floatingActionButton: FloatingActionButton(
        tooltip: 'Add session',
        child: const Icon(Icons.add),
        onPressed: () async {
          final selectedDay = _selectedDay;
          final auth = context.read<AuthProvider>();
          final prov = context.read<TrainingSessionsProvider>();
          final dto = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (_) => TrainingSessionFormDialog(
              initialDay: selectedDay,
            ),
          );
          if (dto == null) return;

          final token = await auth.getValidToken();
          if (token == null) return;
          if (!mounted) return;
          TrainingSession created;
          try {
            created = await prov.create(token: token, dto: dto);
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to create session: $e')),
            );
            return;
          }
          if (!mounted) return;

          // switch to the day/month where the new session was added
          setState(() {
            _selectedDay = created.start;
            _focusedDay = created.start;
          });
          await _refreshForMonth();
          await _refreshForDay();
        },
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  /* ───────── App-bar ───────── */

  AppBar _appBar(AuthProvider auth) => AppBar(
        title: const Text('Home'),
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
