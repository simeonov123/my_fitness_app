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

  Future<ActiveWorkoutSnapshot?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;
    return ActiveWorkoutSnapshot.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> save(ActiveWorkoutSnapshot snapshot) {
    return _storage.write(key: _key, value: jsonEncode(snapshot.toJson()));
  }

  Future<void> clear() => _storage.delete(key: _key);
}
