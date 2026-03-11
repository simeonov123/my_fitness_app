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
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

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
        return list.stream()
                .sorted((a, b) -> {
                    int byClient = a.getWorkoutInstance().getClient().getFullName()
                            .compareToIgnoreCase(b.getWorkoutInstance().getClient().getFullName());
                    if (byClient != 0) return byClient;
                    return Integer.compare(a.getSequenceOrder(), b.getSequenceOrder());
                })
                .map(WorkoutInstanceExerciseMapper::toDto)
                .toList();
    }

    @Override
    public List<WorkoutInstanceExerciseDto> replaceAll(
            String kc, Long sessionId, List<WorkoutInstanceExerciseDto> dtos) {

        var session = ownedSessionOr404(kc, sessionId);
        Map<Long, WorkoutInstance> workoutInstancesById = session.getWorkoutInstances().stream()
                .collect(Collectors.toMap(WorkoutInstance::getId, Function.identity()));
        Map<Long, WorkoutInstance> workoutInstancesByClientId = session.getWorkoutInstances().stream()
                .collect(Collectors.toMap(wi -> wi.getClient().getId(), Function.identity()));

        /* 1) clear managed child collections, then nuke existing rows */
        for (WorkoutInstance wi : session.getWorkoutInstances()) {
            wi.getWorkoutInstanceExercises().clear();
        }
        repo.deleteByWorkoutInstance_TrainingSession_Id(sessionId);
        repo.flush();

        /* 2) recreate per client-specific WorkoutInstance */
        for (WorkoutInstanceExerciseDto dto : dtos) {
            WorkoutInstance wi = null;
            if (dto.workoutInstanceId() != null) {
                wi = workoutInstancesById.get(dto.workoutInstanceId());
            }
            if (wi == null && dto.clientId() != null) {
                wi = workoutInstancesByClientId.get(dto.clientId());
            }
            if (wi == null) {
                throw new IllegalArgumentException("Workout instance not found for client entry");
            }

            var ex = exRepo.findById(dto.exerciseId())
                    .orElseThrow(() -> new IllegalArgumentException("Exercise not found"));

            var ent = WorkoutInstanceExerciseMapper.toEntity(dto, wi);
            ent.setExercise(ex);

            wi.getWorkoutInstanceExercises().add(ent);
            repo.save(ent);
        }
        repo.flush();
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
