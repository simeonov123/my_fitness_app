package com.mvfitness.mytrainer2.mapper;

import com.mvfitness.mytrainer2.domain.ClientFolder;
import com.mvfitness.mytrainer2.dto.ClientFolderDto;

public final class ClientFolderMapper {
    private ClientFolderMapper() { }

    public static ClientFolderDto toDto(ClientFolder folder) {
        return new ClientFolderDto(
                folder.getId(),
                folder.getName(),
                folder.getSequenceOrder(),
                folder.getClients() == null ? 0L : (long) folder.getClients().size(),
                folder.getCreatedAt(),
                folder.getUpdatedAt()
        );
    }
}
