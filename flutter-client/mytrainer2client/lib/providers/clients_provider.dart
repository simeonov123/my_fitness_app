import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/clients_api_service.dart';

class ClientsProvider extends ChangeNotifier {
  final ClientsApiService _api = ClientsApiService();

  bool loading = false;
  String search = '';
  String sort = 'newest';
  int size = 10;
  int page = 0;
  int totalPages = 1;
  List<Client> items = [];

  Future<void> load({
    required String token,
    int? toPage,
    String? newSearch,
    String? newSort,
  }) async {
    loading = true;
    if (newSearch != null) search = newSearch;
    if (newSort   != null) sort   = newSort;
    if (toPage != null) page = toPage;
    notifyListeners();

    final p = await _api.page(
      page: page,
      size: size,
      q: search,
      sort : sort,
    );

    items = p.items;
    page = p.page;
    totalPages = p.totalPages;
    loading = false;
    notifyListeners();
  }

  Future<void> save({
    required String token,
    required Client c,
  }) async {
    if (c.id == 0) {
      final created = await _api.create(c);
      items.insert(0, created);
    } else {
      final updated = await _api.update(c);
      final idx = items.indexWhere((e) => e.id == c.id);
      if (idx != -1) items[idx] = updated;
    }
    notifyListeners();
  }

  Future<void> remove({
    required String token,
    required int id,
  }) async {
    await _api.delete(id);
    items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
