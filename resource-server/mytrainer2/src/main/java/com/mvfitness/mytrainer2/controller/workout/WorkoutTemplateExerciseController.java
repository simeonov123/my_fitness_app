// src/main/java/com/mvfitness/mytrainer2/controller/workout/WorkoutTemplateExerciseController.java
package com.mvfitness.mytrainer2.controller.workout;

import com.mvfitness.mytrainer2.dto.WorkoutTemplateExerciseDto;
import com.mvfitness.mytrainer2.service.workout.WorkoutTemplateExerciseService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@PreAuthorize("hasRole('TRAINER')")
@RestController
@RequiredArgsConstructor
@RequestMapping("/trainer/workout-templates/{templateId}/exercises")
public class WorkoutTemplateExerciseController {

    private final WorkoutTemplateExerciseService svc;

    private static String kc(JwtAuthenticationToken auth) {
        return auth.getToken().getSubject();
    }

    @GetMapping
    public List<WorkoutTemplateExerciseDto> list(
            JwtAuthenticationToken auth,
            @PathVariable Long templateId
    ) {
        return svc.list(kc(auth), templateId);
    }

    @PutMapping
    public List<WorkoutTemplateExerciseDto> replaceAll(
            JwtAuthenticationToken auth,
            @PathVariable Long templateId,
            @RequestBody List<WorkoutTemplateExerciseDto> dtos
    ) {
        return svc.replaceAll(kc(auth), templateId, dtos);
    }

    @DeleteMapping("/{exerciseEntryId}")
    public ResponseEntity<Void> deleteOne(
            JwtAuthenticationToken auth,
            @PathVariable Long templateId,
            @PathVariable Long exerciseEntryId
    ) {
        svc.deleteOne(kc(auth), templateId, exerciseEntryId);
        return ResponseEntity.noContent().build();
    }
}
