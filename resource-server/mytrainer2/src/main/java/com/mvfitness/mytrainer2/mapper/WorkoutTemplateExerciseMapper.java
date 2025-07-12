    package com.mvfitness.mytrainer2.mapper;

    import com.mvfitness.mytrainer2.domain.ExerciseHasSets;
    import com.mvfitness.mytrainer2.domain.WorkoutTemplateExercise;
    import com.mvfitness.mytrainer2.dto.WorkoutTemplateExerciseDto;
    import com.mvfitness.mytrainer2.dto.ExerciseHasSetsDto;
    import java.util.Comparator;
    import java.util.List;
    import java.util.stream.Collectors;

    public class WorkoutTemplateExerciseMapper {

        public static WorkoutTemplateExerciseDto toDto(WorkoutTemplateExercise e) {
            List<ExerciseHasSetsDto> sets = e.getExerciseHasSets().stream()
                    .sorted(Comparator.comparing(ExerciseHasSets::getSetNumber))
                    .map(ExerciseHasSetsMapper::toDto)
                    .collect(Collectors.toList());

            return new WorkoutTemplateExerciseDto(
                    e.getId(),
                    e.getExercise().getId(),
                    e.getExercise().getName(),
                    e.getExercise().getDefaultSetType(),
                    e.getExercise().getDefaultSetParams(),
                    e.getSequenceOrder(),
                    e.getSetType(),
                    e.getSetParams(),
                    e.getNotes(),
                    sets
            );
        }

        public static List<WorkoutTemplateExerciseDto> toDtoList(List<WorkoutTemplateExercise> all) {
            return all.stream()
                    .map(WorkoutTemplateExerciseMapper::toDto)
                    .collect(Collectors.toList());
        }

        public static void updateEntity(
                WorkoutTemplateExercise ent,
                WorkoutTemplateExerciseDto dto,
                com.mvfitness.mytrainer2.domain.WorkoutTemplate tpl,
                com.mvfitness.mytrainer2.domain.Exercise ex
        ) {
            ent.setWorkoutTemplate(tpl);
            ent.setExercise(ex);
            ent.setSequenceOrder(dto.sequenceOrder());
            ent.setSetType(dto.setType());
            ent.setSetParams(dto.setParams());
            ent.setNotes(dto.notes());

            // sync template-level sets
            ent.getExerciseHasSets().clear();
            if (dto.sets() != null) {
                dto.sets().forEach(sDto -> {
                    var ehs = ExerciseHasSets.builder()
                            .workoutExercise(ent)
                            .setNumber(sDto.setNumber())
                            .build();
                    sDto.data().forEach(sdDto -> {
                        var sd = com.mvfitness.mytrainer2.domain.SetData.builder()
                                .type(sdDto.type())
                                .value(sdDto.value())
                                .build();
                        ehs.addSetData(sd);
                    });
                    ent.getExerciseHasSets().add(ehs);
                });
            }
        }
    }
