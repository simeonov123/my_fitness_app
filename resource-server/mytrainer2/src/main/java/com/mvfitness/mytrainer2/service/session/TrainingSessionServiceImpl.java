package com.mvfitness.mytrainer2.service.session;

import com.mvfitness.mytrainer2.domain.*;
import com.mvfitness.mytrainer2.dto.CalendarDayCountDto;
import com.mvfitness.mytrainer2.dto.TrainingSessionDto;
import com.mvfitness.mytrainer2.mapper.TrainingSessionMapper;
import com.mvfitness.mytrainer2.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service                                   // <-- only ONE @Service with this name exists now
@RequiredArgsConstructor
@Transactional
public class TrainingSessionServiceImpl implements TrainingSessionService {

    private final TrainingSessionRepository sessions;
    private final UserRepository            users;
    private final ClientRepository          clients;
    private final WorkoutTemplateRepository templates;

    private final WorkoutTemplateExerciseRepository templateExercises;

    /* 🔹 extra repos needed for manual delete */
    private final WorkoutInstanceRepository               instanceRepo;
    private final WorkoutInstanceExerciseRepository       instanceExRepo;
    private final WorkoutInstanceExerciseHasSetsRepository instanceSetRepo;
    private final SetDataRepository                       setDataRepo;
    /* ───────────────── helpers ─────────────────────────────────────── */

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

    private TrainingSession ownedOr404(String kc, Long id) {
        TrainingSession t = sessions.findWithClientsById(id)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));
        if (!t.getTrainer().getKeycloakUserId().equals(kc))
            throw new IllegalArgumentException("Session not found");
        return t;
    }

    private List<Client> ownedClientsOr404(User trainer, List<Long> clientIds) {
        if (clientIds == null || clientIds.isEmpty()) {
            return List.of();
        }

        List<Client> found = clients.findAllById(clientIds);
        if (found.size() != clientIds.size()) {
            throw new IllegalArgumentException("One or more clients not found");
        }

        boolean invalidOwnership = found.stream()
                .anyMatch(client -> client.getUser() == null || !trainer.getId().equals(client.getUser().getId()));
        if (invalidOwnership) {
            throw new IllegalArgumentException("One or more clients not found");
        }

        Map<Long, Client> byId = found.stream()
                .collect(Collectors.toMap(Client::getId, Function.identity()));

        return clientIds.stream()
                .map(byId::get)
                .toList();
    }

    /* ───────────────── list / get ──────────────────────────────────── */

    @Override @Transactional(readOnly = true)
    public Page<TrainingSessionDto> list(String kc, String q,
                                         int page, int size, String sort) {

        Sort order = switch (sort) {
            case "name"      -> Sort.by("sessionName").ascending();
            case "name_desc" -> Sort.by("sessionName").descending();
            case "oldest"    -> Sort.by("startTime").ascending();
            default          -> Sort.by("startTime").descending();
        };

        Page<TrainingSession> p;
        if (isTrainer(kc)) {
            p = sessions.findByTrainerAndSessionNameContainingIgnoreCase(
                    trainerOr404(kc), (q == null ? "" : q),
                    PageRequest.of(page, size, order));
        } else {
            p = sessions.findDistinctByClients_AccountUserAndSessionNameContainingIgnoreCase(
                    accountUserOr404(kc), (q == null ? "" : q),
                    PageRequest.of(page, size, order));
        }

        return p.map(TrainingSessionMapper::toDto);
    }

    @Override @Transactional(readOnly = true)
    public TrainingSessionDto get(String kc, Long id) {
        if (isTrainer(kc)) {
            return TrainingSessionMapper.toDto(ownedOr404(kc, id));
        }
        TrainingSession session = sessions.findWithClientsByIdAndClients_AccountUser(id, accountUserOr404(kc))
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));
        return TrainingSessionMapper.toDto(session);
    }

    /* ───────────────── create ──────────────────────────────────────── */

    @Override
    public TrainingSessionDto create(String kc, TrainingSessionDto d) {

        /* 1) base entities */
        User trainer = trainerOr404(kc);

        List<Client> clientRefs = ownedClientsOr404(trainer, d.clientIds());

        WorkoutTemplate tpl = (d.workoutTemplateId() == null) ? null
                : templates.findById(d.workoutTemplateId())
                .orElseThrow(() -> new IllegalArgumentException("Template not found"));

        /* 2) session shell */
        TrainingSession session = TrainingSession.builder()
                .trainer(trainer)
                .clients(new ArrayList<>(clientRefs))
                .workoutTemplate(tpl)
                .startTime(d.startTime())
                .endTime(d.endTime())
                .dayIndexInCycle(d.dayIndexInCycle())
                .sessionName(d.sessionName())
                .sessionDescription(d.sessionDescription())
                .sessionType(d.sessionType())
                .trainerNotes(d.trainerNotes())
                .status(d.status())
                .isCompleted(Boolean.FALSE)
                .build();

        /* 3) persist shell first so workout instances are built from a managed session */
        session = sessions.save(session);

        /* 4) deep-clone template → instances (sets included) */
        if (tpl != null && !clientRefs.isEmpty()) {
            injectDeepClone(session, tpl, clientRefs);
        }

        /* 5) persist (+ cascades) */
        return TrainingSessionMapper.toDto(sessions.save(session));
    }

    /* ───────────────── update ──────────────────────────────────────── */

    @Override
    public TrainingSessionDto update(String kc, Long id, TrainingSessionDto d) {

        TrainingSession s = ownedOr404(kc, id);

        /* client list */
        if (d.clientIds() != null) {
            List<Long> currentClientIds = s.getClients().stream()
                    .map(Client::getId)
                    .sorted()
                    .toList();
            List<Long> requestedClientIds = d.clientIds().stream()
                    .sorted()
                    .toList();

            if (!currentClientIds.equals(requestedClientIds)) {
                List<Client> newClients = ownedClientsOr404(trainerOr404(kc), d.clientIds());
                s.getClients().clear();
                s.getClients().addAll(newClients);
            }
        }

        /* template switch */
        if (d.workoutTemplateId() != null &&
                (s.getWorkoutTemplate() == null ||
                        !s.getWorkoutTemplate().getId().equals(d.workoutTemplateId()))) {

            WorkoutTemplate tpl = templates.findById(d.workoutTemplateId())
                    .orElseThrow(() -> new IllegalArgumentException("Template not found"));

            s.setWorkoutTemplate(tpl);

            /* rebuild instances */
            s.getWorkoutInstances().clear();
            injectDeepClone(s, tpl, new ArrayList<>(s.getClients()));
        } else if (d.workoutTemplateId() == null && s.getWorkoutTemplate() != null) {
            s.setWorkoutTemplate(null);
        }

        /* scalars */
        s.setStartTime(d.startTime());
        s.setEndTime(d.endTime());
        s.setActualStartTime(d.actualStartTime());
        s.setActualEndTime(d.actualEndTime());
        s.setDayIndexInCycle(d.dayIndexInCycle());
        s.setSessionName(d.sessionName());
        s.setSessionDescription(d.sessionDescription());
        s.setSessionType(d.sessionType());
        s.setTrainerNotes(d.trainerNotes());
        s.setStatus(d.status());
        s.setIsCompleted(d.isCompleted());

        return TrainingSessionMapper.toDto(sessions.save(s));
    }

    /* ───────────────── delete ───────────────── */
    @Override
    @Transactional
    public void delete(String kc, Long id) {
        sessions.delete( ownedOr404(kc, id) );
    }




    /* ───────────────── private deep-clone helper ───────────────────── */

    private void injectDeepClone(TrainingSession session, WorkoutTemplate tpl, List<Client> clientsForInstances) {

        /* load template exercises + their sets in one go */
        List<WorkoutTemplateExercise> exTpls =
                templateExercises.findByWorkoutTemplateOrderBySequenceOrderAsc(tpl);
        exTpls.forEach(e -> e.getExerciseHasSets()
                .forEach(sh -> sh.getSetData().size())); // init LAZY

        for (Client cli : clientsForInstances) {

            WorkoutInstance wi = WorkoutInstance.builder()
                    .trainingSession(session)
                    .client(cli)
                    .workoutTemplate(tpl)
                    .build();
            wi = instanceRepo.save(wi);
            session.getWorkoutInstances().add(wi);

            for (WorkoutTemplateExercise te : exTpls) {

                WorkoutInstanceExercise ie = WorkoutInstanceExercise.builder()
                        .workoutInstance(wi)
                        .exercise(te.getExercise())
                        .sequenceOrder(te.getSequenceOrder())
                        .setType(te.getSetType())
                        .setParams(te.getSetParams())
                        .notes(te.getNotes())
                        .build();
                ie = instanceExRepo.save(ie);
                wi.getWorkoutInstanceExercises().add(ie);

                /* clone every set (+ per-set data) */
                for (ExerciseHasSets ehs : te.getExerciseHasSets()) {

                    WorkoutInstanceExerciseHasSets ies = WorkoutInstanceExerciseHasSets.builder()
                            .workoutInstanceExercise(ie)
                            .setNumber(ehs.getSetNumber())
                            .completed(ehs.getCompleted())
                            .setContextType(ehs.getSetContextType())
                            .notes(ehs.getNotes())
                            .build();
                    ies = instanceSetRepo.save(ies);
                    ie.getWorkoutInstanceExerciseHasSets().add(ies);

                    for (SetData sd : ehs.getSetData()) {
                        SetData copy = SetData.builder()
                                .type(sd.getType())
                                .value(sd.getValue())
                                .build();
                        ies.addSetData(copy);
                        setDataRepo.save(copy);
                    }
                }
            }
        }
    }



    /* ───────── calendar optimisation ───────── */

    @Override @Transactional(readOnly = true)
    public List<CalendarDayCountDto> calendarCounts(String kc,
                                                    LocalDate from,
                                                    LocalDate to) {

        if (to.isBefore(from))
            throw new IllegalArgumentException("`to` must be ≥ `from`");

        // inclusive range → add one day, then < nextDay00:00
        LocalDateTime fromTs = from.atStartOfDay();
        LocalDateTime toTs   = to.plusDays(1).atStartOfDay().minusNanos(1);

        List<Object[]> raw = isTrainer(kc)
                ? sessions.countPerDay(trainerOr404(kc), fromTs, toTs)
                : sessions.countPerDayForAccountUser(accountUserOr404(kc), fromTs, toTs);

        Map<LocalDate,Long> tmp = new HashMap<>();
        for (Object[] row : raw) {
            LocalDate day  = ((java.sql.Date) row[0]).toLocalDate();
            long      cnt  = ((Number) row[1]).longValue();
            tmp.put(day, cnt);
        }

        List<CalendarDayCountDto> out = new ArrayList<>();
        LocalDate cur = from;
        while (!cur.isAfter(to)) {
            out.add(new CalendarDayCountDto(cur, tmp.getOrDefault(cur, 0L)));
            cur = cur.plusDays(1);
        }
        return out;
    }

    @Override @Transactional(readOnly = true)
    public Page<TrainingSessionDto> listForDay(String kc,
                                               LocalDate day,
                                               int page,
                                               int size) {

        LocalDateTime from = day.atStartOfDay();
        LocalDateTime to   = day.plusDays(1).atStartOfDay().minusNanos(1);

        Page<TrainingSession> p = isTrainer(kc)
                ? sessions.findByTrainerAndStartTimeBetween(
                        trainerOr404(kc), from, to,
                        PageRequest.of(page, size, Sort.by("startTime").ascending()))
                : sessions.findDistinctByClients_AccountUserAndStartTimeBetween(
                        accountUserOr404(kc), from, to,
                        PageRequest.of(page, size, Sort.by("startTime").ascending()));

        return p.map(TrainingSessionMapper::toDto);
    }
}
