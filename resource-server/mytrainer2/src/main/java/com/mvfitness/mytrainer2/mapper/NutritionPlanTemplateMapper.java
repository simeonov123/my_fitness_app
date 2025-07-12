// ─── src/main/java/com/mvfitness/mytrainer2/mapper/NutritionPlanTemplateMapper.java
package com.mvfitness.mytrainer2.mapper;

import com.mvfitness.mytrainer2.domain.NutritionPlanTemplate;
import com.mvfitness.mytrainer2.domain.NutritionPlanTemplateItem;
import com.mvfitness.mytrainer2.dto.NutritionPlanTemplateDto;
import com.mvfitness.mytrainer2.dto.NutritionPlanTemplateItemDto;

import java.util.List;
import java.util.stream.Collectors;

public final class NutritionPlanTemplateMapper {
    private NutritionPlanTemplateMapper() { }

    public static NutritionPlanTemplateDto toDto(NutritionPlanTemplate t) {
        List<NutritionPlanTemplateItemDto> items = t.getItems()
                .stream()
                .map(NutritionPlanTemplateItemMapper::toDto)
                .collect(Collectors.toList());

        return new NutritionPlanTemplateDto(
                t.getId(),
                t.getName(),
                t.getDescription(),
                items,
                t.getCreatedAt(),
                t.getUpdatedAt()
        );
    }

    public static void updateEntity(NutritionPlanTemplate t, NutritionPlanTemplateDto d) {
        t.setName(d.name());
        t.setDescription(d.description());

        /* Simple one‑shot replace of items (fine for small lists).
           In production you might want a smarter diff/merge. */
        t.getItems().clear();
        if (d.items() != null) {
            for (NutritionPlanTemplateItemDto iDto : d.items()) {
                NutritionPlanTemplateItem i = NutritionPlanTemplateItem.builder()
                        .nutritionPlanTemplate(t)
                        .itemName(iDto.itemName())
                        .details(iDto.details())
                        .sequenceOrder(iDto.sequenceOrder())
                        .build();
                t.getItems().add(i);
            }
        }
    }
}
