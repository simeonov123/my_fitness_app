package com.mvfitness.mytrainer2.dto;

import java.util.List;

public record TrainingSessionRealtimeEventDto(
        String type,
        Long sessionId,
        TrainingSessionDto session,
        List<WorkoutInstanceExerciseDto> instanceExercises
) {
}
