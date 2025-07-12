import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/page_response.dart';
import '../models/training_session.dart';
import '../models/workout_instance_exercise.dart';

class TrainingSessionsApiService {
  static const _base =
  kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';

  /* ───────── helpers ───────── */
  Map<String, String> _hdr(String tok) => {
    'Authorization': 'Bearer $tok',
    'Content-Type': 'application/json',
  };

  /* ───────── calendar counts ───────── */

  Future<Map<DateTime, int>> counts({
    required String token,
    required DateTime from,
    required DateTime to,
  }) async {
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse(
        '$_base/trainer/training-sessions/calendar?from=${fmt(from)}&to=${fmt(to)}');

    final res = await http.get(uri, headers: _hdr(token));
    if (res.statusCode != 200) {
      throw Exception('GET counts failed • ${res.body}');
    }

    final out = <DateTime, int>{};
    for (final m in (jsonDecode(res.body) as List<dynamic>)
        .cast<Map<String, dynamic>>()) {
      out[DateTime.parse(m['date'] as String)] =
          (m['count'] as num).toInt();
    }
    return out;
  }

  /* ───────── one-day slice ───────── */

  Future<List<TrainingSession>> listDay({
    required String token,
    required DateTime day,
    int page = 0,
    int size = 100,
  }) async {
    final d = '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse(
        '$_base/trainer/training-sessions/day/$d?page=$page&size=$size');

    final res = await http.get(uri, headers: _hdr(token));
    if (res.statusCode != 200) {
      throw Exception('GET day list failed • ${res.body}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['content'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(TrainingSession.fromJson)
        .toList();
  }

  /* ───────── paged search ───────── */

  Future<PageResponse<TrainingSession>> page({
    required String token,
    required int page,
    required int size,
    String q = '',
    String sort = 'newest',
  }) async {
    final uri = Uri.parse('$_base/trainer/training-sessions'
        '?page=$page&size=$size&q=${Uri.encodeQueryComponent(q)}&sort=$sort');

    final res = await http.get(uri, headers: _hdr(token));
    if (res.statusCode != 200) {
      throw Exception('GET sessions failed • ${res.body}');
    }

    return PageResponse.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
      TrainingSession.fromJson,
    );
  }

  /* ───────── CRUD (single) ───────── */

  Future<TrainingSession> getOne({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('$_base/trainer/training-sessions/$id');
    final res = await http.get(uri, headers: _hdr(token));
    if (res.statusCode != 200) {
      throw Exception('GET session failed • ${res.body}');
    }
    return TrainingSession.fromJson(jsonDecode(res.body));
  }

  Future<TrainingSession> create({
    required String token,
    required Map<String, dynamic> dto,
  }) async {
    final uri = Uri.parse('$_base/trainer/training-sessions');
    final res =
    await http.post(uri, headers: _hdr(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('POST session failed • ${res.body}');
    }
    return TrainingSession.fromJson(jsonDecode(res.body));
  }

  Future<TrainingSession> update({
    required String token,
    required int id,
    required Map<String, dynamic> dto,
  }) async {
    final uri = Uri.parse('$_base/trainer/training-sessions/$id');
    final res =
    await http.put(uri, headers: _hdr(token), body: jsonEncode(dto));
    if (res.statusCode != 200) {
      throw Exception('PUT session failed • ${res.body}');
    }
    return TrainingSession.fromJson(jsonDecode(res.body));
  }

  /* ───────── DELETE ───────── */

  Future<void> delete({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('$_base/trainer/training-sessions/$id');
    final res = await http.delete(uri, headers: _hdr(token));

    // backend may return 200 *or* 204 depending on Spring config
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('DELETE session failed • ${res.body}');
    }
  }

  /* ───────── workout-instance helpers (unchanged) ───────── */

  Future<List<WorkoutInstanceExercise>> listInstanceExercises({
    required String token,
    required int sessionId,
  }) async {
    final uri =
    Uri.parse('$_base/trainer/training-sessions/$sessionId/instance');
    final res = await http.get(uri, headers: _hdr(token));
    if (res.statusCode != 200) {
      throw Exception('GET instance failed • ${res.body}');
    }
    return (jsonDecode(res.body) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(WorkoutInstanceExercise.fromJson)
        .toList();
  }

  Future<List<WorkoutInstanceExercise>> replaceInstanceExercises({
    required String token,
    required int sessionId,
    required List<WorkoutInstanceExercise> items,
  }) async {
    final uri =
    Uri.parse('$_base/trainer/training-sessions/$sessionId/instance');
    final res = await http.put(uri,
        headers: _hdr(token),
        body: jsonEncode(items.map((e) => e.toJson()).toList()));
    if (res.statusCode != 200) {
      throw Exception('PUT instance failed • ${res.body}');
    }
    return (jsonDecode(res.body) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(WorkoutInstanceExercise.fromJson)
        .toList();
  }
}
