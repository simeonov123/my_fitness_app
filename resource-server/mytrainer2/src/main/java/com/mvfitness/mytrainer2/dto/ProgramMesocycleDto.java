package com.mvfitness.mytrainer2.dto;

public record ProgramMesocycleDto(
        Long id,
        String name,
        String goal,
        String description,
        Integer lengthInWeeks,
        Integer sequenceOrder,
        ProgramMicrocycleDto microcycle
) { }
