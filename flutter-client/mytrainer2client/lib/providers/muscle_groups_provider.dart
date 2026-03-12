import 'package:flutter/material.dart';

import '../models/muscle_group.dart';
import '../services/muscle_groups_api_service.dart';

class MuscleGroupsProvider extends ChangeNotifier {
  final _api = MuscleGroupsApiService();

  bool _loading = false;
  List<MuscleGroup> _items = [];

  bool get loading => _loading;
  List<MuscleGroup> get items => List.unmodifiable(_items);

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      _items = await _api.list();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<MuscleGroup> create(String name) async {
    final created = await _api.create(name: name);
    _items = [..._items.where((item) => item.id != created.id), created]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
    return created;
  }

  Future<MuscleGroup> update(int id, String name) async {
    final updated = await _api.update(id: id, name: name);
    _items = _items
        .map((item) => item.id == id ? updated : item)
        .toList(growable: false)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
    return updated;
  }

  Future<void> remove(int id) async {
    await _api.delete(id);
    _items = _items.where((item) => item.id != id).toList(growable: false);
    notifyListeners();
  }
}
