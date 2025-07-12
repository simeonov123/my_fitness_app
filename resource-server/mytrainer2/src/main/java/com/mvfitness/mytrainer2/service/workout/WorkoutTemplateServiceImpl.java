// src/main/java/com/mvfitness/mytrainer2/service/workout/WorkoutTemplateServiceImpl.java
package com.mvfitness.mytrainer2.service.workout;

import com.mvfitness.mytrainer2.dto.WorkoutTemplateExerciseDto;
import com.mvfitness.mytrainer2.domain.*;
import com.mvfitness.mytrainer2.dto.WorkoutTemplateDto;
import com.mvfitness.mytrainer2.mapper.WorkoutTemplateMapper;
import com.mvfitness.mytrainer2.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service @RequiredArgsConstructor @Transactional
public class WorkoutTemplateServiceImpl implements WorkoutTemplateService {

    private final WorkoutTemplateRepository repo;
    private final UserRepository users;
    private final ExerciseRepository exercises;
    private final WorkoutTemplateExerciseRepository wteRepo;


    private User trainerOr404(String kcId){
        User u = users.findByKeycloakUserId(kcId);
        if(u==null) throw new IllegalArgumentException("Trainer not found");
        return u;
    }
    private WorkoutTemplate ownedOr404(String kcId, Long id){
        User tr = trainerOr404(kcId);
        WorkoutTemplate t = repo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Template not found"));
        if(!t.getTrainer().getId().equals(tr.getId()))
            throw new IllegalArgumentException("Template not found");
        return t;
    }

    @Override @Transactional(readOnly = true)
    public Page<WorkoutTemplateDto> list(String kcId, String q, int page, int size, String sort) {
        Sort order = switch (sort) {
            case "name"      -> Sort.by("name").ascending();
            case "name_desc" -> Sort.by("name").descending();
            case "oldest"    -> Sort.by("createdAt").ascending();
            default          -> Sort.by("createdAt").descending();
        };
        User trainer = trainerOr404(kcId);
        Page<WorkoutTemplate> p = repo.findByTrainerAndNameContainingIgnoreCase(
                trainer, q==null?"":q, PageRequest.of(page,size,order));
        return p.map(WorkoutTemplateMapper::toDto);
    }

    @Override @Transactional(readOnly = true)
    public WorkoutTemplateDto get(String kcId, Long id) {
        return WorkoutTemplateMapper.toDto(ownedOr404(kcId,id));
    }

    @Override
    public WorkoutTemplateDto create(String kcId, WorkoutTemplateDto dto) {
        User trainer = trainerOr404(kcId);
        WorkoutTemplate t = WorkoutTemplate.builder()
                .trainer(trainer)
                .build();
        List<Exercise> refs = dto.exercises()==null? List.of() :
                exercises.findAllById(dto.exercises().stream()
                        .map(WorkoutTemplateExerciseDto::exerciseId).toList());
        WorkoutTemplateMapper.updateEntity(t,dto,refs);
        return WorkoutTemplateMapper.toDto(repo.save(t));
    }

    @Override
    public WorkoutTemplateDto update(String kcId, Long id, WorkoutTemplateDto dto) {
        WorkoutTemplate t = ownedOr404(kcId,id);
        List<Exercise> refs = dto.exercises()==null? List.of() :
                exercises.findAllById(dto.exercises().stream()
                        .map(WorkoutTemplateExerciseDto::exerciseId).toList());
        WorkoutTemplateMapper.updateEntity(t,dto,refs);
        return WorkoutTemplateMapper.toDto(repo.save(t));
    }

    @Override
    public void delete(String kcId, Long id) {
        // fetch & verify ownership
        WorkoutTemplate t = ownedOr404(kcId, id);

        // delete all child rows first
        wteRepo.deleteByWorkoutTemplateId(t.getId());

        // now delete the template
        repo.delete(t);
    }
}
