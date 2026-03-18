// src/main/java/com/mvfitness/mytrainer2/controller/workout/WorkoutInstanceExerciseController.java
package com.mvfitness.mytrainer2.controller.workout;

import com.mvfitness.mytrainer2.dto.ExerciseHistoryDto;
import com.mvfitness.mytrainer2.dto.WorkoutInstanceExerciseDto;
import com.mvfitness.mytrainer2.service.workout.WorkoutInstanceExerciseService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/trainer/training-sessions/{sessionId}/instance")
@RequiredArgsConstructor
public class WorkoutInstanceExerciseController {

    private final WorkoutInstanceExerciseService svc;

    private static String kc(JwtAuthenticationToken a) { return a.getToken().getSubject(); }

    /* ───────── READ ───────── */

    @GetMapping
    @PreAuthorize("hasAnyRole('TRAINER','CLIENT')")
    public List<WorkoutInstanceExerciseDto> list(
            JwtAuthenticationToken auth,
            @PathVariable Long sessionId
    ) {
        return svc.list(kc(auth), sessionId);
    }

    /* ───────── REPLACE ALL ───────── */

    @PutMapping
    @PreAuthorize("hasAnyRole('TRAINER','CLIENT')")
    public List<WorkoutInstanceExerciseDto> replaceAll(
            JwtAuthenticationToken auth,
            @PathVariable Long sessionId,
            @RequestBody List<WorkoutInstanceExerciseDto> dtos
    ) {
        return svc.replaceAll(kc(auth), sessionId, dtos);
    }

    @GetMapping("/{exerciseEntryId}/history")
    @PreAuthorize("hasAnyRole('TRAINER','CLIENT')")
    public ExerciseHistoryDto history(
            JwtAuthenticationToken auth,
            @PathVariable Long sessionId,
            @PathVariable Long exerciseEntryId,
            @RequestParam(defaultValue = "5") int limit
    ) {
        return svc.history(kc(auth), sessionId, exerciseEntryId, limit);
    }

    /* ───────── DELETE ONE ───────── */

    @DeleteMapping("/{exerciseEntryId}")
    @PreAuthorize("hasAnyRole('TRAINER','CLIENT')")
    public ResponseEntity<Void> deleteOne(
            JwtAuthenticationToken auth,
            @PathVariable Long sessionId,
            @PathVariable Long exerciseEntryId
    ) {
        svc.deleteOne(kc(auth), sessionId, exerciseEntryId);
        return ResponseEntity.noContent().build();
    }
}
