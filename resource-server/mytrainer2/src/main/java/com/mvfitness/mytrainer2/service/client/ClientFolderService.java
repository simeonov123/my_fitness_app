package com.mvfitness.mytrainer2.service.client;

import com.mvfitness.mytrainer2.dto.ClientFolderDto;

import java.util.List;

public interface ClientFolderService {
    List<ClientFolderDto> list(String kcUserId);
    ClientFolderDto create(String kcUserId, ClientFolderDto dto);
    ClientFolderDto update(String kcUserId, Long id, ClientFolderDto dto);
    void delete(String kcUserId, Long id);
}
