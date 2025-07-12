// src/main/java/com/mvfitness/mytrainer2/mapper/ExerciseMapper.java
package com.mvfitness.mytrainer2.mapper;

import com.mvfitness.mytrainer2.domain.Exercise;
import com.mvfitness.mytrainer2.dto.ExerciseDto;

public class ExerciseMapper {

    public static ExerciseDto toDto(Exercise e) {
        return new ExerciseDto(
                e.getId(),
                e.getName(),
                e.getDescription(),
                e.getIsCustom(),
                e.getDefaultSetType(),
                e.getDefaultSetParams(),
                e.getCreatedAt(),
                e.getUpdatedAt()
        );
    }

    /** Updates the mutable fields of an existing Exercise from the DTO. */
    public static void updateEntity(Exercise e, ExerciseDto dto) {
        e.setName(dto.name());
        e.setDescription(dto.description());
        e.setIsCustom(dto.isCustom());
        e.setDefaultSetType(dto.defaultSetType());
        e.setDefaultSetParams(dto.defaultSetParams());
    }
}
