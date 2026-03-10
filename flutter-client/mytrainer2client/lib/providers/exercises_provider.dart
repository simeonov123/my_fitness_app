import 'dart:async';
import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/exercises_api_service.dart';

class ExercisesProvider extends ChangeNotifier {
  final _api = ExercisesApiService();

  List<Exercise> _all = [];
  bool  _loading = false;
  String _search = '';

  /* ───────── getters ───────── */

  bool get loading => _loading;

  List<Exercise> get list => _all.where(
        (e) => _search.isEmpty ||
        e.name.toLowerCase().contains(_search.toLowerCase()),
  ).toList(growable: false);

  List<Exercise> _sortExercises(Iterable<Exercise> source) {
    final sorted = source.toList(growable: false);
    sorted.sort((a, b) {
      if (a.isCustom != b.isCustom) {
        return a.isCustom ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  /* ───────── internal helper ───────── */

  Future<void> _load(Future<List<Exercise>> Function() fetch) async {
    if (_loading) return;               // guard against duplicate calls
    _loading = true;

    // defer the first notify until the next micro-task; this makes it
    // impossible to hit “setState() during build”.
    scheduleMicrotask(notifyListeners);

    _all = _sortExercises(await fetch());
    _loading = false;
    notifyListeners();
  }

  /* ───────── public API (unchanged signature) ───────── */

  Future<void> load()            => _load(() => _api.list());
  Future<void> loadCommon()      => _load(() => _api.listCommon());
  Future<void> loadAvailable()   => _load(() async {
        final common = await _api.listCommon();
        final custom = await _api.list();
        final byId = <int, Exercise>{};
        for (final ex in [...custom, ...common]) {
          byId[ex.id] = ex;
        }
        return byId.values.toList(growable: false);
      });

  Future<Exercise> create({
    required String name,
    String? description,
    required String defaultSetType,
    required String defaultSetParams,
  }) async {
    final created = await _api.create(
      name: name,
      description: description,
      defaultSetType: defaultSetType,
      defaultSetParams: defaultSetParams,
    );
    _all = _sortExercises([..._all.where((e) => e.id != created.id), created]);
    notifyListeners();
    return created;
  }

  void search(String q) {
    _search = q;
    notifyListeners();
  }
}
