import 'dart:convert';

import 'authenticated_http.dart' as http;

import '../models/program_template.dart';
import '../models/training_session.dart';
import 'dev_endpoints.dart';

class ProgramsApiService {
  static final _base = apiBaseUrl;

  Future<Map<String, String>> _headers() {
    return http.authorizedHeaders(includeJsonContentType: true);
  }

  Never _fail(String prefix, http.Response res) {
    final body = res.body.isEmpty ? '<empty body>' : res.body;
    throw Exception('$prefix (${res.statusCode}): $body');
  }

  Future<List<ProgramTemplateModel>> listTemplates() async {
    final uri = Uri.parse('$_base/trainer/programs');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      _fail('GET programs failed', res);
    }
    return (jsonDecode(res.body) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ProgramTemplateModel.fromJson)
        .toList();
  }

  Future<ProgramTemplateModel> createTemplate(
      ProgramTemplateModel program) async {
    final uri = Uri.parse('$_base/trainer/programs');
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(program.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      _fail('POST program failed', res);
    }
    return ProgramTemplateModel.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<ProgramTemplateModel> updateTemplate(
      ProgramTemplateModel program) async {
    final uri = Uri.parse('$_base/trainer/programs/${program.id}');
    final res = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(program.toJson()),
    );
    if (res.statusCode != 200) {
      _fail('PUT program failed', res);
    }
    return ProgramTemplateModel.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteTemplate(int id) async {
    final uri = Uri.parse('$_base/trainer/programs/$id');
    final res = await http.delete(uri, headers: await _headers());
    if (res.statusCode != 200 && res.statusCode != 204) {
      _fail('DELETE program failed', res);
    }
  }

  Future<void> assignTemplate({
    required int templateId,
    required List<int> clientIds,
    required DateTime startDate,
    bool assignToTrainer = false,
  }) async {
    final day =
        '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse('$_base/trainer/programs/$templateId/assign');
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'clientIds': clientIds,
        'startDate': day,
        'assignToTrainer': assignToTrainer,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _fail('POST program assignment failed', res);
    }
  }

  Future<List<ClientProgram>> listClientPrograms() async {
    final uri = Uri.parse('$_base/client/programs');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      _fail('GET client programs failed', res);
    }
    return (jsonDecode(res.body) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ClientProgram.fromJson)
        .toList();
  }

  Future<List<ClientProgram>> listTrainerAssignedPrograms() async {
    final uri = Uri.parse('$_base/trainer/programs/assigned');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) {
      _fail('GET trainer assigned programs failed', res);
    }
    return (jsonDecode(res.body) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ClientProgram.fromJson)
        .toList();
  }

  Future<TrainingSession> startClientProgramDay({
    required int assignmentId,
    required int dayIndex,
  }) async {
    final uri = Uri.parse(
        '$_base/client/programs/$assignmentId/days/$dayIndex/start');
    final res = await http.post(uri, headers: await _headers());
    if (res.statusCode != 200) {
      _fail('POST start program day failed', res);
    }
    return TrainingSession.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<TrainingSession> startTrainerProgramDay({
    required int assignmentId,
    required int dayIndex,
  }) async {
    final uri = Uri.parse(
        '$_base/trainer/programs/assigned/$assignmentId/days/$dayIndex/start');
    final res = await http.post(uri, headers: await _headers());
    if (res.statusCode != 200) {
      _fail('POST start trainer program day failed', res);
    }
    return TrainingSession.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}
