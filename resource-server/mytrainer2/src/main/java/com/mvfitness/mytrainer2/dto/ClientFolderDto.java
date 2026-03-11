package com.mvfitness.mytrainer2.dto;

import java.time.LocalDateTime;

public record ClientFolderDto(
        Long id,
        String name,
        Integer sequenceOrder,
        Long clientCount,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) { }
