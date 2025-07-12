// ─── src/main/java/com/mvfitness/mytrainer2/dto/NutritionPlanTemplateDto.java
package com.mvfitness.mytrainer2.dto;

import java.time.LocalDateTime;
import java.util.List;

/** DTO exposed to the front‑end for template CRUD */
public record NutritionPlanTemplateDto(
        Long id,
        String name,
        String description,
        List<NutritionPlanTemplateItemDto> items,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) { }
