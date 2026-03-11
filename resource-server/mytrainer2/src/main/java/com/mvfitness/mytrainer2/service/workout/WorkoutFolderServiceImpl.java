package com.mvfitness.mytrainer2.service.workout;

import com.mvfitness.mytrainer2.domain.User;
import com.mvfitness.mytrainer2.domain.WorkoutFolder;
import com.mvfitness.mytrainer2.dto.WorkoutFolderDto;
import com.mvfitness.mytrainer2.mapper.WorkoutFolderMapper;
import com.mvfitness.mytrainer2.repository.UserRepository;
import com.mvfitness.mytrainer2.repository.WorkoutFolderRepository;
import com.mvfitness.mytrainer2.repository.WorkoutTemplateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class WorkoutFolderServiceImpl implements WorkoutFolderService {

    private final WorkoutFolderRepository folders;
    private final UserRepository users;
    private final WorkoutTemplateRepository templates;

    private User trainerOr404(String kcId) {
        User u = users.findByKeycloakUserId(kcId);
        if (u == null) throw new IllegalArgumentException("Trainer not found");
        return u;
    }

    private WorkoutFolder ownedOr404(String kcId, Long id) {
        User trainer = trainerOr404(kcId);
        WorkoutFolder folder = folders.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Workout folder not found"));
        if (!folder.getTrainer().getId().equals(trainer.getId())) {
            throw new IllegalArgumentException("Workout folder not found");
        }
        return folder;
    }

    @Override
    @Transactional(readOnly = true)
    public List<WorkoutFolderDto> list(String kcUserId) {
        return folders.findByTrainerOrderBySequenceOrderAscIdAsc(trainerOr404(kcUserId))
                .stream()
                .map(WorkoutFolderMapper::toDto)
                .toList();
    }

    @Override
    public WorkoutFolderDto create(String kcUserId, WorkoutFolderDto dto) {
        WorkoutFolder folder = WorkoutFolder.builder()
                .trainer(trainerOr404(kcUserId))
                .name(dto.name())
                .sequenceOrder(dto.sequenceOrder())
                .build();
        return WorkoutFolderMapper.toDto(folders.save(folder));
    }

    @Override
    public WorkoutFolderDto update(String kcUserId, Long id, WorkoutFolderDto dto) {
        WorkoutFolder folder = ownedOr404(kcUserId, id);
        folder.setName(dto.name());
        folder.setSequenceOrder(dto.sequenceOrder());
        return WorkoutFolderMapper.toDto(folders.save(folder));
    }

    @Override
    public void delete(String kcUserId, Long id) {
        WorkoutFolder folder = ownedOr404(kcUserId, id);
        for (var template : templates.findByFolder(folder)) {
            template.setFolder(null);
        }
        folders.delete(folder);
    }
}
