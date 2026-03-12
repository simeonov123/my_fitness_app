package com.mvfitness.mytrainer2.controller.exercise;

import com.mvfitness.mytrainer2.dto.MuscleGroupDto;
import com.mvfitness.mytrainer2.service.exercise.MuscleGroupService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@PreAuthorize("hasRole('TRAINER')")
@RestController
@RequestMapping({"/trainer/muscle-groups", "/trainer/exercises/muscle-groups"})
@RequiredArgsConstructor
public class MuscleGroupController {

    private final MuscleGroupService svc;

    private static String kc(JwtAuthenticationToken a) {
        return a.getToken().getSubject();
    }

    @GetMapping
    public List<MuscleGroupDto> list(JwtAuthenticationToken auth) {
        return svc.list(kc(auth));
    }

    @PostMapping
    public MuscleGroupDto create(JwtAuthenticationToken auth, @RequestBody MuscleGroupDto dto) {
        return svc.create(kc(auth), dto);
    }

    @PutMapping("/{id}")
    public MuscleGroupDto update(
            JwtAuthenticationToken auth,
            @PathVariable Long id,
            @RequestBody MuscleGroupDto dto
    ) {
        return svc.update(kc(auth), id, dto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(JwtAuthenticationToken auth, @PathVariable Long id) {
        svc.delete(kc(auth), id);
        return ResponseEntity.noContent().build();
    }
}
