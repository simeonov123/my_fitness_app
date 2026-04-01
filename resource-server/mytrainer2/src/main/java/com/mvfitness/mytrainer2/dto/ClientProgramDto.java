package com.mvfitness.mytrainer2.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public record ClientProgramDto(
        Long assignmentId,
        Long programId,
        String name,
        String goal,
        String description,
        LocalDate startDate,
        LocalDate endDate,
        Integer totalDays,
        Integer completedDays,
        String status,
        LocalDateTime assignedAt,
        List<ClientProgramDayDto> days
) { }
