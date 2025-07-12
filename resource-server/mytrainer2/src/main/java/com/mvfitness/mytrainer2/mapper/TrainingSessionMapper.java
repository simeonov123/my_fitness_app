package com.mvfitness.mytrainer2.mapper;

import com.mvfitness.mytrainer2.domain.TrainingSession;
import com.mvfitness.mytrainer2.dto.TrainingSessionDto;

import java.util.stream.Collectors;

/** Static helpers → no Spring bean necessary */
public final class TrainingSessionMapper {

    private TrainingSessionMapper() { }

    public static TrainingSessionDto toDto(TrainingSession t) {
        return new TrainingSessionDto(
                t.getId(),
                t.getStartTime(),
                t.getEndTime(),
                t.getDayIndexInCycle(),
                t.getSessionName(),
                t.getSessionDescription(),
                t.getSessionType(),
                t.getTrainerNotes(),
                t.getStatus(),
                t.getIsCompleted(),
                t.getClients()
                        .stream()
                        .map(c -> c.getId())
                        .collect(Collectors.toList()),
                (t.getWorkoutTemplate() != null)
                        ? t.getWorkoutTemplate().getId()
                        : null
        );
    }
}
