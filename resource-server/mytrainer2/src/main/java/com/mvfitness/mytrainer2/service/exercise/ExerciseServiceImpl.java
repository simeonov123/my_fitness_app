// src/main/java/com/mvfitness/mytrainer2/service/exercise/ExerciseServiceImpl.java
package com.mvfitness.mytrainer2.service.exercise;

import com.mvfitness.mytrainer2.domain.Exercise;
import com.mvfitness.mytrainer2.domain.User;
import com.mvfitness.mytrainer2.dto.ExerciseDto;
import com.mvfitness.mytrainer2.mapper.ExerciseMapper;
import com.mvfitness.mytrainer2.repository.ExerciseRepository;
import com.mvfitness.mytrainer2.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service @RequiredArgsConstructor @Transactional
public class ExerciseServiceImpl implements ExerciseService {

    private final ExerciseRepository repo;
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
        Exercise e = Exercise.builder()
                .trainer(trainerOr404(kcId))
                .name(dto.name())
                .description(dto.description())
                .isCustom(dto.isCustom())
                .defaultSetType(dto.defaultSetType())
                .defaultSetParams(dto.defaultSetParams())
                .build();
        return ExerciseMapper.toDto(repo.save(e));
    }

    @Override
    public ExerciseDto update(String kcId, Long id, ExerciseDto dto) {
        Exercise e = ownedOr404(kcId,id);
        ExerciseMapper.updateEntity(e,dto);
        return ExerciseMapper.toDto(repo.save(e));
    }

    @Override
    public void delete(String kcId, Long id) {
        repo.delete(ownedOr404(kcId,id));
    }
}
