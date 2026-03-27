import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/page_response.dart';
import '../models/exercise_history.dart';
import '../models/training_session.dart';
import '../models/workout_instance_exercise.dart';
import 'auth_service.dart';
import 'dev_endpoints.dart';

class TrainingSessionsApiService {
  final AuthService _auth = AuthService();

  static final _base = apiBaseUrl;

  /* ───────── helpers ───────── */
  Future<Map<String, String>> _hdr([String? tok]) async {
    final token = tok ?? await _auth.getValidAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No valid access token available');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Never _fail(String prefix, http.Response res) {
    final body = res.body.isEmpty ? '<empty body>' : res.body;
    throw Exception('$prefix (${res.statusCode}): $body');
  }

  /* ───────── calendar counts ───────── */

  Future<Map<DateTime, int>> counts({
    String? token,
    required DateTime from,
    required DateTime to,
  }) async {
    String fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse(
        '$_base/trainer/training-sessions/calendar?from=${fmt(from)}&to=${fmt(to)}');

    final res = await http.get(uri, headers: await _hdr(token));
    if (res.statusCode != 200) {
      _fail('GET counts failed', res);
    }

    final out = <DateTime, int>{};
    for (final m in (jsonDecode(res.body) as List<dynamic>)
        .cast<Map<String, dynamic>>()) {
      out[DateTime.parse(m['date'] as String)] = (m['count'] as num).toInt();
    }
    return out;
  }

  /* ───────── one-day slice ───────── */

  Future<List<TrainingSession>> listDay({
    String? token,
    required DateTime day,
    int page = 0,
    int size = 100,
  }) async {
    final d = '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse(
        '$_base/trainer/training-sessions/day/$d?page=$page&size=$size');

    final res = await http.get(uri, headers: await _hdr(token));
    if (res.statusCode != 200) {
      _fail('GET day list failed', res);
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['content'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(TrainingSession.fromJson)
        .toList();
  }

  /* ───────── paged search ───────── */

  Future<PageResponse<TrainingSession>> page({
    String? token,
    required int page,
    required int size,
    String q = '',
    String sort = 'newest',
  }) async {
    final uri = Uri.parse('$_base/trainer/training-sessions'
        '?page=$page&size=$size&q=${Uri.encodeQueryComponent(q)}&sort=$sort');

    final res = await http.get(uri, headers: await _hdr(token));
    if (res.statusCode != 200) {
      _fail('GET sessions failed', res);
    }

    return PageResponse.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
      TrainingSession.fromJson,
    );
  }

  /* ───────── CRUD (single) ───────── */

  Future<TrainingSession> getOne({
    String? token,
    required int id,
  }) async {
    final uri = Uri.parse('$_base/trainer/training-sessions/$id');
    final res = await http.get(uri, headers: await _hdr(token));
    if (res.statusCode != 200) {
      _fail('GET session failed', res);
    }
    return TrainingSession.fromJson(jsonDecode(res.body));
  }

  Future<TrainingSession> create({
    String? token,
    required Map<String, dynamic> dto,
  }) async {
    final uri = Uri.parse('$_base/trainer/training-sessions');
    final res =
        await http.post(uri, headers: await _hdr(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 201) {
      _fail('POST session failed', res);
    }
    return TrainingSession.fromJson(jsonDecode(res.body));
  }

  Future<TrainingSession> update({
    String? token,
    required int id,
    required Map<String, dynamic> dto,
  }) async {
    final uri = Uri.parse('$_base/trainer/training-sessions/$id');
    final res =
        await http.put(uri, headers: await _hdr(token), body: jsonEncode(dto));
    if (res.statusCode != 200) {
      _fail('PUT session failed', res);
    }
    return TrainingSession.fromJson(jsonDecode(res.body));
  }

  /* ───────── DELETE ───────── */

  Future<void> delete({
    String? token,
    required int id,
  }) async {
    final uri = Uri.parse('$_base/trainer/training-sessions/$id');
    final res = await http.delete(uri, headers: await _hdr(token));

    // backend may return 200 *or* 204 depending on Spring config
    if (res.statusCode != 200 && res.statusCode != 204) {
      _fail('DELETE session failed', res);
    }
  }

  /* ───────── workout-instance helpers (unchanged) ───────── */

  Future<List<WorkoutInstanceExercise>> listInstanceExercises({
    String? token,
    required int sessionId,
  }) async {
    final uri =
        Uri.parse('$_base/trainer/training-sessions/$sessionId/instance');
    final res = await http.get(uri, headers: await _hdr(token));
    if (res.statusCode != 200) {
      _fail('GET instance failed', res);
    }
    return (jsonDecode(res.body) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(WorkoutInstanceExercise.fromJson)
        .toList();
  }

  Future<List<WorkoutInstanceExercise>> replaceInstanceExercises({
    String? token,
    required int sessionId,
    required List<WorkoutInstanceExercise> items,
  }) async {
    final uri =
        Uri.parse('$_base/trainer/training-sessions/$sessionId/instance');
    final res = await http.put(uri,
        headers: await _hdr(token),
        body: jsonEncode(items.map((e) => e.toJson()).toList()));
    if (res.statusCode != 200) {
      _fail('PUT instance failed', res);
    }
    return (jsonDecode(res.body) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(WorkoutInstanceExercise.fromJson)
        .toList();
  }

  Future<ExerciseHistory> getInstanceExerciseHistory({
    String? token,
    required int sessionId,
    required int entryId,
    int limit = 5,
  }) async {
    final uri = Uri.parse(
      '$_base/trainer/training-sessions/$sessionId/instance/$entryId/history?limit=$limit',
    );
    final res = await http.get(uri, headers: await _hdr(token));
    if (res.statusCode != 200) {
      _fail('GET exercise history failed', res);
    }
    return ExerciseHistory.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}
