package com.mvfitness.mytrainer2.service.program;

import com.mvfitness.mytrainer2.domain.*;
import com.mvfitness.mytrainer2.dto.*;
import com.mvfitness.mytrainer2.mapper.TrainingSessionMapper;
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
    private final ProgramDayRepository programDays;
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
        LocalDate startDate = dto.startDate();

        boolean assignToTrainer = Boolean.TRUE.equals(dto.assignToTrainer());
        if (assignToTrainer && dto.clientIds() != null && !dto.clientIds().isEmpty()) {
            throw new IllegalArgumentException("Solo program cannot include clients");
        }

        List<Client> selectedClients = assignToTrainer
                ? List.of()
                : ownedClientsOr404(trainer, dto.clientIds());
        List<MesocycleTemplate> mesocycleTemplatesOrdered = mesocycleTemplates.findByProgramTemplateOrderBySequenceOrderAsc(template);
        if (mesocycleTemplatesOrdered.isEmpty()) {
            throw new IllegalArgumentException("Program template is incomplete");
        }

        if (assignToTrainer) {
            if (assignments.existsByTrainerAssigneeAndProgram_ProgramTemplate(trainer, template)) {
                throw new IllegalArgumentException("Program already assigned to trainer");
            }
            Program program = programs.save(Program.builder()
                    .trainer(trainer)
                    .programTemplate(template)
                    .name(template.getName())
                    .goal(template.getGoal())
                    .description(template.getDescription())
                    .build());

            int mesocycleOrder = 1;
            int globalDayIndex = 1;
            for (MesocycleTemplate mesocycleTemplate : mesocycleTemplatesOrdered) {
                MicrocycleTemplate microcycleTemplate = microcycleTemplates
                        .findFirstByMesocycleTemplateOrderBySequenceOrderAsc(mesocycleTemplate)
                        .orElseThrow(() -> new IllegalArgumentException("Program template is incomplete"));
                List<MicrocycleTemplateWorkouts> days = templateWorkouts
                        .findByMicrocycleTemplateOrderByDayIndexAsc(microcycleTemplate);

                Mesocycle mesocycle = mesocycles.save(Mesocycle.builder()
                        .program(program)
                        .name(mesocycleTemplate.getName())
                        .goal(mesocycleTemplate.getGoal())
                        .description(mesocycleTemplate.getDescription())
                        .sequenceOrder(mesocycleOrder)
                        .build());

                Microcycle microcycle = microcycles.save(Microcycle.builder()
                        .mesocycle(mesocycle)
                        .name(microcycleTemplate.getName())
                        .goal(microcycleTemplate.getGoal())
                        .description(microcycleTemplate.getDescription())
                        .sequenceOrder(1)
                        .build());

                for (int week = 0; week < mesocycleTemplate.getLengthInWeeks(); week++) {
                    for (MicrocycleTemplateWorkouts day : days) {
                        programDays.save(ProgramDay.builder()
                                .program(program)
                                .dayIndex(globalDayIndex)
                                .restDay(day.getWorkoutTemplate() == null)
                                .workoutTemplate(day.getWorkoutTemplate())
                                .notes(day.getNotes())
                                .status("PLANNED")
                                .build());
                        globalDayIndex++;
                    }
                }
                mesocycleOrder++;
            }

            assignments.save(ClientProgramAssignment.builder()
                    .trainerAssignee(trainer)
                    .program(program)
                    .assignedByTrainer(trainer)
                    .startDate(startDate)
                    .status("ACTIVE")
                    .assignedToTrainer(Boolean.TRUE)
                    .build());
            return;
        }

        for (Client client : selectedClients) {
            if (assignments.existsByClientAndProgram_ProgramTemplate(client, template)) {
                throw new IllegalArgumentException("Program already assigned to client");
            }
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

                Mesocycle mesocycle = mesocycles.save(Mesocycle.builder()
                        .program(program)
                        .name(mesocycleTemplate.getName())
                        .goal(mesocycleTemplate.getGoal())
                        .description(mesocycleTemplate.getDescription())
                        .sequenceOrder(mesocycleOrder)
                        .build());

                microcycles.save(Microcycle.builder()
                        .mesocycle(mesocycle)
                        .name(microcycleTemplate.getName())
                        .goal(microcycleTemplate.getGoal())
                        .description(microcycleTemplate.getDescription())
                        .sequenceOrder(1)
                        .build());

                for (int week = 0; week < mesocycleTemplate.getLengthInWeeks(); week++) {
                    for (MicrocycleTemplateWorkouts day : days) {
                        programDays.save(ProgramDay.builder()
                                .program(program)
                                .dayIndex(globalDayIndex)
                                .restDay(day.getWorkoutTemplate() == null)
                                .workoutTemplate(day.getWorkoutTemplate())
                                .notes(day.getNotes())
                                .status("PLANNED")
                                .build());
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
                    .assignedToTrainer(Boolean.FALSE)
                    .build());
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<ClientProgramDto> listClientPrograms(String kcUserId) {
        Client client = clientProfileOr404(kcUserId);
        return assignments.findByClientOrderByAssignedAtDesc(client).stream()
                .map(this::toClientProgramDto)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<ClientProgramDto> listTrainerAssignedPrograms(String kcUserId) {
        User trainer = trainerOr404(kcUserId);
        return assignments.findByTrainerAssigneeOrderByAssignedAtDesc(trainer).stream()
                .map(this::toClientProgramDto)
                .toList();
    }

    @Override
    public TrainingSessionDto startProgramDayForClient(String kcUserId, Long assignmentId, Integer dayIndex) {
        Client client = clientProfileOr404(kcUserId);
        ClientProgramAssignment assignment = assignments.findById(assignmentId)
                .orElseThrow(() -> new IllegalArgumentException("Program assignment not found"));
        if (assignment.getClient() == null || !Objects.equals(assignment.getClient().getId(), client.getId())) {
            throw new IllegalArgumentException("Program assignment not found");
        }
        return startProgramDay(assignment, dayIndex, assignment.getProgram().getTrainer().getKeycloakUserId(),
                List.of(client.getId()), "CLIENT");
    }

    @Override
    public TrainingSessionDto startProgramDayForTrainer(String kcUserId, Long assignmentId, Integer dayIndex) {
        User trainer = trainerOr404(kcUserId);
        ClientProgramAssignment assignment = assignments.findById(assignmentId)
                .orElseThrow(() -> new IllegalArgumentException("Program assignment not found"));
        if (assignment.getTrainerAssignee() == null ||
                !Objects.equals(assignment.getTrainerAssignee().getId(), trainer.getId())) {
            throw new IllegalArgumentException("Program assignment not found");
        }
        return startProgramDay(assignment, dayIndex, trainer.getKeycloakUserId(), List.of(), "SOLO");
    }

    private TrainingSessionDto startProgramDay(
            ClientProgramAssignment assignment,
            Integer dayIndex,
            String trainerKc,
            List<Long> clientIds,
            String sessionType
    ) {
        if (dayIndex == null || dayIndex < 1) {
            throw new IllegalArgumentException("Day index is required");
        }
        Program program = assignment.getProgram();
        ProgramDay day = programDays.findByProgramAndDayIndex(program, dayIndex)
                .orElseThrow(() -> new IllegalArgumentException("Program day not found"));
        if (Boolean.TRUE.equals(day.getRestDay())) {
            throw new IllegalArgumentException("Rest days cannot be started");
        }
        if (day.getTrainingSession() != null) {
            return TrainingSessionMapper.toDto(day.getTrainingSession());
        }

        LocalDateTime now = LocalDateTime.now();
        LocalDateTime end = now.plusHours(1);
        String workoutName = day.getWorkoutTemplate() == null ? "Workout" : day.getWorkoutTemplate().getName();

        TrainingSessionDto created = trainingSessionService.create(trainerKc, new TrainingSessionDto(
                null,
                now,
                end,
                null,
                null,
                dayIndex,
                "Day %d - %s".formatted(dayIndex, workoutName),
                program.getDescription(),
                sessionType,
                day.getNotes(),
                "PLANNED",
                Boolean.FALSE,
                clientIds,
                List.of(),
                day.getWorkoutTemplate() == null ? null : day.getWorkoutTemplate().getId()
        ));

        TrainingSession session = trainingSessions.findById(created.id())
                .orElseThrow(() -> new IllegalArgumentException("Created session not found"));
        day.setTrainingSession(session);
        day.setStartedAt(now);
        day.setStatus("STARTED");
        programDays.save(day);
        return created;
    }

    private ClientProgramDto toClientProgramDto(ClientProgramAssignment assignment) {
        Program program = assignment.getProgram();
        List<ProgramDay> days = programDays.findByProgramOrderByDayIndexAsc(program);
        if (days.isEmpty()) {
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

        int completedDays = (int) days.stream()
                .filter(day -> day.getTrainingSession() != null && Boolean.TRUE.equals(day.getTrainingSession().getIsCompleted()))
                .count();

        List<ClientProgramDayDto> dayDtos = new ArrayList<>();
        for (ProgramDay day : days) {
            TrainingSession session = day.getTrainingSession();
            WorkoutTemplate workout = day.getWorkoutTemplate();
            dayDtos.add(new ClientProgramDayDto(
                    day.getDayIndex(),
                    "Day " + day.getDayIndex(),
                    Boolean.TRUE.equals(day.getRestDay()),
                    session == null ? null : session.getId(),
                    workout == null ? null : workout.getId(),
                    workout == null ? null : workout.getName(),
                    session != null && Boolean.TRUE.equals(session.getIsCompleted())
            ));
        }

        return new ClientProgramDto(
                assignment.getId(),
                program.getId(),
                program.getName(),
                program.getGoal(),
                program.getDescription(),
                assignment.getStartDate(),
                assignment.getStartDate(),
                days.size(),
                completedDays,
                assignment.getStatus(),
                assignment.getAssignedAt(),
                dayDtos
        );
    }
}
