// src/main/java/com/mvfitness/mytrainer2/service/workout/WorkoutTemplateExerciseService.java
package com.mvfitness.mytrainer2.service.workout;

import com.mvfitness.mytrainer2.dto.WorkoutTemplateExerciseDto;

import java.util.List;

public interface WorkoutTemplateExerciseService {

    /** List all exercises for a given template */
    List<WorkoutTemplateExerciseDto> list(String keycloakUserId, Long templateId);

    /** Replace entire list for a template (delete old + insert new in one transaction) */
    List<WorkoutTemplateExerciseDto> replaceAll(
            String keycloakUserId,
            Long templateId,
            List<WorkoutTemplateExerciseDto> dtos
    );

    /** Remove a single exercise entry by its id (and return remaining list) */
    void deleteOne(String keycloakUserId, Long templateId, Long exerciseEntryId);
}
