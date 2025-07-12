// TrainingSessionResponse.java
package com.mvfitness.mytrainer2.dto;

import java.time.LocalDateTime;
import java.util.List;

public record TrainingSessionResponse(
        Long id,
        Long trainerId,
        List<Long> clientIds,
        LocalDateTime scheduledDate,
        Integer dayIndexInCycle,
        String sessionName,
        String sessionDescription,
        String sessionType,
        String status,
        Boolean isCompleted
) {}
