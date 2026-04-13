// src/main/java/com/mvfitness/mytrainer2/service/workout/WorkoutInstanceExerciseServiceImpl.java
package com.mvfitness.mytrainer2.service.workout;

import com.mvfitness.mytrainer2.domain.*;
import com.mvfitness.mytrainer2.dto.ExerciseHasSetsDto;
import com.mvfitness.mytrainer2.dto.ExerciseHistoryDto;
import com.mvfitness.mytrainer2.dto.ExerciseHistorySnapshotDto;
import com.mvfitness.mytrainer2.dto.ExerciseHistorySummaryDto;
import com.mvfitness.mytrainer2.dto.WorkoutInstanceExerciseDto;
import com.mvfitness.mytrainer2.mapper.ExerciseHasSetsMapper;
import com.mvfitness.mytrainer2.mapper.WorkoutInstanceExerciseMapper;
import com.mvfitness.mytrainer2.repository.*;
import com.mvfitness.mytrainer2.service.session.TrainingSessionRealtimeService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class WorkoutInstanceExerciseServiceImpl
        implements WorkoutInstanceExerciseService {

    private final WorkoutInstanceExerciseRepository repo;
    private final WorkoutInstanceRepository         instanceRepo;
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

    private String participantName(WorkoutInstance instance) {
        if (instance.getClient() != null) {
            return instance.getClient().getFullName();
        }
        if (instance.getTrainingSession() != null && instance.getTrainingSession().getTrainer() != null) {
            String fullName = instance.getTrainingSession().getTrainer().getFullName();
            if (fullName != null && !fullName.isBlank()) {
                return fullName;
            }
        }
        return "Solo";
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

    private WorkoutInstance createWorkoutInstance(TrainingSession session, Client client) {
        WorkoutInstance instance = WorkoutInstance.builder()
                .trainingSession(session)
                .client(client)
                .workoutTemplate(session.getWorkoutTemplate())
                .build();
        instance = instanceRepo.save(instance);
        session.getWorkoutInstances().add(instance);
        if (client != null) {
            client.getWorkoutInstances().add(instance);
        }
        return instance;
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
                        return client != null
                                && client.getAccountUser() != null
                                && client.getAccountUser().getId().equals(accountUser.getId());
                    })
                    .toList();
        }
        return list.stream()
                .sorted((a, b) -> {
                    int byClient = participantName(a.getWorkoutInstance())
                            .compareToIgnoreCase(participantName(b.getWorkoutInstance()));
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
                .collect(Collectors.toMap(WorkoutInstance::getId, Function.identity(), (left, right) -> left, LinkedHashMap::new));
        Map<Long, WorkoutInstance> workoutInstancesByClientId = session.getWorkoutInstances().stream()
                .filter(wi -> wi.getClient() != null)
                .collect(Collectors.toMap(
                        wi -> wi.getClient().getId(),
                        Function.identity(),
                        (left, right) -> left,
                        LinkedHashMap::new
                ));
        WorkoutInstance soloInstance = session.getWorkoutInstances().stream()
                .filter(wi -> wi.getClient() == null)
                .findFirst()
                .orElse(null);

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
                    if (wi == null) {
                        Client sessionClient = session.getClients().stream()
                                .filter(client -> Objects.equals(client.getId(), dto.clientId()))
                                .findFirst()
                                .orElseThrow(() -> new IllegalArgumentException("Workout instance not found for client entry"));
                        wi = createWorkoutInstance(session, sessionClient);
                        workoutInstancesById.put(wi.getId(), wi);
                        workoutInstancesByClientId.put(sessionClient.getId(), wi);
                    }
                }
                if (wi == null && dto.clientId() == null) {
                    wi = soloInstance;
                    if (wi == null) {
                        wi = createWorkoutInstance(session, null);
                        workoutInstancesById.put(wi.getId(), wi);
                        soloInstance = wi;
                    }
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
    @Transactional(readOnly = true)
    public ExerciseHistoryDto history(String kc, Long sessionId, Long entryId, int limit) {
        accessibleSessionOr404(kc, sessionId);

        WorkoutInstanceExercise current = repo.findById(entryId)
                .orElseThrow(() -> new IllegalArgumentException("Entry not found"));
        if (!current.getWorkoutInstance().getTrainingSession().getId().equals(sessionId)) {
            throw new IllegalArgumentException("Entry not in that session");
        }

        if (!isTrainer(kc)) {
            User accountUser = accountUserOr404(kc);
            Client entryClient = current.getWorkoutInstance().getClient();
            if (entryClient == null
                    || entryClient.getAccountUser() == null
                    || !entryClient.getAccountUser().getId().equals(accountUser.getId())) {
                throw new IllegalArgumentException("Entry not in that session");
            }
        }

        Long exerciseId = current.getExercise().getId();
        int clampedLimit = Math.max(1, Math.min(limit, 5));

        List<Long> historyIds;
        if (current.getWorkoutInstance().getClient() != null) {
            Long clientId = current.getWorkoutInstance().getClient().getId();
            historyIds = repo.findHistoryIdsForClientExercise(
                    clientId,
                    exerciseId,
                    sessionId,
                    PageRequest.of(0, clampedLimit)
            );
        } else {
            historyIds = repo.findHistoryIdsForTrainerSoloExercise(
                    current.getWorkoutInstance().getTrainingSession().getTrainer().getId(),
                    exerciseId,
                    sessionId,
                    PageRequest.of(0, clampedLimit)
            );
        }

        List<WorkoutInstanceExercise> history = historyIds.isEmpty()
                ? List.of()
                : repo.findAllWithDetailsByIdIn(historyIds);

        Map<Long, Integer> order = new LinkedHashMap<>();
        for (int i = 0; i < historyIds.size(); i++) {
            order.put(historyIds.get(i), i);
        }

        history = history.stream()
                .sorted(Comparator.comparingInt(e -> order.getOrDefault(e.getId(), Integer.MAX_VALUE)))
                .toList();

        history.forEach(this::initializeHistoryEntry);

        Long historyOwnerId = current.getWorkoutInstance().getClient() != null
                ? current.getWorkoutInstance().getClient().getId()
                : null;
        String historyOwnerName = participantName(current.getWorkoutInstance());

        return new ExerciseHistoryDto(
                historyOwnerId,
                historyOwnerName,
                exerciseId,
                current.getExercise().getName(),
                current.getSetType(),
                current.getSetParams(),
                buildSummary(current, history),
                history.stream().map(this::toSnapshotDto).toList()
        );
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
            if (entryClient == null
                    || entryClient.getAccountUser() == null
                    || !entryClient.getAccountUser().getId().equals(accountUser.getId())) {
                throw new IllegalArgumentException("Entry not in that session");
            }
        }
        repo.delete(ent);
        repo.flush();
        realtime.publishInstanceUpdated(sessionId, subscriberKc -> list(subscriberKc, sessionId));
    }

    private void initializeHistoryEntry(WorkoutInstanceExercise entry) {
        entry.getWorkoutInstanceExerciseHasSets().forEach(set -> set.getSetData().size());
        if (entry.getWorkoutInstance().getTrainingSession() != null) {
            entry.getWorkoutInstance().getTrainingSession().getStartTime();
        }
        if (entry.getWorkoutInstance().getClient() != null) {
            entry.getWorkoutInstance().getClient().getFullName();
        }
        if (entry.getExercise() != null) {
            entry.getExercise().getName();
        }
    }

    private ExerciseHistorySnapshotDto toSnapshotDto(WorkoutInstanceExercise entry) {
        ExerciseMetrics metrics = collectMetrics(List.of(entry));
        TrainingSession session = entry.getWorkoutInstance().getTrainingSession();
        List<ExerciseHasSetsDto> sets = ExerciseHasSetsMapper.toDtoListFromInstance(
                entry.getWorkoutInstanceExerciseHasSets()
        );
        int completedSetCount = (int) entry.getWorkoutInstanceExerciseHasSets().stream()
                .filter(set -> Boolean.TRUE.equals(set.getCompleted()))
                .count();

        return new ExerciseHistorySnapshotDto(
                session.getId(),
                session.getSessionName(),
                session.getStartTime(),
                entry.getWorkoutInstance().getId(),
                entry.getId(),
                entry.getSetType(),
                entry.getSetParams(),
                completedSetCount,
                entry.getWorkoutInstanceExerciseHasSets().size(),
                metrics.bestReps(),
                metrics.bestOneRepMax(),
                metrics.bestSetVolume(),
                metrics.bestWeight(),
                metrics.bestDurationSeconds(),
                metrics.bestDistanceKm(),
                sets
        );
    }

    private ExerciseHistorySummaryDto buildSummary(
            WorkoutInstanceExercise current,
            List<WorkoutInstanceExercise> history
    ) {
        ExerciseMetrics metrics = collectMetrics(history);
        return new ExerciseHistorySummaryDto(
                metrics.averageBestRepsPerSession(),
                metrics.bestOneRepMax(),
                metrics.bestSetVolume(),
                metrics.bestWeight(),
                metrics.bestDurationSeconds(),
                metrics.bestDistanceKm(),
                metrics.fastestPaceSecondsPerKm(),
                supportedMetrics(current, history)
        );
    }

    private ExerciseMetrics collectMetrics(List<WorkoutInstanceExercise> entries) {
        List<Double> bestRepsPerEntry = new ArrayList<>();
        Double bestOneRepMax = null;
        Double bestSetVolume = null;
        Double bestWeight = null;
        Double bestDurationSeconds = null;
        Double bestDistanceKm = null;
        Double fastestPaceSecondsPerKm = null;

        for (WorkoutInstanceExercise entry : entries) {
            Double sessionBestReps = null;

            for (WorkoutInstanceExerciseHasSets set : entry.getWorkoutInstanceExerciseHasSets()) {
                if (!Boolean.TRUE.equals(set.getCompleted())) {
                    continue;
                }

                Double reps = valueFor(set, SetType.REPS);
                Double kg = valueFor(set, SetType.KG);
                Double time = valueFor(set, SetType.TIME);
                Double km = valueFor(set, SetType.KM);

                if (reps != null) {
                    sessionBestReps = max(sessionBestReps, reps);
                }
                if (kg != null) {
                    bestWeight = max(bestWeight, kg);
                }
                if (time != null) {
                    bestDurationSeconds = max(bestDurationSeconds, time);
                }
                if (km != null) {
                    bestDistanceKm = max(bestDistanceKm, km);
                }
                if (kg != null && reps != null && reps > 0) {
                    bestSetVolume = max(bestSetVolume, kg * reps);
                    bestOneRepMax = max(bestOneRepMax, kg * (1.0 + (reps / 30.0)));
                }
                if (time != null && km != null && time > 0 && km > 0) {
                    fastestPaceSecondsPerKm = min(fastestPaceSecondsPerKm, time / km);
                }
            }

            if (sessionBestReps != null) {
                bestRepsPerEntry.add(sessionBestReps);
            }
        }

        Double averageBestRepsPerSession = null;
        if (!bestRepsPerEntry.isEmpty()) {
            averageBestRepsPerSession = bestRepsPerEntry.stream()
                    .filter(Objects::nonNull)
                    .mapToDouble(Double::doubleValue)
                    .average()
                    .orElse(0.0);
        }

        Double bestReps = bestRepsPerEntry.stream().max(Double::compareTo).orElse(null);

        return new ExerciseMetrics(
                averageBestRepsPerSession,
                bestReps,
                bestOneRepMax,
                bestSetVolume,
                bestWeight,
                bestDurationSeconds,
                bestDistanceKm,
                fastestPaceSecondsPerKm
        );
    }

    private List<String> supportedMetrics(
            WorkoutInstanceExercise current,
            List<WorkoutInstanceExercise> history
    ) {
        var keys = new java.util.LinkedHashSet<String>();
        if (current.getSetParams() != null) {
            for (String raw : current.getSetParams().split(",")) {
                String trimmed = raw.trim().toUpperCase();
                if (!trimmed.isEmpty()) {
                    keys.add(trimmed);
                }
            }
        }
        for (WorkoutInstanceExercise entry : history) {
            for (WorkoutInstanceExerciseHasSets set : entry.getWorkoutInstanceExerciseHasSets()) {
                set.getSetData().forEach(data -> keys.add(data.getType().name()));
            }
        }

        List<String> supported = new ArrayList<>();
        if (keys.contains("REPS")) {
            supported.add("averageBestRepsPerSet");
        }
        if (keys.contains("KG") && keys.contains("REPS")) {
            supported.add("estimatedOneRepMax");
            supported.add("bestSetVolume");
            supported.add("bestWeight");
        } else if (keys.contains("KG")) {
            supported.add("bestWeight");
        }
        if (keys.contains("TIME")) {
            supported.add("bestDurationSeconds");
        }
        if (keys.contains("KM")) {
            supported.add("bestDistanceKm");
        }
        if (keys.contains("TIME") && keys.contains("KM")) {
            supported.add("fastestPaceSecondsPerKm");
        }
        return supported;
    }

    private Double valueFor(WorkoutInstanceExerciseHasSets set, SetType type) {
        return set.getSetData().stream()
                .filter(d -> d.getType() == type && d.getValue() != null)
                .map(SetData::getValue)
                .findFirst()
                .orElse(null);
    }

    private Double max(Double left, Double right) {
        if (left == null) return right;
        if (right == null) return left;
        return Math.max(left, right);
    }

    private Double min(Double left, Double right) {
        if (left == null) return right;
        if (right == null) return left;
        return Math.min(left, right);
    }

    private record ExerciseMetrics(
            Double averageBestRepsPerSession,
            Double bestReps,
            Double bestOneRepMax,
            Double bestSetVolume,
            Double bestWeight,
            Double bestDurationSeconds,
            Double bestDistanceKm,
            Double fastestPaceSecondsPerKm
    ) {}
}
