// src/main/java/com/mvfitness/mytrainer2/service/workout/WorkoutInstanceExerciseService.java
package com.mvfitness.mytrainer2.service.workout;

import com.mvfitness.mytrainer2.dto.WorkoutInstanceExerciseDto;

import java.util.List;

public interface WorkoutInstanceExerciseService {

    List<WorkoutInstanceExerciseDto> list(String kcUserId, Long sessionId);

    List<WorkoutInstanceExerciseDto> replaceAll(
            String kcUserId,
            Long sessionId,
            List<WorkoutInstanceExerciseDto> dtos
    );

    void deleteOne(String kcUserId, Long sessionId, Long exerciseEntryId);
}
