import 'package:flutter/material.dart';

import '../models/exercise_history.dart';
import '../services/workout_instance_exercises_api_service.dart';

class ExerciseHistoryProvider extends ChangeNotifier {
  final _api = WorkoutInstanceExercisesApiService();
  final Map<String, ExerciseHistory> _cache = {};
  final Set<String> _loadingKeys = {};

  String _key(int sessionId, int entryId, int limit) =>
      '$sessionId:$entryId:$limit';

  bool isLoading({
    required int sessionId,
    required int entryId,
    int limit = 5,
  }) =>
      _loadingKeys.contains(_key(sessionId, entryId, limit));

  ExerciseHistory? cached({
    required int sessionId,
    required int entryId,
    int limit = 5,
  }) =>
      _cache[_key(sessionId, entryId, limit)];

  Future<ExerciseHistory> fetch({
    required int sessionId,
    required int entryId,
    int limit = 5,
    bool forceRefresh = false,
  }) async {
    final key = _key(sessionId, entryId, limit);
    if (!forceRefresh && _cache.containsKey(key)) {
      return _cache[key]!;
    }

    _loadingKeys.add(key);
    notifyListeners();
    try {
      final history = await _api.history(
        sessionId: sessionId,
        entryId: entryId,
        limit: limit,
      );
      _cache[key] = history;
      return history;
    } finally {
      _loadingKeys.remove(key);
      notifyListeners();
    }
  }
}
