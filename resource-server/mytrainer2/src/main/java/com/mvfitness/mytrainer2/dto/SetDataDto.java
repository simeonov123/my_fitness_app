// src/main/java/com/mvfitness/mytrainer2/dto/SetDataDto.java
package com.mvfitness.mytrainer2.dto;

import com.mvfitness.mytrainer2.domain.SetType;

public record SetDataDto(
        Long id,
        SetType type,
        Double value
) {}
