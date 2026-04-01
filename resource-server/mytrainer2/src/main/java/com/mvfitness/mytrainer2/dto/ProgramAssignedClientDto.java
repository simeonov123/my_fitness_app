package com.mvfitness.mytrainer2.dto;

public record ProgramAssignedClientDto(
        Long clientId,
        String fullName,
        String email
) { }
