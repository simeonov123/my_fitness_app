import 'package:flutter/foundation.dart';

import '../models/program_template.dart';
import '../services/programs_api_service.dart';

class ProgramsProvider extends ChangeNotifier {
  final ProgramsApiService _api = ProgramsApiService();

  bool loading = false;
  List<ProgramTemplateModel> templates = [];
  List<ClientProgram> clientPrograms = [];
  List<ClientProgram> trainerAssignedPrograms = [];

  Future<void> loadTrainerPrograms() async {
    loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.listTemplates(),
        _api.listTrainerAssignedPrograms(),
      ]);
      templates = results[0] as List<ProgramTemplateModel>;
      trainerAssignedPrograms = results[1] as List<ClientProgram>;
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
    bool assignToTrainer = false,
  }) async {
    await _api.assignTemplate(
      templateId: templateId,
      clientIds: clientIds,
      startDate: startDate,
      assignToTrainer: assignToTrainer,
    );
    await loadTrainerPrograms();
  }

  Future<int> startClientProgramDay({
    required int assignmentId,
    required int dayIndex,
  }) async {
    final session = await _api.startClientProgramDay(
      assignmentId: assignmentId,
      dayIndex: dayIndex,
    );
    _applyStartedDay(
      programs: clientPrograms,
      assignmentId: assignmentId,
      dayIndex: dayIndex,
      trainingSessionId: session.id,
    );
    return session.id;
  }

  Future<int> startTrainerProgramDay({
    required int assignmentId,
    required int dayIndex,
  }) async {
    final session = await _api.startTrainerProgramDay(
      assignmentId: assignmentId,
      dayIndex: dayIndex,
    );
    _applyStartedDay(
      programs: trainerAssignedPrograms,
      assignmentId: assignmentId,
      dayIndex: dayIndex,
      trainingSessionId: session.id,
    );
    return session.id;
  }

  void _applyStartedDay({
    required List<ClientProgram> programs,
    required int assignmentId,
    required int dayIndex,
    required int trainingSessionId,
  }) {
    final programIndex =
        programs.indexWhere((program) => program.assignmentId == assignmentId);
    if (programIndex == -1) {
      return;
    }
    final program = programs[programIndex];
    final updatedDays = program.days
        .map((day) => day.dayIndex == dayIndex
            ? ClientProgramDay(
                dayIndex: day.dayIndex,
                label: day.label,
                restDay: day.restDay,
                trainingSessionId: trainingSessionId,
                workoutTemplateId: day.workoutTemplateId,
                workoutName: day.workoutName,
                completed: day.completed,
              )
            : day)
        .toList();
    final updatedPrograms = [...programs];
    updatedPrograms[programIndex] = ClientProgram(
      assignmentId: program.assignmentId,
      programId: program.programId,
      name: program.name,
      goal: program.goal,
      description: program.description,
      startDate: program.startDate,
      endDate: program.endDate,
      totalDays: program.totalDays,
      completedDays: program.completedDays,
      status: program.status,
      assignedAt: program.assignedAt,
      days: updatedDays,
    );
    if (programs == clientPrograms) {
      clientPrograms = updatedPrograms;
    } else {
      trainerAssignedPrograms = updatedPrograms;
    }
    notifyListeners();
  }
}
