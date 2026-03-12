package com.mvfitness.mytrainer2.service.exercise;

import com.mvfitness.mytrainer2.domain.MuscleGroup;
import com.mvfitness.mytrainer2.domain.User;
import com.mvfitness.mytrainer2.dto.MuscleGroupDto;
import com.mvfitness.mytrainer2.mapper.MuscleGroupMapper;
import com.mvfitness.mytrainer2.repository.MuscleGroupRepository;
import com.mvfitness.mytrainer2.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class MuscleGroupServiceImpl implements MuscleGroupService {

    private final MuscleGroupRepository repo;
    private final UserRepository users;

    private User trainerOr404(String kcId) {
        User u = users.findByKeycloakUserId(kcId);
        if (u == null) throw new IllegalArgumentException("Trainer not found");
        return u;
    }

    private MuscleGroup ownedCustomOr404(String kcId, Long id) {
        User trainer = trainerOr404(kcId);
        MuscleGroup group = repo.findByIdAndTrainer(id, trainer)
                .orElseThrow(() -> new IllegalArgumentException("Muscle group not found"));
        if (!Boolean.TRUE.equals(group.getIsCustom())) {
            throw new IllegalArgumentException("Muscle group not found");
        }
        return group;
    }

    @Override
    @Transactional(readOnly = true)
    public List<MuscleGroupDto> list(String kcUserId) {
        return repo.findByTrainerOrIsCustomFalseOrderByNameAsc(trainerOr404(kcUserId))
                .stream()
                .map(MuscleGroupMapper::toDto)
                .toList();
    }

    @Override
    public MuscleGroupDto create(String kcUserId, MuscleGroupDto dto) {
        MuscleGroup group = MuscleGroup.builder()
                .trainer(trainerOr404(kcUserId))
                .name(dto.name())
                .isCustom(true)
                .build();
        return MuscleGroupMapper.toDto(repo.save(group));
    }

    @Override
    public MuscleGroupDto update(String kcUserId, Long id, MuscleGroupDto dto) {
        MuscleGroup group = ownedCustomOr404(kcUserId, id);
        group.setName(dto.name());
        return MuscleGroupMapper.toDto(repo.save(group));
    }

    @Override
    public void delete(String kcUserId, Long id) {
        MuscleGroup group = ownedCustomOr404(kcUserId, id);
        group.getExercises().forEach(exercise -> exercise.getMuscleGroups().remove(group));
        group.getExercises().clear();
        repo.delete(group);
    }
}
