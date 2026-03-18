import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/exercise_history.dart';
import '../providers/exercise_history_provider.dart';
import '../theme/app_density.dart';

class ExerciseHistorySheet extends StatefulWidget {
  final int sessionId;
  final int entryId;
  final ValueChanged<int> onOpenSnapshot;

  const ExerciseHistorySheet({
    super.key,
    required this.sessionId,
    required this.entryId,
    required this.onOpenSnapshot,
  });

  @override
  State<ExerciseHistorySheet> createState() => _ExerciseHistorySheetState();
}

class _ExerciseHistorySheetState extends State<ExerciseHistorySheet> {
  Future<ExerciseHistory>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _future = context.read<ExerciseHistoryProvider>().fetch(
              sessionId: widget.sessionId,
              entryId: widget.entryId,
            );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.68,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDensity.radius(30)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: FutureBuilder<ExerciseHistory>(
            future: _future,
            builder: (context, snapshot) {
              if (_future == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _HistoryState(
                  title: 'Exercise history',
                  child: Padding(
                    padding: AppDensity.all(18),
                    child: Text(
                      'Failed to load history.\n${snapshot.error}',
                      style: const TextStyle(
                        color: Color(0xFF5D6475),
                        height: 1.45,
                      ),
                    ),
                  ),
                );
              }

              final history = snapshot.data!;
              return _HistoryState(
                title: history.exerciseName,
                subtitle: history.clientName == null
                    ? 'Previous training data'
                    : '${history.clientName} • previous training data',
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppDensity.space(18),
                    0,
                    AppDensity.space(18),
                    AppDensity.space(20),
                  ),
                  children: [
                    Wrap(
                      spacing: AppDensity.space(10),
                      runSpacing: AppDensity.space(10),
                      children: _metricCards(history.summary),
                    ),
                    SizedBox(height: AppDensity.space(16)),
                    Row(
                      children: [
                        const Text(
                          'Recent snapshots',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF232530),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${history.snapshots.length} sessions',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7382A4),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDensity.space(10)),
                    if (history.snapshots.isEmpty)
                      _emptyState()
                    else
                      ...history.snapshots.map(_snapshotCard),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _metricCards(ExerciseHistorySummary summary) {
    final cards = <Widget>[
      _metricCard('Avg best reps', _formatCount(summary.averageBestRepsPerSet)),
      _metricCard('1RM', _formatKg(summary.estimatedOneRepMax)),
      _metricCard('Best volume', _formatKg(summary.bestSetVolume)),
      if (summary.bestWeight != null)
        _metricCard('Best weight', _formatKg(summary.bestWeight)),
      if (summary.bestDurationSeconds != null)
        _metricCard('Best time', _formatDuration(summary.bestDurationSeconds)),
      if (summary.bestDistanceKm != null)
        _metricCard('Best distance', _formatDistance(summary.bestDistanceKm)),
      if (summary.fastestPaceSecondsPerKm != null)
        _metricCard(
            'Fastest pace', _formatPace(summary.fastestPaceSecondsPerKm)),
    ];

    return cards;
  }

  Widget _metricCard(String label, String value) {
    return Container(
      width: AppDensity.space(132),
      padding: AppDensity.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: AppDensity.circular(18),
        border: Border.all(color: const Color(0xFFD9E6FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7382A4),
            ),
          ),
          SizedBox(height: AppDensity.space(6)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF232530),
            ),
          ),
        ],
      ),
    );
  }

  Widget _snapshotCard(ExerciseHistorySnapshot snapshot) {
    final date = snapshot.sessionStart == null
        ? 'Unknown date'
        : DateFormat('EEE, MMM d').format(snapshot.sessionStart!);

    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        widget.onOpenSnapshot(snapshot.sessionId);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: AppDensity.space(10)),
        padding: AppDensity.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppDensity.circular(20),
          border: Border.all(color: const Color(0xFFD9E6FF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F2F80FF),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    snapshot.sessionName?.trim().isNotEmpty == true
                        ? snapshot.sessionName!
                        : 'Training session',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF232530),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF6D7CA0),
                ),
              ],
            ),
            SizedBox(height: AppDensity.space(5)),
            Text(
              date,
              style: const TextStyle(
                color: Color(0xFF7382A4),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppDensity.space(10)),
            Wrap(
              spacing: AppDensity.space(7),
              runSpacing: AppDensity.space(7),
              children: [
                _chip(
                    '${snapshot.completedSetCount}/${snapshot.totalSetCount} sets'),
                if (snapshot.bestReps != null)
                  _chip('${_formatCount(snapshot.bestReps)} reps'),
                if (snapshot.bestWeight != null)
                  _chip(_formatKg(snapshot.bestWeight)),
                if (snapshot.bestSetVolume != null)
                  _chip('${snapshot.bestSetVolume!.toStringAsFixed(0)} vol'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: AppDensity.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: AppDensity.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF2F80FF),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: AppDensity.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: AppDensity.circular(20),
        border: Border.all(color: const Color(0xFFD9E6FF)),
      ),
      child: const Text(
        'No completed history yet for this exercise.',
        style: TextStyle(
          color: Color(0xFF5D6475),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatCount(double? value) {
    if (value == null) return '--';
    if ((value - value.round()).abs() < 0.01) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _formatKg(double? value) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(1)} kg';
  }

  String _formatDuration(double? value) {
    if (value == null) return '--';
    final totalSeconds = value.round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  String _formatDistance(double? value) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(2)} km';
  }

  String _formatPace(double? value) {
    if (value == null) return '--';
    final totalSeconds = value.round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
  }
}

class _HistoryState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _HistoryState({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: AppDensity.space(10)),
        Container(
          width: AppDensity.space(38),
          height: AppDensity.space(4),
          decoration: BoxDecoration(
            color: const Color(0xFFD7DCE8),
            borderRadius: AppDensity.circular(999),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppDensity.space(18),
            AppDensity.space(16),
            AppDensity.space(18),
            AppDensity.space(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF232530),
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: AppDensity.space(5)),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xFF7382A4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
