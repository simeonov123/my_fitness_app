package com.mvfitness.mytrainer2.controller.workout;

import com.mvfitness.mytrainer2.dto.WorkoutFolderDto;
import com.mvfitness.mytrainer2.service.workout.WorkoutFolderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@PreAuthorize("hasRole('TRAINER')")
@RestController
@RequestMapping("/trainer/workout-folders")
@RequiredArgsConstructor
public class WorkoutFolderController {

    private final WorkoutFolderService svc;

    private static String kc(JwtAuthenticationToken a){ return a.getToken().getSubject(); }

    @GetMapping
    public List<WorkoutFolderDto> list(JwtAuthenticationToken auth) {
        return svc.list(kc(auth));
    }

    @PostMapping
    public WorkoutFolderDto create(JwtAuthenticationToken auth, @RequestBody WorkoutFolderDto dto) {
        return svc.create(kc(auth), dto);
    }

    @PutMapping("/{id}")
    public WorkoutFolderDto update(
            JwtAuthenticationToken auth,
            @PathVariable Long id,
            @RequestBody WorkoutFolderDto dto
    ) {
        return svc.update(kc(auth), id, dto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(JwtAuthenticationToken auth, @PathVariable Long id) {
        svc.delete(kc(auth), id);
        return ResponseEntity.noContent().build();
    }
}
