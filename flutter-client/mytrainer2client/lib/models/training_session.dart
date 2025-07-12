// lib/models/training_session.dart
import 'dart:convert';

/// Mirrors the Spring `TrainingSessionDto`.
class TrainingSession {
  final int          id;
  final DateTime     startTime;
  final DateTime     endTime;
  final int?         dayIndexInCycle;
  final String?      sessionName;
  final String?      sessionDescription;
  final String?      sessionType;
  final String?      trainerNotes;
  final String?      status;
  final bool?        isCompleted;
  final List<int>    clientIds;
  final int?         workoutTemplateId;

  /* helpers for timeline / calendar */
  DateTime get start => startTime;
  DateTime get end   => endTime;
  int get durationMinutes => end.difference(start).inMinutes;

  const TrainingSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.dayIndexInCycle,
    this.sessionName,
    this.sessionDescription,
    this.sessionType,
    this.trainerNotes,
    this.status,
    this.isCompleted,
    required this.clientIds,
    this.workoutTemplateId,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> j) => TrainingSession(
    id              : (j['id'] as num).toInt(),
    startTime       : DateTime.parse(j['startTime'] as String),
    endTime         : DateTime.parse(j['endTime']   as String),
    dayIndexInCycle : j['dayIndexInCycle'] as int?,
    sessionName     : j['sessionName'] as String?,
    sessionDescription : j['sessionDescription'] as String?,
    sessionType     : j['sessionType'] as String?,
    trainerNotes    : j['trainerNotes'] as String?,
    status          : j['status'] as String?,
    isCompleted     : j['isCompleted'] as bool?,
    clientIds       : (j['clientIds'] as List<dynamic>? ?? [])
        .cast<num>().map((e) => e.toInt()).toList(),
    workoutTemplateId:
    (j['workoutTemplateId'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id'              : id,
    'startTime'       : startTime.toIso8601String(),
    'endTime'         : endTime .toIso8601String(),
    'dayIndexInCycle' : dayIndexInCycle,
    'sessionName'     : sessionName,
    'sessionDescription': sessionDescription,
    'sessionType'     : sessionType,
    'trainerNotes'    : trainerNotes,
    'status'          : status,
    'isCompleted'     : isCompleted,
    'clientIds'       : clientIds,
    'workoutTemplateId': workoutTemplateId,
  };

  @override
  String toString() => jsonEncode(toJson());
}
