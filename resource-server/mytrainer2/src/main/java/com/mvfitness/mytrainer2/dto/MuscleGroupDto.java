package com.mvfitness.mytrainer2.dto;

import java.time.LocalDateTime;

public record MuscleGroupDto(
        Long id,
        String name,
        Boolean isCustom,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) { }
