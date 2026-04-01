package com.mvfitness.mytrainer2.dto;

public record ProgramDayAssignmentDto(
        Integer dayIndex,
        Long workoutTemplateId,
        String workoutTemplateName,
        String notes
) { }
