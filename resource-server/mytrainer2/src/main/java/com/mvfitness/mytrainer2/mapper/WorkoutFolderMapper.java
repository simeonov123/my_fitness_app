package com.mvfitness.mytrainer2.mapper;

import com.mvfitness.mytrainer2.domain.WorkoutFolder;
import com.mvfitness.mytrainer2.dto.WorkoutFolderDto;

public final class WorkoutFolderMapper {
    private WorkoutFolderMapper() { }

    public static WorkoutFolderDto toDto(WorkoutFolder folder) {
        return new WorkoutFolderDto(
                folder.getId(),
                folder.getName(),
                folder.getSequenceOrder(),
                folder.getWorkoutTemplates() == null ? 0L : (long) folder.getWorkoutTemplates().size(),
                folder.getCreatedAt(),
                folder.getUpdatedAt()
        );
    }
}
