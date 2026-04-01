package com.mvfitness.mytrainer2.dto;

import java.time.LocalDate;
import java.util.List;

public record ProgramAssignmentRequestDto(
        List<Long> clientIds,
        LocalDate startDate
) { }
