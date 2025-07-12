    // src/main/java/com/mvfitness/mytrainer2/dto/ExerciseDto.java
    package com.mvfitness.mytrainer2.dto;

    import java.time.LocalDateTime;

    public record ExerciseDto(
            Long id,
            String name,
            String description,
            Boolean isCustom,
            String defaultSetType,
            String defaultSetParams,
            LocalDateTime createdAt,
            LocalDateTime updatedAt
    ) { }
