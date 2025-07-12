// src/main/java/com/mvfitness/mytrainer2/service/workout/WorkoutInstanceExerciseServiceImpl.java
package com.mvfitness.mytrainer2.service.workout;

import com.mvfitness.mytrainer2.domain.*;
import com.mvfitness.mytrainer2.dto.WorkoutInstanceExerciseDto;
import com.mvfitness.mytrainer2.mapper.WorkoutInstanceExerciseMapper;
import com.mvfitness.mytrainer2.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class WorkoutInstanceExerciseServiceImpl
        implements WorkoutInstanceExerciseService {

    private final WorkoutInstanceExerciseRepository repo;
    private final TrainingSessionRepository         sessions;
    private final ExerciseRepository                exRepo;
    private final UserRepository                    users;

    /* ───────── helper guards ───────── */

    private User trainerOr404(String kc) {
        User u = users.findByKeycloakUserId(kc);
        if (u == null) throw new IllegalArgumentException("Trainer not found");
        return u;
    }

    private TrainingSession ownedSessionOr404(String kc, Long id) {
        TrainingSession t = sessions.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));
        if (!t.getTrainer().getKeycloakUserId().equals(kc))
            throw new IllegalArgumentException("Session not found");
        return t;
    }

    /* ───────── API ───────── */

    @Override @Transactional(readOnly = true)
    public List<WorkoutInstanceExerciseDto> list(String kc, Long sessionId) {
        ownedSessionOr404(kc, sessionId);          // ownership check
        var list = repo
                .findByWorkoutInstance_TrainingSession_IdOrderBySequenceOrderAsc(sessionId);
        // pull lazy sets
        list.forEach(e -> e.getWorkoutInstanceExerciseHasSets().forEach(s -> s.getSetData().size()));
        return WorkoutInstanceExerciseMapper.toDtoList(list);
    }

    @Override
    public List<WorkoutInstanceExerciseDto> replaceAll(
            String kc, Long sessionId, List<WorkoutInstanceExerciseDto> dtos) {

        var session = ownedSessionOr404(kc, sessionId);

        /* 1) nuke existing */
        repo.deleteByWorkoutInstance_TrainingSession_Id(sessionId);

        /* 2) recreate – iterate over every WorkoutInstance of the session */
        for (WorkoutInstance wi : session.getWorkoutInstances()) {
            for (WorkoutInstanceExerciseDto dto : dtos) {

                var ex = exRepo.findById(dto.exerciseId())
                        .orElseThrow(() -> new IllegalArgumentException("Exercise not found"));

                var ent = WorkoutInstanceExerciseMapper.toEntity(dto, wi);
                ent.setExercise(ex);

                wi.getWorkoutInstanceExercises().add(ent);
                repo.save(ent);                                  // cascades OK
            }
        }
        return list(kc, sessionId);
    }

    @Override
    public void deleteOne(String kc, Long sessionId, Long entryId) {
        ownedSessionOr404(kc, sessionId);                        // guard
        var ent = repo.findById(entryId)
                .orElseThrow(() -> new IllegalArgumentException("Entry not found"));
        if (!ent.getWorkoutInstance().getTrainingSession().getId().equals(sessionId))
            throw new IllegalArgumentException("Entry not in that session");
        repo.delete(ent);
    }
}
