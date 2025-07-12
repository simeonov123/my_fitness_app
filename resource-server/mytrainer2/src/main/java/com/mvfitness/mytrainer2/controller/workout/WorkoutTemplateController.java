// src/main/java/com/mvfitness/mytrainer2/controller/workout/WorkoutTemplateController.java
package com.mvfitness.mytrainer2.controller.workout;

import com.mvfitness.mytrainer2.dto.WorkoutTemplateDto;
import com.mvfitness.mytrainer2.service.workout.WorkoutTemplateService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;

@PreAuthorize("hasRole('TRAINER')")
@RestController
@RequestMapping("/trainer/workout-templates")
@RequiredArgsConstructor
public class WorkoutTemplateController {

    private final WorkoutTemplateService svc;

    private static String kc(JwtAuthenticationToken a){ return a.getToken().getSubject(); }

    @GetMapping
    public Page<WorkoutTemplateDto> list(
            JwtAuthenticationToken auth,
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "newest") String sort){
        return svc.list(kc(auth),q,page,size,sort);
    }

    @GetMapping("/{id}")
    public WorkoutTemplateDto get(JwtAuthenticationToken auth,@PathVariable Long id){
        return svc.get(kc(auth),id);
    }

    @PostMapping
    public WorkoutTemplateDto create(JwtAuthenticationToken auth,@RequestBody WorkoutTemplateDto dto){
        return svc.create(kc(auth),dto);
    }

    @PutMapping("/{id}")
    public WorkoutTemplateDto update(JwtAuthenticationToken auth,
                                     @PathVariable Long id,
                                     @RequestBody WorkoutTemplateDto dto){
        return svc.update(kc(auth),id,dto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(JwtAuthenticationToken auth,@PathVariable Long id){
        svc.delete(kc(auth),id);
        return ResponseEntity.noContent().build();
    }
}
