package com.mvfitness.mytrainer2.dto;

import java.util.List;

public record WorkoutTemplateExerciseDto(
        Long id,
        Long exerciseId,
        String exerciseName,
        String exerciseDefaultSetType,
        String exerciseDefaultSetParams,
        Integer sequenceOrder,
        String setType,
        String setParams,
        String notes,
        List<ExerciseHasSetsDto> sets
) {}
