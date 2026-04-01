package com.mvfitness.mytrainer2.dto;

import java.time.LocalDateTime;
import java.util.List;

public record ProgramTemplateDto(
        Long id,
        String name,
        String goal,
        String description,
        Integer totalDurationDays,
        List<ProgramMesocycleDto> mesocycles,
        List<ProgramAssignedClientDto> assignedClients,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) { }
