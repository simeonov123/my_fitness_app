package com.mvfitness.mytrainer2.mapper;

import com.mvfitness.mytrainer2.domain.Client;
import com.mvfitness.mytrainer2.dto.ClientDto;

/** Tiny manual mapper (you can swap to MapStruct later). */
public final class ClientMapper {

    private ClientMapper() { }   // utility class

    public static ClientDto toDto(Client c) {
        return new ClientDto(
                c.getId(),
                c.getFullName(),
                c.getEmail(),
                c.getPhone(),
                c.getCreatedAt(),
                c.getUpdatedAt()
        );
    }

    public static void updateEntity(Client c, ClientDto dto) {
        c.setFullName(dto.fullName());
        c.setEmail(dto.email());
        c.setPhone(dto.phone());
    }
}
