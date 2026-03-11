package com.mvfitness.mytrainer2.service.client;

import com.mvfitness.mytrainer2.domain.ClientFolder;
import com.mvfitness.mytrainer2.domain.User;
import com.mvfitness.mytrainer2.dto.ClientFolderDto;
import com.mvfitness.mytrainer2.mapper.ClientFolderMapper;
import com.mvfitness.mytrainer2.repository.ClientFolderRepository;
import com.mvfitness.mytrainer2.repository.ClientRepository;
import com.mvfitness.mytrainer2.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class ClientFolderServiceImpl implements ClientFolderService {

    private final ClientFolderRepository folders;
    private final ClientRepository clients;
    private final UserRepository users;

    private User trainerOr404(String kcId) {
        User u = users.findByKeycloakUserId(kcId);
        if (u == null) throw new IllegalArgumentException("Trainer not found");
        return u;
    }

    private ClientFolder ownedOr404(String kcId, Long id) {
        User trainer = trainerOr404(kcId);
        ClientFolder folder = folders.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Client folder not found"));
        if (!folder.getUser().getId().equals(trainer.getId())) {
            throw new IllegalArgumentException("Client folder not found");
        }
        return folder;
    }

    @Override
    @Transactional(readOnly = true)
    public List<ClientFolderDto> list(String kcUserId) {
        return folders.findByUserOrderBySequenceOrderAscIdAsc(trainerOr404(kcUserId))
                .stream()
                .map(ClientFolderMapper::toDto)
                .toList();
    }

    @Override
    public ClientFolderDto create(String kcUserId, ClientFolderDto dto) {
        ClientFolder folder = ClientFolder.builder()
                .user(trainerOr404(kcUserId))
                .name(dto.name())
                .sequenceOrder(dto.sequenceOrder())
                .build();
        return ClientFolderMapper.toDto(folders.save(folder));
    }

    @Override
    public ClientFolderDto update(String kcUserId, Long id, ClientFolderDto dto) {
        ClientFolder folder = ownedOr404(kcUserId, id);
        folder.setName(dto.name());
        folder.setSequenceOrder(dto.sequenceOrder());
        return ClientFolderMapper.toDto(folders.save(folder));
    }

    @Override
    public void delete(String kcUserId, Long id) {
        ClientFolder folder = ownedOr404(kcUserId, id);
        for (var client : clients.findByFolder(folder)) {
            client.setFolder(null);
        }
        folders.delete(folder);
    }
}
