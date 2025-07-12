// src/main/java/com/mvfitness/mytrainer2/service/client/ClientService.java
package com.mvfitness.mytrainer2.service.client;

import com.mvfitness.mytrainer2.dto.ClientDto;
import org.springframework.data.domain.Page;

public interface ClientService {
    Page<ClientDto> list(String kcUserId, String q, int page, int size, String sort);

    ClientDto get(String kcUserId, Long clientId);

    ClientDto create(String kcUserId, ClientDto dto);

    ClientDto update(String kcUserId, Long clientId, ClientDto dto);

    void delete(String kcUserId, Long clientId);
}
