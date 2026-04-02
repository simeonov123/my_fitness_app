package com.mvfitness.mytrainer2.controller.program;

import com.mvfitness.mytrainer2.dto.ClientProgramDto;
import com.mvfitness.mytrainer2.dto.ProgramAssignmentRequestDto;
import com.mvfitness.mytrainer2.dto.ProgramTemplateDto;
import com.mvfitness.mytrainer2.dto.TrainingSessionDto;
import com.mvfitness.mytrainer2.service.program.ProgramTemplateService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@PreAuthorize("hasRole('TRAINER')")
@RestController
@RequestMapping("/trainer/programs")
@RequiredArgsConstructor
public class ProgramTemplateController {

    private final ProgramTemplateService service;

    private static String kc(JwtAuthenticationToken auth) {
        return auth.getToken().getSubject();
    }

    @GetMapping
    public List<ProgramTemplateDto> list(JwtAuthenticationToken auth) {
        return service.listTemplates(kc(auth));
    }

    @GetMapping("/{id}")
    public ProgramTemplateDto get(JwtAuthenticationToken auth, @PathVariable Long id) {
        return service.getTemplate(kc(auth), id);
    }

    @PostMapping
    public ProgramTemplateDto create(JwtAuthenticationToken auth, @RequestBody ProgramTemplateDto dto) {
        return service.createTemplate(kc(auth), dto);
    }

    @PutMapping("/{id}")
    public ProgramTemplateDto update(
            JwtAuthenticationToken auth,
            @PathVariable Long id,
            @RequestBody ProgramTemplateDto dto
    ) {
        return service.updateTemplate(kc(auth), id, dto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(JwtAuthenticationToken auth, @PathVariable Long id) {
        service.deleteTemplate(kc(auth), id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/assign")
    public ResponseEntity<Void> assign(
            JwtAuthenticationToken auth,
            @PathVariable Long id,
            @RequestBody ProgramAssignmentRequestDto dto
    ) {
        service.assignTemplate(kc(auth), id, dto);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/assigned")
    public List<ClientProgramDto> listAssigned(JwtAuthenticationToken auth) {
        return service.listTrainerAssignedPrograms(kc(auth));
    }

    @PostMapping("/assigned/{assignmentId}/days/{dayIndex}/start")
    public TrainingSessionDto startProgramDay(
            JwtAuthenticationToken auth,
            @PathVariable Long assignmentId,
            @PathVariable Integer dayIndex
    ) {
        return service.startProgramDayForTrainer(kc(auth), assignmentId, dayIndex);
    }
}
