// src/main/java/com/mvfitness/mytrainer2/service/client/ClientServiceImpl.java
package com.mvfitness.mytrainer2.service.client;

import com.mvfitness.mytrainer2.domain.Client;
import com.mvfitness.mytrainer2.domain.ClientFolder;
import com.mvfitness.mytrainer2.domain.User;
import com.mvfitness.mytrainer2.dto.ClientDto;
import com.mvfitness.mytrainer2.mapper.ClientMapper;
import com.mvfitness.mytrainer2.repository.ClientRepository;
import com.mvfitness.mytrainer2.repository.ClientFolderRepository;
import com.mvfitness.mytrainer2.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.jdbc.core.metadata.HsqlTableMetaDataProvider;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class ClientServiceImpl implements ClientService {

    private final ClientRepository repo;
    private final ClientFolderRepository folders;
    private final UserRepository   users;

    // ───────────── helpers ──────────────────────────────────────────
    private User trainerOr404(String kcUserId) {
        User u = users.findByKeycloakUserId(kcUserId);
        if (u == null)
            throw new IllegalArgumentException("Trainer not found for KC id: " + kcUserId);
        return u;
    }

    private Client ownedClientOr404(String kcUserId, Long clientId) {
        User trainer = trainerOr404(kcUserId);

        Client client = repo.findById(clientId)
                .orElseThrow(() -> new IllegalArgumentException("Client not found or not yours"));

        if (!trainer.getId().equals(trainer.getId()))
            throw new IllegalArgumentException("Client not found or not yours");

        return  client;
    }

    private ClientFolder folderOr404(User trainer, Long folderId) {
        ClientFolder folder = folders.findById(folderId)
                .orElseThrow(() -> new IllegalArgumentException("Client folder not found"));
        if (!folder.getUser().getId().equals(trainer.getId()))
            throw new IllegalArgumentException("Client folder not found");
        return folder;
    }
    // ───────────────────────────────────────────────────────────────

    @Override @Transactional(readOnly = true)
    public Page<ClientDto> list(String kcUserId, String q, int page, int size, String sort) {
        Sort order = switch (sort) {
            case "name"      -> Sort.by("fullName").ascending();
            case "name_desc" -> Sort.by("fullName").descending();
            case "oldest"    -> Sort.by("createdAt").ascending();
            default          -> Sort.by("createdAt").descending();   // newest
        };

        User trainer = trainerOr404(kcUserId);
        Page<Client> p = repo.findByUserAndFullNameContainingIgnoreCase(
                trainer,
                q == null ? "" : q,
                PageRequest.of(page, size, order)
        );
        return p.map(ClientMapper::toDto);
    }

    @Override @Transactional(readOnly = true)
    public ClientDto get(String kcUserId, Long clientId) {
        return ClientMapper.toDto(ownedClientOr404(kcUserId, clientId));
    }

    @Override
    public ClientDto create(String kcUserId, ClientDto dto) {
        User trainer = trainerOr404(kcUserId);
        ClientFolder folder = dto.folderId() == null ? null : folderOr404(trainer, dto.folderId());
        Client c = Client.builder()
                .user(trainer)
                .fullName(dto.fullName())
                .email(dto.email())
                .phone(dto.phone())
                .folder(folder)
                .sequenceOrder(dto.sequenceOrder())
                .build();
        return ClientMapper.toDto(repo.save(c));
    }

    @Override
    public ClientDto update(String kcUserId, Long clientId, ClientDto dto) {
        Client c = ownedClientOr404(kcUserId, clientId);
        User trainer = trainerOr404(kcUserId);
        ClientFolder folder = dto.folderId() == null ? null : folderOr404(trainer, dto.folderId());
        ClientMapper.updateEntity(c, dto);
        c.setFolder(folder);
        return ClientMapper.toDto(repo.save(c));
    }

    @Override
    public void delete(String kcUserId, Long clientId) {
        try{

            repo.delete(ownedClientOr404(kcUserId, clientId));
        } catch (Exception e) {
            System.out.println("Error deleting client: " + e.getMessage());
            throw new IllegalArgumentException("Client not found or not yours");
        }

    }
}
