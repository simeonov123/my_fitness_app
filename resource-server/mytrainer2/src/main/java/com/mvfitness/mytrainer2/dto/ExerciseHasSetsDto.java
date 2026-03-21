// src/main/java/com/mvfitness/mytrainer2/dto/ExerciseHasSetsDto.java
package com.mvfitness.mytrainer2.dto;

import java.util.List;

public record ExerciseHasSetsDto(
        Long id,
        Integer setNumber,
        Boolean completed,
        String setContextType,
        String notes,
        Long stopwatchStartedAtMs,
        Long restStartedAtMs,
        List<SetDataDto> data
) {}
