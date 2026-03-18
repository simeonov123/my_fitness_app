package com.mvfitness.mytrainer2.dto;

import java.util.List;

public record ExerciseHistorySummaryDto(
        Double averageBestRepsPerSet,
        Double estimatedOneRepMax,
        Double bestSetVolume,
        Double bestWeight,
        Double bestDurationSeconds,
        Double bestDistanceKm,
        Double fastestPaceSecondsPerKm,
        List<String> supportedMetrics
) {}
