// src/main/java/com/mvfitness/mytrainer2/dto/WorkoutTemplateDto.java
package com.mvfitness.mytrainer2.dto;

import java.time.LocalDateTime;
import java.util.List;

public record WorkoutTemplateDto(
        Long id,
        String name,
        String description,
        List<WorkoutTemplateExerciseDto> exercises,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) { }
