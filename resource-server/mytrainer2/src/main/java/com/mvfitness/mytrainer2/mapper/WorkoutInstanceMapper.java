package com.mvfitness.mytrainer2.mapper;

import com.mvfitness.mytrainer2.domain.WorkoutInstance;
import com.mvfitness.mytrainer2.dto.WorkoutInstanceDto;

public final class WorkoutInstanceMapper {
    private WorkoutInstanceMapper() {}

    public static WorkoutInstanceDto toDto(WorkoutInstance wi) {
        return new WorkoutInstanceDto(
                wi.getId(),
                wi.getTrainingSession() != null ? wi.getTrainingSession().getId() : null,
                wi.getClient()           != null ? wi.getClient().getId()           : null,
                wi.getWorkoutTemplate()  != null ? wi.getWorkoutTemplate().getId()  : null,
                wi.getPerformedAt(),
                wi.getNotes()
        );
    }
}
