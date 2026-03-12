package com.mvfitness.mytrainer2.dto;

public record ClientInviteValidationDto(
        boolean valid,
        String status,
        String trainerName,
        Long clientId,
        String clientName,
        String clientEmail,
        boolean alreadyAccepted
) {
}
