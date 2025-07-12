package com.mvfitness.mytrainer2.dto;

import java.time.LocalDateTime;
import java.util.List;

/**
 * A flat DTO that the controller exposes.
 * Jackson uses the field names, so the constructor order does not matter.
 */
public record TrainingSessionDto(
        Long               id,
        LocalDateTime startTime,
          LocalDateTime endTime,
        Integer            dayIndexInCycle,
        String             sessionName,
        String             sessionDescription,
        String             sessionType,
        String             trainerNotes,
        String             status,
        Boolean            isCompleted,
        List<Long>         clientIds,
        Long               workoutTemplateId
) { }
