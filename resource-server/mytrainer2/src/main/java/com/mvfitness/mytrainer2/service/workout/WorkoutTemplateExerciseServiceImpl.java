// src/main/java/com/mvfitness/mytrainer2/service/workout/WorkoutTemplateExerciseServiceImpl.java
package com.mvfitness.mytrainer2.service.workout;

import com.mvfitness.mytrainer2.domain.WorkoutTemplate;
import com.mvfitness.mytrainer2.domain.WorkoutTemplateExercise;
import com.mvfitness.mytrainer2.dto.WorkoutTemplateExerciseDto;
import com.mvfitness.mytrainer2.mapper.WorkoutTemplateExerciseMapper;
import com.mvfitness.mytrainer2.repository.ExerciseRepository;
import com.mvfitness.mytrainer2.repository.UserRepository;
import com.mvfitness.mytrainer2.repository.WorkoutTemplateExerciseRepository;
import com.mvfitness.mytrainer2.repository.WorkoutTemplateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class WorkoutTemplateExerciseServiceImpl implements WorkoutTemplateExerciseService {

    private final WorkoutTemplateRepository tplRepo;
    private final WorkoutTemplateExerciseRepository wteRepo;
    private final ExerciseRepository exRepo;
    private final UserRepository userRepo;

    private WorkoutTemplate loadOwnedTemplate(String kc, Long id) {
        var user = userRepo.findByKeycloakUserId(kc);
        if (user == null) throw new IllegalArgumentException("Trainer not found");
        var tpl = tplRepo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Template not found"));
        if (!tpl.getTrainer().getId().equals(user.getId())) {
            throw new IllegalArgumentException("Not yours");
        }
        return tpl;
    }

    @Override
    @Transactional(readOnly = true)
    public List<WorkoutTemplateExerciseDto> list(String kc, Long templateId) {
        var tpl = loadOwnedTemplate(kc, templateId);
        var all = wteRepo.findByWorkoutTemplateOrderBySequenceOrderAsc(tpl);
        // Force fetch of sets (optional)
        all.forEach(wte -> wte.getExerciseHasSets().size());
        return WorkoutTemplateExerciseMapper.toDtoList(all);
    }

    @Override
    public List<WorkoutTemplateExerciseDto> replaceAll(
            String kc, Long templateId, List<WorkoutTemplateExerciseDto> dtos) {

        var tpl = loadOwnedTemplate(kc, templateId);

        // delete existing (cascade will clean up template‐sets/data)
        wteRepo.deleteByWorkoutTemplate(tpl);

        // recreate everything
        for (var dto : dtos) {
            var ex = exRepo.findById(dto.exerciseId())
                    .orElseThrow(() -> new IllegalArgumentException("Exercise not found"));
            var ent = WorkoutTemplateExercise.builder().build();
            WorkoutTemplateExerciseMapper.updateEntity(ent, dto, tpl, ex);
            wteRepo.save(ent);
        }

        return list(kc, templateId);
    }

    @Override
    public void deleteOne(String kc, Long tplId, Long entryId) {
        var tpl = loadOwnedTemplate(kc, tplId);
        var ent = wteRepo.findById(entryId)
                .orElseThrow(() -> new IllegalArgumentException("Entry not found"));
        if (!ent.getWorkoutTemplate().getId().equals(tpl.getId())) {
            throw new IllegalArgumentException("Entry not yours");
        }
        wteRepo.delete(ent);
    }
}
