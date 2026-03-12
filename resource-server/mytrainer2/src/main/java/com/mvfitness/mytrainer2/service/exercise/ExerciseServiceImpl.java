// src/main/java/com/mvfitness/mytrainer2/service/exercise/ExerciseServiceImpl.java
package com.mvfitness.mytrainer2.service.exercise;

import com.mvfitness.mytrainer2.domain.Exercise;
import com.mvfitness.mytrainer2.domain.MuscleGroup;
import com.mvfitness.mytrainer2.domain.User;
import com.mvfitness.mytrainer2.dto.ExerciseDto;
import com.mvfitness.mytrainer2.mapper.ExerciseMapper;
import com.mvfitness.mytrainer2.repository.ExerciseRepository;
import com.mvfitness.mytrainer2.repository.MuscleGroupRepository;
import com.mvfitness.mytrainer2.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service @RequiredArgsConstructor @Transactional
public class ExerciseServiceImpl implements ExerciseService {

    private final ExerciseRepository repo;
    private final MuscleGroupRepository muscleGroups;
    private final UserRepository users;

    private User trainerOr404(String kcId){
        User u = users.findByKeycloakUserId(kcId);
        if(u==null) throw new IllegalArgumentException("Trainer not found");
        return u;
    }
    private Exercise ownedOr404(String kcId, Long id){
        User tr = trainerOr404(kcId);
        Exercise e = repo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Exercise not found"));
        if(!e.getTrainer().getId().equals(tr.getId()))
            throw new IllegalArgumentException("Exercise not found");
        return e;
    }

    @Override @Transactional(readOnly = true)
    public Page<ExerciseDto> list(String kcId, String q, int page, int size, String sort) {
        Sort order = switch (sort) {
            case "name"      -> Sort.by("name").ascending();
            case "name_desc" -> Sort.by("name").descending();
            case "oldest"    -> Sort.by("createdAt").ascending();
            default          -> Sort.by("createdAt").descending();
        };
        Page<Exercise> p = repo.findByTrainerAndNameContainingIgnoreCase(
                trainerOr404(kcId),
                q==null? "" : q,
                PageRequest.of(page,size,order));
        return p.map(ExerciseMapper::toDto);
    }

    @Override @Transactional(readOnly = true)
    public Page<ExerciseDto> listCommonExercises(String kcId, String q, int page, int size, String sort) {
        Sort order = switch (sort) {
            case "name"      -> Sort.by("name").ascending();
            case "name_desc" -> Sort.by("name").descending();
            case "oldest"    -> Sort.by("createdAt").ascending();
            default          -> Sort.by("createdAt").descending();
        };
        Page<Exercise> p = repo.findByIsCustomFalseAndNameContainingIgnoreCase(
                q == null ? "" : q,
                PageRequest.of(page, size, order));
        return p.map(ExerciseMapper::toDto);
    }

    @Override @Transactional(readOnly = true)
    public ExerciseDto get(String kcId, Long id) {
        return ExerciseMapper.toDto(ownedOr404(kcId,id));
    }

    @Override
    public ExerciseDto create(String kcId, ExerciseDto dto) {
        User trainer = trainerOr404(kcId);
        Exercise e = Exercise.builder()
                .trainer(trainer)
                .name(dto.name())
                .description(dto.description())
                .isCustom(dto.isCustom())
                .defaultSetType(dto.defaultSetType())
                .defaultSetParams(dto.defaultSetParams())
                .build();
        applyMuscleGroups(trainer, e, dto);
        return ExerciseMapper.toDto(repo.save(e));
    }

    @Override
    public ExerciseDto update(String kcId, Long id, ExerciseDto dto) {
        Exercise e = ownedOr404(kcId,id);
        User trainer = trainerOr404(kcId);
        ExerciseMapper.updateEntity(e,dto);
        applyMuscleGroups(trainer, e, dto);
        return ExerciseMapper.toDto(repo.save(e));
    }

    @Override
    public void delete(String kcId, Long id) {
        repo.delete(ownedOr404(kcId,id));
    }

    private void applyMuscleGroups(User trainer, Exercise e, ExerciseDto dto) {
        e.getMuscleGroups().clear();
        if (dto.muscleGroups() == null || dto.muscleGroups().isEmpty()) return;

        List<Long> ids = dto.muscleGroups().stream()
                .map(mg -> mg.id())
                .filter(id -> id != null && id > 0)
                .toList();

        if (ids.isEmpty()) return;

        List<MuscleGroup> groups = muscleGroups.findAllById(ids).stream()
                .filter(group -> Boolean.FALSE.equals(group.getIsCustom()) ||
                        (group.getTrainer() != null &&
                                group.getTrainer().getId().equals(trainer.getId())))
                .toList();
        e.getMuscleGroups().addAll(groups);
    }
}
