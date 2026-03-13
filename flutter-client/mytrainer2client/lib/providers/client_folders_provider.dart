import 'package:flutter/material.dart';

import '../models/client_folder.dart';
import '../services/client_folders_api_service.dart';

class ClientFoldersProvider extends ChangeNotifier {
  final _api = ClientFoldersApiService();

  bool loading = false;
  bool supported = true;
  String? error;
  List<ClientFolder> items = [];

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      items = await _api.list();
      supported = true;
      error = null;
    } on ClientFoldersUnavailableException catch (e) {
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
    required ClientFolder folder,
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
    required int id,
  }) async {
    if (!supported) return;
    await _api.delete(id);
    items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
