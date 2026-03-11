import 'package:flutter/material.dart';

import '../models/workout_folder.dart';
import '../services/workout_folders_api_service.dart';

class WorkoutFoldersProvider extends ChangeNotifier {
  final _api = WorkoutFoldersApiService();

  bool loading = false;
  bool supported = true;
  String? error;
  List<WorkoutFolder> items = [];

  Future<void> load({required String token}) async {
    loading = true;
    notifyListeners();
    try {
      items = await _api.list();
      supported = true;
      error = null;
    } on WorkoutFoldersUnavailableException catch (e) {
      supported = false;
      error = e.message;
      items = [];
    } catch (e) {
      supported = true;
      error = e.toString();
      items = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> save({
    required String token,
    required WorkoutFolder folder,
  }) async {
    if (!supported) return;
    if (folder.id == 0) {
      items.add(await _api.create(folder));
    } else {
      final updated = await _api.update(folder);
      final index = items.indexWhere((e) => e.id == folder.id);
      if (index != -1) items[index] = updated;
    }
    notifyListeners();
  }

  Future<void> remove({
    required String token,
    required int id,
  }) async {
    if (!supported) return;
    await _api.delete(id);
    items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
