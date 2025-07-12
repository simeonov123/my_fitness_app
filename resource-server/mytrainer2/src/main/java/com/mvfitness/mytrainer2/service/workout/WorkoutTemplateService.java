// src/main/java/com/mvfitness/mytrainer2/service/workout/WorkoutTemplateService.java
package com.mvfitness.mytrainer2.service.workout;

import com.mvfitness.mytrainer2.dto.WorkoutTemplateDto;
import org.springframework.data.domain.Page;

public interface WorkoutTemplateService {
    Page<WorkoutTemplateDto> list(String kcUserId, String q, int page, int size, String sort);
    WorkoutTemplateDto get(String kcUserId, Long id);
    WorkoutTemplateDto create(String kcUserId, WorkoutTemplateDto dto);
    WorkoutTemplateDto update(String kcUserId, Long id, WorkoutTemplateDto dto);
    void delete(String kcUserId, Long id);
}
