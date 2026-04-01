package com.mvfitness.mytrainer2.dto;

public record ClientProgramDayDto(
        Integer dayIndex,
        String label,
        Boolean restDay,
        Long trainingSessionId,
        Long workoutTemplateId,
        String workoutName,
        Boolean completed
) { }
