package com.mvfitness.mytrainer2.mapper;

import com.mvfitness.mytrainer2.domain.SetData;
import com.mvfitness.mytrainer2.domain.WorkoutInstance;
import com.mvfitness.mytrainer2.domain.WorkoutInstanceExercise;
import com.mvfitness.mytrainer2.domain.WorkoutInstanceExerciseHasSets;
import com.mvfitness.mytrainer2.dto.ExerciseHasSetsDto;
import com.mvfitness.mytrainer2.dto.SetDataDto;
import com.mvfitness.mytrainer2.dto.WorkoutInstanceExerciseDto;

import java.util.Comparator;
import java.util.List;
import java.util.Objects;

/**
 * Maps {@link WorkoutInstanceExercise} ⇆ {@link WorkoutInstanceExerciseDto}.
 *
 * Deep-copies the entire set hierarchy so that edits made on the client
 * (add / delete sets, change values) persist correctly.
 */
public final class WorkoutInstanceExerciseMapper {

    private WorkoutInstanceExerciseMapper() {}

    /* ───────────────────  ENTITY ➜ DTO  ─────────────────── */

    public static WorkoutInstanceExerciseDto toDto(WorkoutInstanceExercise e) {
        return new WorkoutInstanceExerciseDto(
                e.getId(),
                e.getWorkoutInstance().getId(),
                e.getExercise().getId(),
                e.getExercise().getName(),
                e.getSequenceOrder(),
                e.getSetType(),
                e.getSetParams(),
                e.getNotes(),
                // instance-specific helper keeps ordering / set-data
                ExerciseHasSetsMapper.toDtoListFromInstance(
                        e.getWorkoutInstanceExerciseHasSets())
        );
    }

    public static List<WorkoutInstanceExerciseDto> toDtoList(
            List<WorkoutInstanceExercise> list) {
        return list.stream().map(WorkoutInstanceExerciseMapper::toDto).toList();
    }

    /* ───────────────────  DTO ➜ ENTITY  ─────────────────── */

    /**
     * Builds a new {@link WorkoutInstanceExercise} —
     * including <strong>all</strong> nested sets &amp; set-data.
     *
     * The caller (service layer) still has to inject the proper
     * {@code exercise} reference before saving.
     */
    public static WorkoutInstanceExercise toEntity(
            WorkoutInstanceExerciseDto d,
            WorkoutInstance            parent
    ) {

        // root row
        WorkoutInstanceExercise e = WorkoutInstanceExercise.builder()
                .workoutInstance(parent)
                .sequenceOrder(d.sequenceOrder())
                .setType(d.setType())
                .setParams(d.setParams())
                .notes(d.notes())
                .build();

        /* ── deep-copy sets ── */
        if (d.sets() != null && !d.sets().isEmpty()) {
            for (ExerciseHasSetsDto sDto : d.sets()) {

                WorkoutInstanceExerciseHasSets has =
                        WorkoutInstanceExerciseHasSets.builder()
                                .workoutInstanceExercise(e)
                                .setNumber(sDto.setNumber())
                                .build();

                // copy per-set data
                if (sDto.data() != null) {
                    for (SetDataDto sd : sDto.data()) {
                        has.addSetData(SetData.builder()
                                .type(sd.type())
                                .value(sd.value())
                                .build());
                    }
                }
                e.getWorkoutInstanceExerciseHasSets().add(has);
            }

            // keep natural ordering just in case
            e.getWorkoutInstanceExerciseHasSets()
                    .sort(Comparator.comparingInt(
                            WorkoutInstanceExerciseHasSets::getSetNumber));
        }

        return e;
    }

    /* ───────────────────  PATCH (scalars only)  ─────────────────── */

    public static void updateEntity(
            WorkoutInstanceExercise target,
            WorkoutInstanceExerciseDto src) {

        Objects.requireNonNull(target, "target entity is null");
        Objects.requireNonNull(src,    "source dto is null");

        target.setSequenceOrder(src.sequenceOrder());
        target.setSetType(src.setType());
        target.setSetParams(src.setParams());
        target.setNotes(src.notes());
        // sets are not patched here — full replaceAll is used for that path
    }
}
