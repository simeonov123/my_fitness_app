// src/main/java/com/mvfitness/mytrainer2/dto/WorkoutInstanceExerciseDto.java
package com.mvfitness.mytrainer2.dto;

import java.util.List;

public record WorkoutInstanceExerciseDto(
        Long   id,
        Long   workoutInstanceId,
        Long   exerciseId,
        String exerciseName,
        Integer sequenceOrder,
        String setType,
        String setParams,
        String notes,
        List<ExerciseHasSetsDto> sets        // ← reuse existing sub-DTO
) { }
