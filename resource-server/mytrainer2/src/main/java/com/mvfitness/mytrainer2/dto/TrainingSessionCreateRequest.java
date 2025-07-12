// TrainingSessionCreateRequest.java
package com.mvfitness.mytrainer2.dto;

import org.jetbrains.annotations.NotNull;

import java.time.LocalDateTime;
import java.util.List;

public record TrainingSessionCreateRequest(
        @NotNull Long trainerId,
        List<Long> clientIds,
        LocalDateTime scheduledDate,
        Integer dayIndexInCycle,
        String sessionName,
        String sessionDescription,
        String sessionType
) {}
