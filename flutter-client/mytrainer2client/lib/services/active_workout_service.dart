import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ActiveWorkoutSnapshot {
  final int sessionId;
  final String sessionName;
  final DateTime startedAt;

  const ActiveWorkoutSnapshot({
    required this.sessionId,
    required this.sessionName,
    required this.startedAt,
  });

  factory ActiveWorkoutSnapshot.fromJson(Map<String, dynamic> json) =>
      ActiveWorkoutSnapshot(
        sessionId: (json['sessionId'] as num).toInt(),
        sessionName: json['sessionName'] as String? ?? '',
        startedAt: DateTime.parse(json['startedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'sessionName': sessionName,
        'startedAt': startedAt.toIso8601String(),
      };
}

class ActiveWorkoutService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'active_workout_snapshot';

  Future<Map<int, ActiveWorkoutSnapshot>> loadAll() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic> && decoded['sessionId'] != null) {
      final legacy = ActiveWorkoutSnapshot.fromJson(decoded);
      return {legacy.sessionId: legacy};
    }
    if (decoded is! Map<String, dynamic>) return {};
    return decoded.map((key, value) {
      final sessionId = int.tryParse(key) ?? 0;
      return MapEntry(
        sessionId,
        ActiveWorkoutSnapshot.fromJson(value as Map<String, dynamic>),
      );
    })..remove(0);
  }

  Future<ActiveWorkoutSnapshot?> load(int sessionId) async =>
      (await loadAll())[sessionId];

  Future<void> save(ActiveWorkoutSnapshot snapshot) {
    return _writeAllWith(snapshot);
  }

  Future<void> _writeAllWith(ActiveWorkoutSnapshot snapshot) async {
    final all = await loadAll();
    all[snapshot.sessionId] = snapshot;
    await _storage.write(
      key: _key,
      value: jsonEncode(
        all.map((key, value) => MapEntry(key.toString(), value.toJson())),
      ),
    );
  }

  Future<void> clear(int sessionId) async {
    final all = await loadAll();
    all.remove(sessionId);
    if (all.isEmpty) {
      await _storage.delete(key: _key);
      return;
    }
    await _storage.write(
      key: _key,
      value: jsonEncode(
        all.map((key, value) => MapEntry(key.toString(), value.toJson())),
      ),
    );
  }

  Future<void> clearAll() => _storage.delete(key: _key);
}
