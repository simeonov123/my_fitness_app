package com.mvfitness.mytrainer2.dto;

import java.time.LocalDateTime;
import java.util.List;

public record ExerciseHistorySnapshotDto(
        Long sessionId,
        String sessionName,
        LocalDateTime sessionStart,
        Long workoutInstanceId,
        Long workoutInstanceExerciseId,
        String setType,
        String setParams,
        Integer completedSetCount,
        Integer totalSetCount,
        Double bestReps,
        Double estimatedOneRepMax,
        Double bestSetVolume,
        Double bestWeight,
        Double bestDurationSeconds,
        Double bestDistanceKm,
        List<ExerciseHasSetsDto> sets
) {}
