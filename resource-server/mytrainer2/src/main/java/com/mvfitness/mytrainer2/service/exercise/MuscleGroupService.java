package com.mvfitness.mytrainer2.service.exercise;

import com.mvfitness.mytrainer2.dto.MuscleGroupDto;

import java.util.List;

public interface MuscleGroupService {
    List<MuscleGroupDto> list(String kcUserId);
    MuscleGroupDto create(String kcUserId, MuscleGroupDto dto);
    MuscleGroupDto update(String kcUserId, Long id, MuscleGroupDto dto);
    void delete(String kcUserId, Long id);
}
