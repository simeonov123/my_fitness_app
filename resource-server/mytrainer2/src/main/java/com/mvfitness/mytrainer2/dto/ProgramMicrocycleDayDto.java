package com.mvfitness.mytrainer2.dto;

public record ProgramMicrocycleDayDto(
        Integer dayIndex,
        Boolean restDay,
        Long workoutTemplateId,
        String workoutTemplateName,
        String notes
) { }
