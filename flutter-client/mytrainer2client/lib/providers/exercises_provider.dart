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

  /* ───────── internal helper ───────── */

  Future<void> _load(Future<List<Exercise>> Function() fetch) async {
    if (_loading) return;               // guard against duplicate calls
    _loading = true;

    // defer the first notify until the next micro-task; this makes it
    // impossible to hit “setState() during build”.
    scheduleMicrotask(notifyListeners);

    _all = await fetch();
    _loading = false;
    notifyListeners();
  }

  /* ───────── public API (unchanged signature) ───────── */

  Future<void> load()            => _load(() => _api.list());
  Future<void> loadCommon()      => _load(() => _api.listCommon());

  void search(String q) {
    _search = q;
    notifyListeners();
  }
}
