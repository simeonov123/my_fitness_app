// src/main/java/com/mvfitness/mytrainer2/mapper/ExerciseHasSetsMapper.java
package com.mvfitness.mytrainer2.mapper;

import com.mvfitness.mytrainer2.domain.ExerciseHasSets;
import com.mvfitness.mytrainer2.domain.WorkoutInstanceExerciseHasSets;
import com.mvfitness.mytrainer2.dto.ExerciseHasSetsDto;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

/** Static helpers – never instantiate. */
public final class ExerciseHasSetsMapper {

    private ExerciseHasSetsMapper() {}

    /* ───────── single row → DTO ───────── */
    public static ExerciseHasSetsDto toDto(ExerciseHasSets e) {
        return new ExerciseHasSetsDto(
                e.getId(),
                e.getSetNumber(),
                e.getSetData().stream()
                        .sorted(Comparator.comparing(com.mvfitness.mytrainer2.domain.SetData::getId))
                        .map(SetDataMapper::toDto)
                        .collect(Collectors.toList())
        );
    }

    /* ───────── template-level list ───────── */
    public static List<ExerciseHasSetsDto> toDtoList(List<ExerciseHasSets> list) {
        return list.stream()
                .sorted(Comparator.comparing(ExerciseHasSets::getSetNumber))
                .map(ExerciseHasSetsMapper::toDto)
                .toList();
    }

    /* ───────── instance-level list ─────────
       Different method name ⇒ no erasure clash */
    public static List<ExerciseHasSetsDto> toDtoListFromInstance(
            List<WorkoutInstanceExerciseHasSets> list) {

        return list.stream()
                .sorted(Comparator.comparing(WorkoutInstanceExerciseHasSets::getSetNumber))
                .map(e -> new ExerciseHasSetsDto(
                        e.getId(),
                        e.getSetNumber(),
                        e.getSetData().stream()
                                .sorted(Comparator.comparing(
                                        com.mvfitness.mytrainer2.domain.SetData::getId))
                                .map(SetDataMapper::toDto)
                                .collect(Collectors.toList())
                ))
                .toList();
    }
}
