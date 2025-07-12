package com.mvfitness.mytrainer2.service.workout;

import com.mvfitness.mytrainer2.dto.WorkoutInstanceDto;
import org.springframework.data.domain.Page;

public interface WorkoutInstanceService {

    Page<WorkoutInstanceDto> list(String kcUserId,
                                  Long sessionId,
                                  int page,
                                  int size,
                                  String sort);

    WorkoutInstanceDto get(String kcUserId, Long id);
}
