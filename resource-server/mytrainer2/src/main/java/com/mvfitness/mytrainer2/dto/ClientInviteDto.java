package com.mvfitness.mytrainer2.dto;

import java.time.LocalDateTime;

public record ClientInviteDto(
        Long id,
        Long clientId,
        String clientName,
        String clientEmail,
        String status,
        String inviteToken,
        String inviteUrl,
        String webInviteUrl,
        LocalDateTime expiresAt,
        LocalDateTime acceptedAt,
        LocalDateTime createdAt
) {
}
