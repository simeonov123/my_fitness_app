package com.mvfitness.mytrainer2.dto;

import java.util.List;

public record ProgramMicrocycleDto(
        Long id,
        String name,
        String goal,
        String description,
        Integer lengthInDays,
        Integer sequenceOrder,
        List<ProgramMicrocycleDayDto> days
) { }
