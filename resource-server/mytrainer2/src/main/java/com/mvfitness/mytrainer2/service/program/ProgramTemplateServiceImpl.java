package com.mvfitness.mytrainer2.service.program;

import com.mvfitness.mytrainer2.domain.*;
import com.mvfitness.mytrainer2.dto.*;
import com.mvfitness.mytrainer2.repository.*;
import com.mvfitness.mytrainer2.service.session.TrainingSessionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class ProgramTemplateServiceImpl implements ProgramTemplateService {

    private final UserRepository users;
    private final ClientRepository clients;
    private final WorkoutTemplateRepository workoutTemplates;
    private final ProgramTemplateRepository programTemplates;
    private final MesocycleTemplateRepository mesocycleTemplates;
    private final MicrocycleTemplateRepository microcycleTemplates;
    private final MicrocycleTemplateWorkoutsRepository templateWorkouts;
    private final ProgramRepository programs;
    private final MesocycleRepository mesocycles;
    private final MicrocycleRepository microcycles;
    private final ClientProgramAssignmentRepository assignments;
    private final TrainingSessionRepository trainingSessions;
    private final TrainingSessionService trainingSessionService;

    private User trainerOr404(String kc) {
        User user = users.findByKeycloakUserId(kc);
        if (user == null) {
            throw new IllegalArgumentException("Trainer not found");
        }
        return user;
    }

    private User accountUserOr404(String kc) {
        User user = users.findByKeycloakUserId(kc);
        if (user == null) {
            throw new IllegalArgumentException("User not found");
        }
        return user;
    }

    private Client clientProfileOr404(String kc) {
        User accountUser = accountUserOr404(kc);
        return clients.findByAccountUser(accountUser)
                .orElseThrow(() -> new IllegalArgumentException("Client profile not found"));
    }

    private ProgramTemplate ownedTemplateOr404(String kc, Long id) {
        User trainer = trainerOr404(kc);
        ProgramTemplate template = programTemplates.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Program template not found"));
        if (template.getTrainer() == null || !trainer.getId().equals(template.getTrainer().getId())) {
            throw new IllegalArgumentException("Program template not found");
        }
        return template;
    }

    private List<Client> ownedClientsOr404(User trainer, List<Long> clientIds) {
        if (clientIds == null || clientIds.isEmpty()) {
            throw new IllegalArgumentException("Pick at least one client");
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

    private ProgramTemplateDto toDto(ProgramTemplate template) {
        List<ProgramMesocycleDto> mesocycleDtos = mesocycleTemplates
                .findByProgramTemplateOrderBySequenceOrderAsc(template)
                .stream()
                .map(mesocycleTemplate -> {
                    MicrocycleTemplate microcycleTemplate = microcycleTemplates
                            .findFirstByMesocycleTemplateOrderBySequenceOrderAsc(mesocycleTemplate)
                            .orElse(null);

                    ProgramMicrocycleDto microcycleDto = null;
                    if (microcycleTemplate != null) {
                        List<ProgramMicrocycleDayDto> dayDtos = templateWorkouts
                                .findByMicrocycleTemplateOrderByDayIndexAsc(microcycleTemplate)
                                .stream()
                                .map(day -> new ProgramMicrocycleDayDto(
                                        day.getDayIndex(),
                                        day.getWorkoutTemplate() == null,
                                        day.getWorkoutTemplate() != null ? day.getWorkoutTemplate().getId() : null,
                                        day.getWorkoutTemplate() != null ? day.getWorkoutTemplate().getName() : null,
                                        day.getNotes()
                                ))
                                .toList();

                        microcycleDto = new ProgramMicrocycleDto(
                                microcycleTemplate.getId(),
                                microcycleTemplate.getName(),
                                microcycleTemplate.getGoal(),
                                microcycleTemplate.getDescription(),
                                microcycleTemplate.getLengthInDays(),
                                microcycleTemplate.getSequenceOrder(),
                                dayDtos
                        );
                    }

                    return new ProgramMesocycleDto(
                            mesocycleTemplate.getId(),
                            mesocycleTemplate.getName(),
                            mesocycleTemplate.getGoal(),
                            mesocycleTemplate.getDescription(),
                            mesocycleTemplate.getLengthInWeeks(),
                            mesocycleTemplate.getSequenceOrder(),
                            microcycleDto
                    );
                })
                .toList();

        List<ProgramAssignedClientDto> assignedClients = List.of();
        List<Program> relatedPrograms = programs.findByProgramTemplate(template);
        if (!relatedPrograms.isEmpty()) {
            Map<Long, ProgramAssignedClientDto> byClientId = new LinkedHashMap<>();
            for (ClientProgramAssignment assignment : assignments.findByProgramIn(relatedPrograms)) {
                Client client = assignment.getClient();
                if (client == null) {
                    continue;
                }
                byClientId.putIfAbsent(
                        client.getId(),
                        new ProgramAssignedClientDto(
                                client.getId(),
                                client.getFullName(),
                                client.getEmail()
                        )
                );
            }
            assignedClients = new ArrayList<>(byClientId.values());
        }

        int totalDurationDays = mesocycleDtos.stream()
                .mapToInt(meso -> {
                    if (meso.microcycle() == null || meso.lengthInWeeks() == null) {
                        return 0;
                    }
                    return meso.lengthInWeeks() * (meso.microcycle().lengthInDays() == null ? 0 : meso.microcycle().lengthInDays());
                })
                .sum();

        return new ProgramTemplateDto(
                template.getId(),
                template.getName(),
                template.getGoal(),
                template.getDescription(),
                totalDurationDays,
                mesocycleDtos,
                assignedClients,
                template.getCreatedAt(),
                template.getUpdatedAt()
        );
    }

    private void validateTemplate(ProgramTemplateDto dto) {
        if (dto.name() == null || dto.name().isBlank()) {
            throw new IllegalArgumentException("Program name is required");
        }
        List<ProgramMesocycleDto> mesocycles = dto.mesocycles() == null ? List.of() : dto.mesocycles();
        if (mesocycles.isEmpty()) {
            throw new IllegalArgumentException("Add at least one mesocycle");
        }

        for (int mesoIndex = 0; mesoIndex < mesocycles.size(); mesoIndex++) {
            ProgramMesocycleDto mesocycle = mesocycles.get(mesoIndex);
            if (mesocycle.lengthInWeeks() == null || mesocycle.lengthInWeeks() < 1) {
                throw new IllegalArgumentException("Each mesocycle must be at least 1 week");
            }
            if (mesocycle.microcycle() == null) {
                throw new IllegalArgumentException("Each mesocycle needs a microcycle pattern");
            }
            ProgramMicrocycleDto microcycle = mesocycle.microcycle();
            if (microcycle.lengthInDays() == null || microcycle.lengthInDays() < 1) {
                throw new IllegalArgumentException("Microcycle length must be at least 1 day");
            }
            List<ProgramMicrocycleDayDto> days = microcycle.days() == null ? List.of() : microcycle.days();
            if (days.size() != microcycle.lengthInDays()) {
                throw new IllegalArgumentException("Each microcycle needs an explicit slot for every day");
            }
            Set<Integer> seenDays = new HashSet<>();
            for (ProgramMicrocycleDayDto day : days) {
                if (day.dayIndex() == null || day.dayIndex() < 1 || day.dayIndex() > microcycle.lengthInDays()) {
                    throw new IllegalArgumentException("Microcycle days must be between 1 and the pattern length");
                }
                if (!seenDays.add(day.dayIndex())) {
                    throw new IllegalArgumentException("Duplicate day inside microcycle pattern");
                }
                boolean restDay = Boolean.TRUE.equals(day.restDay());
                if (!restDay && day.workoutTemplateId() == null) {
                    throw new IllegalArgumentException("Workout selection is required for non-rest days");
                }
            }
        }
    }

    private ProgramTemplate persistTemplate(User trainer, ProgramTemplate existing, ProgramTemplateDto dto) {
        validateTemplate(dto);

        ProgramTemplate template = existing == null ? new ProgramTemplate() : existing;
        template.setTrainer(trainer);
        template.setName(dto.name().trim());
        template.setGoal(dto.goal());
        template.setDescription(dto.description());
        template = programTemplates.save(template);

        mesocycleTemplates.deleteAll(mesocycleTemplates.findByProgramTemplateOrderBySequenceOrderAsc(template));

        List<ProgramMesocycleDto> mesocycles = dto.mesocycles() == null ? List.of() : dto.mesocycles();
        List<Long> workoutIds = mesocycles.stream()
                .flatMap(meso -> meso.microcycle() == null || meso.microcycle().days() == null
                        ? java.util.stream.Stream.empty()
                        : meso.microcycle().days().stream())
                .map(ProgramMicrocycleDayDto::workoutTemplateId)
                .filter(Objects::nonNull)
                .distinct()
                .toList();
        Map<Long, WorkoutTemplate> workoutsById = workoutTemplates.findAllById(workoutIds).stream()
                .collect(Collectors.toMap(WorkoutTemplate::getId, Function.identity()));

        if (workoutsById.size() != workoutIds.size()) {
            throw new IllegalArgumentException("One or more workout templates were not found");
        }

        int mesocycleOrder = 1;
        for (ProgramMesocycleDto mesocycleDto : mesocycles) {
            MesocycleTemplate mesocycleTemplate = mesocycleTemplates.save(MesocycleTemplate.builder()
                    .programTemplate(template)
                    .name((mesocycleDto.name() == null || mesocycleDto.name().isBlank())
                            ? "Mesocycle " + mesocycleOrder
                            : mesocycleDto.name().trim())
                    .goal(mesocycleDto.goal())
                    .description(mesocycleDto.description())
                    .lengthInWeeks(mesocycleDto.lengthInWeeks())
                    .sequenceOrder(mesocycleOrder)
                    .build());

            ProgramMicrocycleDto microcycleDto = mesocycleDto.microcycle();
            MicrocycleTemplate microcycleTemplate = microcycleTemplates.save(MicrocycleTemplate.builder()
                    .mesocycleTemplate(mesocycleTemplate)
                    .name((microcycleDto.name() == null || microcycleDto.name().isBlank())
                            ? "Microcycle " + mesocycleOrder
                            : microcycleDto.name().trim())
                    .goal(microcycleDto.goal())
                    .description(microcycleDto.description())
                    .lengthInDays(microcycleDto.lengthInDays())
                    .sequenceOrder(1)
                    .build());

            for (ProgramMicrocycleDayDto day : microcycleDto.days()) {
                templateWorkouts.save(MicrocycleTemplateWorkouts.builder()
                        .microcycleTemplate(microcycleTemplate)
                        .dayIndex(day.dayIndex())
                        .workoutTemplate(Boolean.TRUE.equals(day.restDay()) ? null : workoutsById.get(day.workoutTemplateId()))
                        .notes(day.notes())
                        .build());
            }
            mesocycleOrder++;
        }

        return template;
    }

    @Override
    @Transactional(readOnly = true)
    public List<ProgramTemplateDto> listTemplates(String kcUserId) {
        User trainer = trainerOr404(kcUserId);
        return programTemplates.findByTrainerOrderByUpdatedAtDesc(trainer).stream()
                .map(this::toDto)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public ProgramTemplateDto getTemplate(String kcUserId, Long id) {
        return toDto(ownedTemplateOr404(kcUserId, id));
    }

    @Override
    public ProgramTemplateDto createTemplate(String kcUserId, ProgramTemplateDto dto) {
        return toDto(persistTemplate(trainerOr404(kcUserId), null, dto));
    }

    @Override
    public ProgramTemplateDto updateTemplate(String kcUserId, Long id, ProgramTemplateDto dto) {
        return toDto(persistTemplate(trainerOr404(kcUserId), ownedTemplateOr404(kcUserId, id), dto));
    }

    @Override
    public void deleteTemplate(String kcUserId, Long id) {
        ProgramTemplate template = ownedTemplateOr404(kcUserId, id);
        List<Program> toDelete = programs.findByProgramTemplate(template);
        if (toDelete.isEmpty() && template.getTrainer() != null) {
            toDelete = programs.findByTrainerAndName(template.getTrainer(), template.getName());
        }
        if (!toDelete.isEmpty()) {
            assignments.deleteByProgramIn(toDelete);
            programs.deleteAll(toDelete);
        }
        programTemplates.delete(template);
    }

    @Override
    public void assignTemplate(String kcUserId, Long id, ProgramAssignmentRequestDto dto) {
        User trainer = trainerOr404(kcUserId);
        ProgramTemplate template = ownedTemplateOr404(kcUserId, id);
        if (dto.startDate() == null) {
            throw new IllegalArgumentException("Start date is required");
        }

        List<Client> selectedClients = ownedClientsOr404(trainer, dto.clientIds());
        List<MesocycleTemplate> mesocycleTemplatesOrdered = mesocycleTemplates.findByProgramTemplateOrderBySequenceOrderAsc(template);
        if (mesocycleTemplatesOrdered.isEmpty()) {
            throw new IllegalArgumentException("Program template is incomplete");
        }

        for (Client client : selectedClients) {
            if (assignments.existsByClientAndProgram_ProgramTemplate(client, template)) {
                throw new IllegalArgumentException("Program already assigned to client");
            }
            LocalDate startDate = dto.startDate();
            LocalDate cursorDate = startDate;
            int globalDayIndex = 1;
            Program program = programs.save(Program.builder()
                    .trainer(trainer)
                    .programTemplate(template)
                    .name(template.getName())
                    .goal(template.getGoal())
                    .description(template.getDescription())
                    .build());

            int mesocycleOrder = 1;
            for (MesocycleTemplate mesocycleTemplate : mesocycleTemplatesOrdered) {
                MicrocycleTemplate microcycleTemplate = microcycleTemplates
                        .findFirstByMesocycleTemplateOrderBySequenceOrderAsc(mesocycleTemplate)
                        .orElseThrow(() -> new IllegalArgumentException("Program template is incomplete"));
                List<MicrocycleTemplateWorkouts> days = templateWorkouts
                        .findByMicrocycleTemplateOrderByDayIndexAsc(microcycleTemplate);

                int mesocycleDays = (mesocycleTemplate.getLengthInWeeks() == null ? 0 : mesocycleTemplate.getLengthInWeeks())
                        * (microcycleTemplate.getLengthInDays() == null ? 0 : microcycleTemplate.getLengthInDays());
                LocalDate mesocycleStart = cursorDate;
                LocalDate mesocycleEnd = mesocycleStart.plusDays(Math.max(mesocycleDays - 1L, 0L));

                Mesocycle mesocycle = mesocycles.save(Mesocycle.builder()
                        .program(program)
                        .name(mesocycleTemplate.getName())
                        .goal(mesocycleTemplate.getGoal())
                        .description(mesocycleTemplate.getDescription())
                        .startDate(mesocycleStart)
                        .endDate(mesocycleEnd)
                        .sequenceOrder(mesocycleOrder)
                        .build());

                Microcycle microcycle = microcycles.save(Microcycle.builder()
                        .mesocycle(mesocycle)
                        .name(microcycleTemplate.getName())
                        .goal(microcycleTemplate.getGoal())
                        .description(microcycleTemplate.getDescription())
                        .startDate(mesocycleStart)
                        .endDate(mesocycleEnd)
                        .sequenceOrder(1)
                        .build());

                for (int week = 0; week < mesocycleTemplate.getLengthInWeeks(); week++) {
                    for (MicrocycleTemplateWorkouts day : days) {
                        LocalDateTime sessionStart = cursorDate.atTime(12, 0);
                        LocalDateTime sessionEnd = sessionStart.plusHours(1);
                        if (day.getWorkoutTemplate() != null) {
                            String workoutName = day.getWorkoutTemplate().getName();
                            TrainingSessionDto created = trainingSessionService.create(kcUserId, new TrainingSessionDto(
                                    null,
                                    sessionStart,
                                    sessionEnd,
                                    null,
                                    null,
                                    globalDayIndex,
                                    "Day %d - %s".formatted(globalDayIndex, workoutName),
                                    template.getDescription(),
                                    "CLIENT",
                                    day.getNotes(),
                                    "PLANNED",
                                    Boolean.FALSE,
                                    List.of(client.getId()),
                                    day.getWorkoutTemplate().getId()
                            ));

                            TrainingSession session = trainingSessions.findById(created.id())
                                    .orElseThrow(() -> new IllegalArgumentException("Created session not found"));
                            session.setMicrocycle(microcycle);
                            trainingSessions.save(session);
                        }
                        cursorDate = cursorDate.plusDays(1);
                        globalDayIndex++;
                    }
                }
                mesocycleOrder++;
            }

            assignments.save(ClientProgramAssignment.builder()
                    .client(client)
                    .program(program)
                    .assignedByTrainer(trainer)
                    .startDate(startDate)
                    .status("ACTIVE")
                    .build());
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<ClientProgramDto> listClientPrograms(String kcUserId) {
        Client client = clientProfileOr404(kcUserId);
        return assignments.findByClientOrderByAssignedAtDesc(client).stream()
                .map(assignment -> {
                    Program program = assignment.getProgram();
                    List<Mesocycle> orderedMesocycles = program.getMesocycles().stream()
                            .sorted(Comparator.comparing(
                                    meso -> meso.getSequenceOrder() == null ? Integer.MAX_VALUE : meso.getSequenceOrder()))
                            .toList();
                    List<Microcycle> orderedMicrocycles = orderedMesocycles.stream()
                            .flatMap(meso -> meso.getMicrocycles().stream()
                                    .sorted(Comparator.comparing(
                                            micro -> micro.getSequenceOrder() == null ? Integer.MAX_VALUE : micro.getSequenceOrder())))
                            .toList();

                    if (orderedMicrocycles.isEmpty()) {
                        return new ClientProgramDto(
                                assignment.getId(),
                                program.getId(),
                                program.getName(),
                                program.getGoal(),
                                program.getDescription(),
                                assignment.getStartDate(),
                                assignment.getStartDate(),
                                0,
                                0,
                                assignment.getStatus(),
                                assignment.getAssignedAt(),
                                List.of()
                        );
                    }

                    List<TrainingSession> sessions = orderedMicrocycles.stream()
                            .flatMap(microcycle -> microcycle.getTrainingSessions().stream())
                            .filter(session -> session.getClients().stream()
                                    .anyMatch(c -> Objects.equals(c.getId(), client.getId())))
                            .sorted(Comparator.comparing(
                                    session -> session.getDayIndexInCycle() == null ? Integer.MAX_VALUE : session.getDayIndexInCycle()))
                            .toList();

                    Map<Integer, TrainingSession> sessionsByDay = sessions.stream()
                            .filter(session -> session.getDayIndexInCycle() != null)
                            .collect(Collectors.toMap(
                                    TrainingSession::getDayIndexInCycle,
                                    Function.identity(),
                                    (left, right) -> left,
                                    LinkedHashMap::new
                            ));

                    LocalDate programStartDate = orderedMicrocycles.get(0).getStartDate();
                    LocalDate programEndDate = orderedMicrocycles.get(orderedMicrocycles.size() - 1).getEndDate();
                    int totalDays = (int) (programEndDate.toEpochDay() - programStartDate.toEpochDay()) + 1;
                    int completedDays = (int) sessions.stream()
                            .filter(session -> Boolean.TRUE.equals(session.getIsCompleted()))
                            .count();

                    List<ClientProgramDayDto> dayDtos = new ArrayList<>();
                    for (int dayIndex = 1; dayIndex <= totalDays; dayIndex++) {
                        TrainingSession session = sessionsByDay.get(dayIndex);
                        if (session == null) {
                            dayDtos.add(new ClientProgramDayDto(
                                    dayIndex,
                                    "Day " + dayIndex,
                                    Boolean.TRUE,
                                    null,
                                    null,
                                    null,
                                    Boolean.FALSE
                            ));
                            continue;
                        }

                        dayDtos.add(new ClientProgramDayDto(
                                dayIndex,
                                "Day " + dayIndex,
                                Boolean.FALSE,
                                session.getId(),
                                session.getWorkoutTemplate() != null ? session.getWorkoutTemplate().getId() : null,
                                session.getWorkoutTemplate() != null ? session.getWorkoutTemplate().getName() : session.getSessionName(),
                                Boolean.TRUE.equals(session.getIsCompleted())
                        ));
                    }

                    return new ClientProgramDto(
                            assignment.getId(),
                            program.getId(),
                            program.getName(),
                            program.getGoal(),
                            program.getDescription(),
                            programStartDate,
                            programEndDate,
                            totalDays,
                            completedDays,
                            assignment.getStatus(),
                            assignment.getAssignedAt(),
                            dayDtos
                    );
                })
                .toList();
    }
}
