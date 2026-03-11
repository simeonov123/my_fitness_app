package com.mvfitness.mytrainer2.dto;

import java.time.LocalDateTime;

/** Plain DTO sent to / received from the front‑end */
public record ClientDto(
        Long id,
        String fullName,
        String email,
        String phone,
        Long folderId,
        String folderName,
        Integer sequenceOrder,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) { }
