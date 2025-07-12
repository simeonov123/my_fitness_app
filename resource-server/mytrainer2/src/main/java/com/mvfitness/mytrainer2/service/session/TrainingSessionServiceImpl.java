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

    private TrainingSession ownedOr404(String kc, Long id) {
        TrainingSession t = sessions.findWithClientsById(id)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));
        if (!t.getTrainer().getKeycloakUserId().equals(kc))
            throw new IllegalArgumentException("Session not found");
        return t;
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

        Page<TrainingSession> p = sessions
                .findByTrainerAndSessionNameContainingIgnoreCase(
                        trainerOr404(kc), (q == null ? "" : q),
                        PageRequest.of(page, size, order));

        return p.map(TrainingSessionMapper::toDto);
    }

    @Override @Transactional(readOnly = true)
    public TrainingSessionDto get(String kc, Long id) {
        return TrainingSessionMapper.toDto( ownedOr404(kc, id) );
    }

    /* ───────────────── create ──────────────────────────────────────── */

    @Override
    public TrainingSessionDto create(String kc, TrainingSessionDto d) {

        /* 1) base entities */
        User trainer = trainerOr404(kc);

        List<Client> clientRefs = (d.clientIds() == null || d.clientIds().isEmpty())
                ? List.of()
                : clients.findAllById(d.clientIds());

        if (d.clientIds() != null && clientRefs.size() != d.clientIds().size())
            throw new IllegalArgumentException("One or more clients not found");

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

        /* 3) deep-clone template → instances (sets included) */
        if (tpl != null && !clientRefs.isEmpty()) {
            injectDeepClone(session, tpl);
        }

        /* 4) persist (+ cascades) */
        return TrainingSessionMapper.toDto(sessions.save(session));
    }

    /* ───────────────── update ──────────────────────────────────────── */

    @Override
    public TrainingSessionDto update(String kc, Long id, TrainingSessionDto d) {

        TrainingSession s = ownedOr404(kc, id);

        /* client list */
        if (d.clientIds() != null) {
            List<Client> newClients = clients.findAllById(d.clientIds());
            if (newClients.size() != d.clientIds().size())
                throw new IllegalArgumentException("One or more clients not found");
            s.getClients().clear();
            s.getClients().addAll(newClients);
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
            injectDeepClone(s, tpl);
        }

        /* scalars */
        s.setStartTime(d.startTime());
        s.setEndTime(d.endTime());
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

    private void injectDeepClone(TrainingSession session, WorkoutTemplate tpl) {

        /* load template exercises + their sets in one go */
        List<WorkoutTemplateExercise> exTpls =
                templateExercises.findByWorkoutTemplateOrderBySequenceOrderAsc(tpl);
        exTpls.forEach(e -> e.getExerciseHasSets()
                .forEach(sh -> sh.getSetData().size())); // init LAZY

        for (Client cli : session.getClients()) {

            WorkoutInstance wi = WorkoutInstance.builder()
                    .trainingSession(session)
                    .client(cli)
                    .workoutTemplate(tpl)
                    .build();
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
                wi.getWorkoutInstanceExercises().add(ie);

                /* clone every set (+ per-set data) */
                te.getExerciseHasSets().forEach(ehs -> {

                    WorkoutInstanceExerciseHasSets ies = WorkoutInstanceExerciseHasSets.builder()
                            .workoutInstanceExercise(ie)
                            .setNumber(ehs.getSetNumber())
                            .build();
                    ie.getWorkoutInstanceExerciseHasSets().add(ies);

                    ehs.getSetData().forEach(sd -> {
                        SetData copy = SetData.builder()
                                .type(sd.getType())
                                .value(sd.getValue())
                                .build();
                        ies.addSetData(copy);
                    });
                });
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

        var trainer = trainerOr404(kc);

        // inclusive range → add one day, then < nextDay00:00
        LocalDateTime fromTs = from.atStartOfDay();
        LocalDateTime toTs   = to.plusDays(1).atStartOfDay().minusNanos(1);

        List<Object[]> raw = sessions.countPerDay(trainer, fromTs, toTs);

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

        var trainer = trainerOr404(kc);
        LocalDateTime from = day.atStartOfDay();
        LocalDateTime to   = day.plusDays(1).atStartOfDay().minusNanos(1);

        Page<TrainingSession> p = sessions.findByTrainerAndStartTimeBetween(
                trainer, from, to, PageRequest.of(page, size, Sort.by("startTime").ascending()));

        return p.map(TrainingSessionMapper::toDto);
    }
}
