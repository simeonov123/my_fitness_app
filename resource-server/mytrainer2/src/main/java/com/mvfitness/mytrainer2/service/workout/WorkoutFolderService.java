package com.mvfitness.mytrainer2.service.workout;

import com.mvfitness.mytrainer2.dto.WorkoutFolderDto;

import java.util.List;

public interface WorkoutFolderService {
    List<WorkoutFolderDto> list(String kcUserId);
    WorkoutFolderDto create(String kcUserId, WorkoutFolderDto dto);
    WorkoutFolderDto update(String kcUserId, Long id, WorkoutFolderDto dto);
    void delete(String kcUserId, Long id);
}
