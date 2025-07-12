// src/main/java/com/mvfitness/mytrainer2/service/exercise/ExerciseService.java
package com.mvfitness.mytrainer2.service.exercise;

import com.mvfitness.mytrainer2.dto.ExerciseDto;
import org.springframework.data.domain.Page;

public interface ExerciseService {
    Page<ExerciseDto> list(String kcUserId, String q, int page, int size, String sort);
    ExerciseDto get(String kcUserId, Long id);
    ExerciseDto create(String kcUserId, ExerciseDto dto);
    ExerciseDto update(String kcUserId, Long id, ExerciseDto dto);
    void delete(String kcUserId, Long id);

    Page<ExerciseDto> listCommonExercises(String kc, String q, int page, int size, String sort);
}
