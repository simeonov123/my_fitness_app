import 'package:flutter/foundation.dart';

import '../models/program_template.dart';
import '../services/programs_api_service.dart';

class ProgramsProvider extends ChangeNotifier {
  final ProgramsApiService _api = ProgramsApiService();

  bool loading = false;
  List<ProgramTemplateModel> templates = [];
  List<ClientProgram> clientPrograms = [];

  Future<void> loadTrainerPrograms() async {
    loading = true;
    notifyListeners();
    try {
      templates = await _api.listTemplates();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadClientPrograms() async {
    loading = true;
    notifyListeners();
    try {
      clientPrograms = await _api.listClientPrograms();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> save(ProgramTemplateModel program) async {
    final saved = program.id == 0
        ? await _api.createTemplate(program)
        : await _api.updateTemplate(program);

    final idx = templates.indexWhere((e) => e.id == saved.id);
    if (idx == -1) {
      templates = [saved, ...templates];
    } else {
      final next = [...templates];
      next[idx] = saved;
      templates = next;
    }
    notifyListeners();
  }

  Future<void> delete(int id) async {
    await _api.deleteTemplate(id);
    templates = templates.where((e) => e.id != id).toList();
    notifyListeners();
  }

  Future<void> assign({
    required int templateId,
    required List<int> clientIds,
    required DateTime startDate,
  }) async {
    await _api.assignTemplate(
      templateId: templateId,
      clientIds: clientIds,
      startDate: startDate,
    );
    notifyListeners();
  }
}
