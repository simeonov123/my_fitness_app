class ProgramMicrocycleDay {
  final int dayIndex;
  final bool restDay;
  final int? workoutTemplateId;
  final String? workoutTemplateName;
  final String? notes;

  const ProgramMicrocycleDay({
    required this.dayIndex,
    required this.restDay,
    this.workoutTemplateId,
    this.workoutTemplateName,
    this.notes,
  });

  factory ProgramMicrocycleDay.fromJson(Map<String, dynamic> json) {
    return ProgramMicrocycleDay(
      dayIndex: (json['dayIndex'] as num).toInt(),
      restDay: json['restDay'] as bool? ?? false,
      workoutTemplateId: (json['workoutTemplateId'] as num?)?.toInt(),
      workoutTemplateName: json['workoutTemplateName'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'dayIndex': dayIndex,
        'restDay': restDay,
        'workoutTemplateId': workoutTemplateId,
        'workoutTemplateName': workoutTemplateName,
        'notes': notes,
      };
}

class ProgramMicrocycle {
  final int id;
  final String name;
  final String? goal;
  final String? description;
  final int lengthInDays;
  final int sequenceOrder;
  final List<ProgramMicrocycleDay> days;

  const ProgramMicrocycle({
    required this.id,
    required this.name,
    this.goal,
    this.description,
    required this.lengthInDays,
    required this.sequenceOrder,
    required this.days,
  });

  factory ProgramMicrocycle.fromJson(Map<String, dynamic> json) {
    return ProgramMicrocycle(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      goal: json['goal'] as String?,
      description: json['description'] as String?,
      lengthInDays: (json['lengthInDays'] as num?)?.toInt() ?? 0,
      sequenceOrder: (json['sequenceOrder'] as num?)?.toInt() ?? 1,
      days: (json['days'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ProgramMicrocycleDay.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id == 0 ? null : id,
        'name': name,
        'goal': goal,
        'description': description,
        'lengthInDays': lengthInDays,
        'sequenceOrder': sequenceOrder,
        'days': days.map((e) => e.toJson()).toList(),
      };
}

class ProgramMesocycle {
  final int id;
  final String name;
  final String? goal;
  final String? description;
  final int lengthInWeeks;
  final int sequenceOrder;
  final ProgramMicrocycle microcycle;

  const ProgramMesocycle({
    required this.id,
    required this.name,
    this.goal,
    this.description,
    required this.lengthInWeeks,
    required this.sequenceOrder,
    required this.microcycle,
  });

  factory ProgramMesocycle.fromJson(Map<String, dynamic> json) {
    return ProgramMesocycle(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      goal: json['goal'] as String?,
      description: json['description'] as String?,
      lengthInWeeks: (json['lengthInWeeks'] as num?)?.toInt() ?? 1,
      sequenceOrder: (json['sequenceOrder'] as num?)?.toInt() ?? 1,
      microcycle: ProgramMicrocycle.fromJson(
        (json['microcycle'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id == 0 ? null : id,
        'name': name,
        'goal': goal,
        'description': description,
        'lengthInWeeks': lengthInWeeks,
        'sequenceOrder': sequenceOrder,
        'microcycle': microcycle.toJson(),
      };
}

class ProgramTemplateModel {
  final int id;
  final String name;
  final String? goal;
  final String? description;
  final int totalDurationDays;
  final List<ProgramMesocycle> mesocycles;
  final List<ProgramAssignedClient> assignedClients;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProgramTemplateModel({
    required this.id,
    required this.name,
    this.goal,
    this.description,
    required this.totalDurationDays,
    required this.mesocycles,
    required this.assignedClients,
    this.createdAt,
    this.updatedAt,
  });

  factory ProgramTemplateModel.fromJson(Map<String, dynamic> json) {
    return ProgramTemplateModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      goal: json['goal'] as String?,
      description: json['description'] as String?,
      totalDurationDays: (json['totalDurationDays'] as num?)?.toInt() ?? 0,
      mesocycles: (json['mesocycles'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ProgramMesocycle.fromJson)
          .toList(),
      assignedClients: (json['assignedClients'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ProgramAssignedClient.fromJson)
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id == 0 ? null : id,
        'name': name,
        'goal': goal,
        'description': description,
        'totalDurationDays': totalDurationDays,
        'mesocycles': mesocycles.map((e) => e.toJson()).toList(),
        'assignedClients': assignedClients.map((e) => e.toJson()).toList(),
      };
}

class ProgramAssignedClient {
  final int clientId;
  final String? fullName;
  final String? email;

  const ProgramAssignedClient({
    required this.clientId,
    this.fullName,
    this.email,
  });

  factory ProgramAssignedClient.fromJson(Map<String, dynamic> json) {
    return ProgramAssignedClient(
      clientId: (json['clientId'] as num?)?.toInt() ?? 0,
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'fullName': fullName,
        'email': email,
      };
}

class ClientProgramDay {
  final int dayIndex;
  final String label;
  final bool restDay;
  final int? trainingSessionId;
  final int? workoutTemplateId;
  final String? workoutName;
  final bool completed;

  const ClientProgramDay({
    required this.dayIndex,
    required this.label,
    required this.restDay,
    this.trainingSessionId,
    this.workoutTemplateId,
    this.workoutName,
    required this.completed,
  });

  factory ClientProgramDay.fromJson(Map<String, dynamic> json) {
    return ClientProgramDay(
      dayIndex: (json['dayIndex'] as num).toInt(),
      label: json['label'] as String? ?? '',
      restDay: json['restDay'] as bool? ?? false,
      trainingSessionId: (json['trainingSessionId'] as num?)?.toInt(),
      workoutTemplateId: (json['workoutTemplateId'] as num?)?.toInt(),
      workoutName: json['workoutName'] as String?,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class ClientProgram {
  final int assignmentId;
  final int programId;
  final String name;
  final String? goal;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final int completedDays;
  final String? status;
  final DateTime? assignedAt;
  final List<ClientProgramDay> days;

  const ClientProgram({
    required this.assignmentId,
    required this.programId,
    required this.name,
    this.goal,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.completedDays,
    this.status,
    this.assignedAt,
    required this.days,
  });

  factory ClientProgram.fromJson(Map<String, dynamic> json) {
    return ClientProgram(
      assignmentId: (json['assignmentId'] as num).toInt(),
      programId: (json['programId'] as num).toInt(),
      name: json['name'] as String? ?? '',
      goal: json['goal'] as String?,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalDays: (json['totalDays'] as num?)?.toInt() ?? 0,
      completedDays: (json['completedDays'] as num?)?.toInt() ?? 0,
      status: json['status'] as String?,
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'] as String)
          : null,
      days: (json['days'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ClientProgramDay.fromJson)
          .toList(),
    );
  }
}
