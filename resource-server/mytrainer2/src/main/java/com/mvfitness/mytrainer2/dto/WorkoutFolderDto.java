package com.mvfitness.mytrainer2.dto;

import java.time.LocalDateTime;

public record WorkoutFolderDto(
        Long id,
        String name,
        Integer sequenceOrder,
        Long workoutCount,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) { }
