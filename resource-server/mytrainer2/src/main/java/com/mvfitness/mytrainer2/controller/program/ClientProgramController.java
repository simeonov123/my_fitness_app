package com.mvfitness.mytrainer2.controller.program;

import com.mvfitness.mytrainer2.dto.ClientProgramDto;
import com.mvfitness.mytrainer2.dto.TrainingSessionDto;
import com.mvfitness.mytrainer2.service.program.ProgramTemplateService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@PreAuthorize("hasRole('CLIENT')")
@RestController
@RequestMapping("/client/programs")
@RequiredArgsConstructor
public class ClientProgramController {

    private final ProgramTemplateService service;

    @GetMapping
    public List<ClientProgramDto> list(JwtAuthenticationToken auth) {
        return service.listClientPrograms(auth.getToken().getSubject());
    }

    @PostMapping("/{assignmentId}/days/{dayIndex}/start")
    public TrainingSessionDto startProgramDay(
            JwtAuthenticationToken auth,
            @PathVariable Long assignmentId,
            @PathVariable Integer dayIndex
    ) {
        return service.startProgramDayForClient(auth.getToken().getSubject(), assignmentId, dayIndex);
    }
}
