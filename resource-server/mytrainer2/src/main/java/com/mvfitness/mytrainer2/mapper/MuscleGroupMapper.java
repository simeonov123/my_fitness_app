package com.mvfitness.mytrainer2.mapper;

import com.mvfitness.mytrainer2.domain.MuscleGroup;
import com.mvfitness.mytrainer2.dto.MuscleGroupDto;

public final class MuscleGroupMapper {

    private MuscleGroupMapper() {}

    public static MuscleGroupDto toDto(MuscleGroup group) {
        return new MuscleGroupDto(
                group.getId(),
                group.getName(),
                group.getIsCustom(),
                group.getCreatedAt(),
                group.getUpdatedAt()
        );
    }
}
