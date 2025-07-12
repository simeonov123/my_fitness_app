// ─── src/main/java/com/mvfitness/mytrainer2/dto/NutritionPlanTemplateItemDto.java
package com.mvfitness.mytrainer2.dto;

/** A single line/food in a nutrition‑template */
public record NutritionPlanTemplateItemDto(
        Long id,
        String itemName,
        String details,
        Integer sequenceOrder
) { }
