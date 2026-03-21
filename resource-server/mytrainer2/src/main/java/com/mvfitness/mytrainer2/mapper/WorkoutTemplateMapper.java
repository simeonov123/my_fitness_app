// src/main/java/com/mvfitness/mytrainer2/mapper/WorkoutTemplateMapper.java
package com.mvfitness.mytrainer2.mapper;

import com.mvfitness.mytrainer2.domain.*;
import com.mvfitness.mytrainer2.dto.*;

import java.util.ArrayList;
import java.util.List;

public final class WorkoutTemplateMapper {
    private WorkoutTemplateMapper() { }

    public static WorkoutTemplateDto toDto(WorkoutTemplate t) {
        List<WorkoutTemplateExerciseDto> list = t.getWorkoutTemplateExercises()
                .stream()
                .map(WorkoutTemplateExerciseMapper::toDto)
                .toList();

        return new WorkoutTemplateDto(
                t.getId(),
                t.getName(),
                t.getDescription(),
                t.getFolder() == null ? null : t.getFolder().getId(),
                t.getFolder() == null ? null : t.getFolder().getName(),
                t.getSequenceOrder(),
                list,
                t.getCreatedAt(),
                t.getUpdatedAt()
        );
    }

    public static void updateEntity(
            WorkoutTemplate t,
            WorkoutTemplateDto d,
            WorkoutFolder folder,
            List<Exercise> exerciseRefs
    ) {
        t.setName(d.name());
        t.setDescription(d.description());
        t.setFolder(folder);
        t.setSequenceOrder(d.sequenceOrder());

        if (t.getWorkoutTemplateExercises() == null)
            t.setWorkoutTemplateExercises(new ArrayList<>());
        else
            t.getWorkoutTemplateExercises().clear();

        if (d.exercises() != null) {
            for (WorkoutTemplateExerciseDto exDto : d.exercises()) {
                Exercise exRef = exerciseRefs.stream()
                        .filter(e -> e.getId().equals(exDto.exerciseId()))
                        .findFirst()
                        .orElseThrow(() -> new IllegalArgumentException("Exercise id "+exDto.exerciseId()+" not found"));

                WorkoutTemplateExercise wte = WorkoutTemplateExercise.builder()
                        .workoutTemplate(t)
                        .exercise(exRef)
                        .sequenceOrder(exDto.sequenceOrder())
                        .setType(exDto.setType())
                        .setParams(exDto.setParams())
                        .restSeconds(exDto.restSeconds())
                        .notes(exDto.notes())
                        .build();
                t.getWorkoutTemplateExercises().add(wte);
            }
        }
    }
}
