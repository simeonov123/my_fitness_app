// src/main/java/com/mvfitness/mytrainer2/controller/exercise/ExerciseController.java
package com.mvfitness.mytrainer2.controller.exercise;

import com.mvfitness.mytrainer2.dto.ExerciseDto;
import com.mvfitness.mytrainer2.service.exercise.ExerciseService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;

@PreAuthorize("hasRole('TRAINER')")
@RestController
@RequestMapping("/trainer/exercises")
@RequiredArgsConstructor
public class ExerciseController {

    private final ExerciseService svc;
    private static String kc(JwtAuthenticationToken a){ return a.getToken().getSubject(); }

    @GetMapping
    public Page<ExerciseDto> list(
            JwtAuthenticationToken auth,
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "newest") String sort){
        return svc.list(kc(auth),q,page,size,sort);
    }


    @GetMapping("/common")
    public Page<ExerciseDto> listCommonExercises(
            JwtAuthenticationToken auth,
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "newest") String sort){
        return svc.listCommonExercises(kc(auth),q,page,size,sort);
    }

    @GetMapping("/{id}")
    public ExerciseDto get(JwtAuthenticationToken auth,@PathVariable Long id){
        return svc.get(kc(auth),id);
    }

    @PostMapping
    public ExerciseDto create(JwtAuthenticationToken auth,@RequestBody ExerciseDto dto){
        return svc.create(kc(auth),dto);
    }

    @PutMapping("/{id}")
    public ExerciseDto update(JwtAuthenticationToken auth,
                              @PathVariable Long id,
                              @RequestBody ExerciseDto dto){
        return svc.update(kc(auth),id,dto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(JwtAuthenticationToken auth,@PathVariable Long id){
        svc.delete(kc(auth),id);
        return ResponseEntity.noContent().build();
    }
}
