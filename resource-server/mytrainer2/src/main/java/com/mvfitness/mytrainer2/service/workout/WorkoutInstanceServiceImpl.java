package com.mvfitness.mytrainer2.service.workout;

import com.mvfitness.mytrainer2.domain.TrainingSession;
import com.mvfitness.mytrainer2.domain.User;
import com.mvfitness.mytrainer2.domain.WorkoutInstance;
import com.mvfitness.mytrainer2.dto.WorkoutInstanceDto;
import com.mvfitness.mytrainer2.mapper.WorkoutInstanceMapper;
import com.mvfitness.mytrainer2.repository.TrainingSessionRepository;
import com.mvfitness.mytrainer2.repository.UserRepository;
import com.mvfitness.mytrainer2.repository.WorkoutInstanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class WorkoutInstanceServiceImpl implements WorkoutInstanceService {

    private final WorkoutInstanceRepository repo;
    private final TrainingSessionRepository sessions;
    private final UserRepository            users;

    /* ─ helpers ─ */
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

    /* ─ API ─ */
    @Override @Transactional(readOnly = true)
    public Page<WorkoutInstanceDto> list(String kc, Long sessionId,
                                         int page, int size, String sort) {

        Sort order = "oldest".equalsIgnoreCase(sort)
                ? Sort.by("id").ascending()
                : Sort.by("id").descending();

        Page<WorkoutInstance> p = (sessionId == null)
                ? repo.findByTrainingSession_Trainer(
                trainerOr404(kc),
                PageRequest.of(page, size, order))
                : repo.findByTrainingSession(
                ownedSessionOr404(kc, sessionId),
                PageRequest.of(page, size, order));

        return p.map(WorkoutInstanceMapper::toDto);
    }

    @Override @Transactional(readOnly = true)
    public WorkoutInstanceDto get(String kc, Long id) {
        WorkoutInstance wi = repo.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Workout-instance not found"));

        if (!wi.getTrainingSession().getTrainer().getKeycloakUserId().equals(kc))
            throw new IllegalArgumentException("Workout-instance not found");

        return WorkoutInstanceMapper.toDto(wi);
    }
}
