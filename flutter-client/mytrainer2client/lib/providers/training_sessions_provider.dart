import 'package:flutter/material.dart';
import '../models/copy_workout_request.dart';
import '../models/session.dart';
import '../models/training_session.dart';
import '../providers/session_store.dart';
import '../services/training_sessions_api_service.dart';

class TrainingSessionsProvider extends ChangeNotifier {
  final _api = TrainingSessionsApiService();
  TrainingSessionsApiService get api => _api;

  /* ───── calendar badge counts ───── */
  final Map<DateTime, int> _counts = {}; // key = dateOnly
  Map<DateTime, int> get counts => Map.unmodifiable(_counts);

  /* ───── currently-viewed day list ───── */
  final List<TrainingSession> _dayList = [];
  List<TrainingSession> get dayList => List.unmodifiable(_dayList);
  DateTime? _loadedDay;

  bool _trainerSoloOnly = false;

  void setTimelinePreferences({
    bool? trainerSoloOnly,
  }) {
    if (trainerSoloOnly != null) {
      _trainerSoloOnly = trainerSoloOnly;
    }
    syncTimeline();
  }

  /* ───── search list (legacy) ───── */
  bool loading = false;
  String search = '';
  String sort = 'newest';
  int page = 0;
  int size = 20;
  int totalPages = 1;

  final List<TrainingSession> _searchList = [];
  List<TrainingSession> get searchList => List.unmodifiable(_searchList);

  /* ───────── calendar counts ───────── */

  Future<void> loadCounts({
    required DateTime monthFirst,
  }) async {
    final first = monthFirst.subtract(Duration(days: monthFirst.weekday % 7));
    final lastMonthDay = DateTime(monthFirst.year, monthFirst.month + 1, 0);
    final last = lastMonthDay.add(Duration(days: 6 - lastMonthDay.weekday % 7));

    final fresh = await _api.counts(from: first, to: last);
    _counts
      ..removeWhere((d, _) =>
          d.isAfter(first.subtract(const Duration())) &&
          d.isBefore(last.add(const Duration(days: 1))))
      ..addAll(fresh);
    notifyListeners();
  }

  /* ───────── day slice (timeline) ───────── */

  Future<void> loadDay({
    required DateTime day,
  }) async {
    final list = await _api.listDay(day: day);
    _loadedDay = DateUtils.dateOnly(day);
    _dayList
      ..clear()
      ..addAll(list);
    notifyListeners();

    syncTimeline();
  }

  void syncTimeline() {
    final visible = _trainerSoloOnly
        ? _dayList.where(_isSoloSession).toList()
        : List<TrainingSession>.from(_dayList);
    SessionStore().setAll(visible.map(_dtoToSession).toList());
  }

  bool _isSoloSession(TrainingSession dto) {
    return (dto.sessionType ?? '').toUpperCase() == 'SOLO';
  }

  Session _dtoToSession(TrainingSession dto) {
    final baseTitle = dto.sessionName ?? 'Session #${dto.id}';
    final title = _formatTitle(dto, baseTitle);
    return Session(
      id: dto.id,
      start: dto.start,
      end: dto.end,
      clients: [title],
    );
  }

  String _formatTitle(TrainingSession dto, String baseTitle) {
    if (dto.clientNames.isEmpty) {
      return baseTitle;
    }
    final primary = dto.clientNames.first;
    final suffix = dto.clientNames.length > 1
        ? ' +${dto.clientNames.length - 1}'
        : '';
    return '$primary$suffix · $baseTitle';
  }

  /* ───────── paged search list ───────── */

  Future<void> loadSearch({
    int? toPage,
    String? newSearch,
    String? newSort,
  }) async {
    loading = true;
    if (toPage != null) page = toPage;
    if (newSearch != null) search = newSearch;
    if (newSort != null) sort = newSort;
    notifyListeners();

    try {
      final resp = await _api.page(
        page: page,
        size: size,
        q: search,
        sort: sort,
      );

      _searchList
        ..clear()
        ..addAll(resp.items);
      page = resp.page;
      totalPages = resp.totalPages;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /* ───────── create (FAB) ───────── */

  Future<TrainingSession> create({
    required Map<String, dynamic> dto,
  }) async {
    final created = await _api.create(dto: dto);
    _integrateCreatedSession(created);
    return created;
  }

  Future<TrainingSession> copy({
    required int sourceId,
    required CopyWorkoutRequest request,
  }) async {
    final created = await _api.copy(sourceId: sourceId, request: request);
    _integrateCreatedSession(created);
    return created;
  }

  /* ───────── delete ───────── */

  Future<void> deleteOne({
    required int id,
  }) async {
    // grab the session (if present) **before** we mutate the list
    final int idx = _dayList.indexWhere((s) => s.id == id);
    final TrainingSession? toRemove = idx == -1 ? null : _dayList[idx];

    // backend call
    await _api.delete(id: id);

    // local UI lists
    if (idx != -1) _dayList.removeAt(idx);

    // adjust badge counts
    if (toRemove != null) {
      final key = DateUtils.dateOnly(toRemove.start);
      final newCnt = (_counts[key] ?? 1) - 1;
      if (newCnt <= 0) {
        _counts.remove(key);
      } else {
        _counts[key] = newCnt;
      }
    }

    notifyListeners();
  }

  void _integrateCreatedSession(TrainingSession created) {
    final createdDay = DateUtils.dateOnly(created.start);
    if (_loadedDay != null && DateUtils.isSameDay(_loadedDay, createdDay)) {
      _dayList.add(created);
      _dayList.sort((a, b) => a.start.compareTo(b.start));
    }
    _counts.update(createdDay, (value) => value + 1, ifAbsent: () => 1);
    notifyListeners();
    syncTimeline();
  }
}
