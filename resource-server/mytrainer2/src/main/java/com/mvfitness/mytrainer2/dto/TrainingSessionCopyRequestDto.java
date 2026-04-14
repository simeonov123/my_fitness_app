package com.mvfitness.mytrainer2.dto;

import java.time.LocalDateTime;

public record TrainingSessionCopyRequestDto(
        LocalDateTime startTime,
        LocalDateTime endTime,
        String sessionName
) { }
