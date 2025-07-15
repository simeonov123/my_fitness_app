import 'package:flutter/material.dart';
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
    required String token,
    required DateTime monthFirst,
  }) async {
    final first = monthFirst.subtract(Duration(days: monthFirst.weekday % 7));
    final lastMonthDay = DateTime(monthFirst.year, monthFirst.month + 1, 0);
    final last = lastMonthDay.add(Duration(days: 6 - lastMonthDay.weekday % 7));

    final fresh = await _api.counts(token: token, from: first, to: last);
    _counts
      ..removeWhere((d, _) =>
          d.isAfter(first.subtract(const Duration())) &&
          d.isBefore(last.add(const Duration(days: 1))))
      ..addAll(fresh);
    notifyListeners();
  }

  /* ───────── day slice (timeline) ───────── */

  Future<void> loadDay({
    required String token,
    required DateTime day,
  }) async {
    final list = await _api.listDay(token: token, day: day);
    _dayList
      ..clear()
      ..addAll(list);
    notifyListeners();

    SessionStore().setAll(_dayList.map(_dtoToSession).toList());
  }

  Session _dtoToSession(TrainingSession dto) => Session(
        id: dto.id,
        start: dto.start,
        end: dto.end,
        clients: [dto.sessionName ?? 'Session #${dto.id}'],
      );

  /* ───────── paged search list ───────── */

  Future<void> loadSearch({
    required String token,
    int? toPage,
    String? newSearch,
    String? newSort,
  }) async {
    loading = true;
    if (toPage != null) page = toPage;
    if (newSearch != null) search = newSearch;
    if (newSort != null) sort = newSort;
    notifyListeners();

    final resp = await _api.page(
      token: token,
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
    loading = false;
    notifyListeners();
  }

  /* ───────── create (FAB) ───────── */

  Future<TrainingSession> create({
    required String token,
    required Map<String, dynamic> dto,
  }) async {
    final created = await _api.create(token: token, dto: dto);
    _dayList.add(created); // if it's today it appears immediately
    notifyListeners();
    return created;
  }

  /* ───────── delete ───────── */

  Future<void> deleteOne({
    required String token,
    required int id,
  }) async {
    // grab the session (if present) **before** we mutate the list
    final int idx = _dayList.indexWhere((s) => s.id == id);
    final TrainingSession? toRemove = idx == -1 ? null : _dayList[idx];

    // backend call
    await _api.delete(token: token, id: id);

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
}
