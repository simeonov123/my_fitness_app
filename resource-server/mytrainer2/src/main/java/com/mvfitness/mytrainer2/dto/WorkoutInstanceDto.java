package com.mvfitness.mytrainer2.dto;

import java.time.LocalDateTime;

public record WorkoutInstanceDto(
        Long id,
        Long trainingSessionId,
        Long clientId,
        Long workoutTemplateId,
        LocalDateTime performedAt,
        String notes
) {}
