// src/main/java/com/mvfitness/mytrainer2/dto/WorkoutInstanceExerciseDto.java
package com.mvfitness.mytrainer2.dto;

import java.util.List;

public record WorkoutInstanceExerciseDto(
        Long   id,
        Long   workoutInstanceId,
        Long   clientId,
        String clientName,
        Long   exerciseId,
        String exerciseName,
        Integer sequenceOrder,
        String setType,
        String setParams,
        Integer restSeconds,
        String notes,
        List<ExerciseHasSetsDto> sets        // ← reuse existing sub-DTO
) { }
