package com.mvfitness.mytrainer2.dto;

import java.util.List;

public record ExerciseHistoryDto(
        Long clientId,
        String clientName,
        Long exerciseId,
        String exerciseName,
        String setType,
        String setParams,
        ExerciseHistorySummaryDto summary,
        List<ExerciseHistorySnapshotDto> snapshots
) {}
