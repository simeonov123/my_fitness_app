// src/main/java/com/mvfitness/mytrainer2/service/workout/WorkoutInstanceExerciseServiceImpl.java
package com.mvfitness.mytrainer2.service.workout;

import com.mvfitness.mytrainer2.domain.*;
import com.mvfitness.mytrainer2.dto.WorkoutInstanceExerciseDto;
import com.mvfitness.mytrainer2.mapper.WorkoutInstanceExerciseMapper;
import com.mvfitness.mytrainer2.repository.*;
import com.mvfitness.mytrainer2.service.session.TrainingSessionRealtimeService;
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
    private final ClientRepository                  clients;
    private final TrainingSessionRealtimeService    realtime;

    /* ───────── helper guards ───────── */

    private User trainerOr404(String kc) {
        User u = users.findByKeycloakUserId(kc);
        if (u == null) throw new IllegalArgumentException("Trainer not found");
        return u;
    }

    private User userOr404(String kc) {
        User u = users.findByKeycloakUserId(kc);
        if (u == null) throw new IllegalArgumentException("User not found");
        return u;
    }

    private boolean isTrainer(String kc) {
        User user = userOr404(kc);
        return "TRAINER".equalsIgnoreCase(user.getRole())
                || !user.getClients().isEmpty()
                || !user.getTrainingSessions().isEmpty()
                || !user.getWorkoutTemplates().isEmpty()
                || !user.getExercises().isEmpty()
                || !user.getClientInvites().isEmpty();
    }

    private Client clientProfileOr404(String kc) {
        User user = userOr404(kc);
        return clients.findByAccountUser(user)
                .orElseThrow(() -> new IllegalArgumentException("Client profile not found"));
    }

    private User accountUserOr404(String kc) {
        User user = userOr404(kc);
        if (user.getClientProfile() == null) {
            throw new IllegalArgumentException("Client profile not found");
        }
        return user;
    }

    private TrainingSession ownedSessionOr404(String kc, Long id) {
        TrainingSession t = sessions.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));
        if (!t.getTrainer().getKeycloakUserId().equals(kc))
            throw new IllegalArgumentException("Session not found");
        return t;
    }

    private TrainingSession accessibleSessionOr404(String kc, Long id) {
        if (isTrainer(kc)) {
            return ownedSessionOr404(kc, id);
        }
        return sessions.findWithClientsByIdAndClients_AccountUser(id, accountUserOr404(kc))
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));
    }

    /* ───────── API ───────── */

    @Override @Transactional(readOnly = true)
    public List<WorkoutInstanceExerciseDto> list(String kc, Long sessionId) {
        TrainingSession session = accessibleSessionOr404(kc, sessionId);
        var list = repo
                .findByWorkoutInstance_TrainingSession_IdOrderBySequenceOrderAsc(sessionId);
        // pull lazy sets
        list.forEach(e -> e.getWorkoutInstanceExerciseHasSets().forEach(s -> s.getSetData().size()));
        if (!isTrainer(kc)) {
            User accountUser = accountUserOr404(kc);
            list = list.stream()
                    .filter(e -> {
                        Client client = e.getWorkoutInstance().getClient();
                        return client.getAccountUser() != null
                                && client.getAccountUser().getId().equals(accountUser.getId());
                    })
                    .toList();
        }
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

        var session = accessibleSessionOr404(kc, sessionId);
        final boolean trainer = isTrainer(kc);
        if (!isTrainer(kc) && Boolean.TRUE.equals(session.getIsCompleted())) {
            throw new IllegalArgumentException("Completed sessions are read-only for clients");
        }
        Map<Long, WorkoutInstance> workoutInstancesById = session.getWorkoutInstances().stream()
                .collect(Collectors.toMap(WorkoutInstance::getId, Function.identity()));
        Map<Long, WorkoutInstance> workoutInstancesByClientId = session.getWorkoutInstances().stream()
                .collect(Collectors.toMap(wi -> wi.getClient().getId(), Function.identity()));

        WorkoutInstance ownInstance = null;
        Long ownClientId = null;

        if (!trainer) {
            User accountUser = accountUserOr404(kc);
            ownInstance = session.getWorkoutInstances().stream()
                    .filter(wi -> wi.getClient() != null
                            && wi.getClient().getAccountUser() != null
                            && wi.getClient().getAccountUser().getId().equals(accountUser.getId()))
                    .findFirst()
                    .orElseThrow(() -> new IllegalArgumentException("Workout instance not found for client entry"));
            ownClientId = ownInstance.getClient().getId();
            final Long ownClientIdForFilter = ownClientId;
            final Long ownWorkoutInstanceId = ownInstance.getId();

            dtos = dtos.stream()
                    .filter(dto ->
                            (dto.clientId() == null || dto.clientId().equals(ownClientIdForFilter))
                                    && (dto.workoutInstanceId() == null
                                    || dto.workoutInstanceId().equals(ownWorkoutInstanceId)))
                    .toList();
        }

        /* 1) clear managed child collections, then nuke existing rows */
        if (trainer) {
            for (WorkoutInstance wi : session.getWorkoutInstances()) {
                wi.getWorkoutInstanceExercises().clear();
            }
            repo.deleteByWorkoutInstance_TrainingSession_Id(sessionId);
        } else {
            ownInstance.getWorkoutInstanceExercises().clear();
            repo.deleteByWorkoutInstance_Id(ownInstance.getId());
        }
        repo.flush();

        /* 2) recreate per client-specific WorkoutInstance */
        for (WorkoutInstanceExerciseDto dto : dtos) {
            WorkoutInstance wi = null;
            if (trainer) {
                if (dto.workoutInstanceId() != null) {
                    wi = workoutInstancesById.get(dto.workoutInstanceId());
                }
                if (wi == null && dto.clientId() != null) {
                    wi = workoutInstancesByClientId.get(dto.clientId());
                }
            } else {
                wi = ownInstance;
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
        List<WorkoutInstanceExerciseDto> updated = list(kc, sessionId);
        realtime.publishInstanceUpdated(sessionId, subscriberKc -> list(subscriberKc, sessionId));
        return updated;
    }

    @Override
    public void deleteOne(String kc, Long sessionId, Long entryId) {
        TrainingSession session = accessibleSessionOr404(kc, sessionId);                        // guard
        var ent = repo.findById(entryId)
                .orElseThrow(() -> new IllegalArgumentException("Entry not found"));
        if (!ent.getWorkoutInstance().getTrainingSession().getId().equals(sessionId))
            throw new IllegalArgumentException("Entry not in that session");
        if (!isTrainer(kc)) {
            if (Boolean.TRUE.equals(session.getIsCompleted())) {
                throw new IllegalArgumentException("Completed sessions are read-only for clients");
            }
            User accountUser = accountUserOr404(kc);
            Client entryClient = ent.getWorkoutInstance().getClient();
            if (entryClient.getAccountUser() == null
                    || !entryClient.getAccountUser().getId().equals(accountUser.getId())) {
                throw new IllegalArgumentException("Entry not in that session");
            }
        }
        repo.delete(ent);
        repo.flush();
        realtime.publishInstanceUpdated(sessionId, subscriberKc -> list(subscriberKc, sessionId));
    }
}
