    // src/main/java/com/mvfitness/mytrainer2/dto/ExerciseDto.java
    package com.mvfitness.mytrainer2.dto;

    import java.time.LocalDateTime;
    import java.util.List;

    public record ExerciseDto(
            Long id,
            String name,
            String description,
            Boolean isCustom,
            String defaultSetType,
            String defaultSetParams,
            List<MuscleGroupDto> muscleGroups,
            LocalDateTime createdAt,
            LocalDateTime updatedAt
    ) { }
