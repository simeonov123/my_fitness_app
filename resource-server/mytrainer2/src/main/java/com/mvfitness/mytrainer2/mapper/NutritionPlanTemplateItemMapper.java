// ─── src/main/java/com/mvfitness/mytrainer2/mapper/NutritionPlanTemplateItemMapper.java
package com.mvfitness.mytrainer2.mapper;

import com.mvfitness.mytrainer2.domain.NutritionPlanTemplateItem;
import com.mvfitness.mytrainer2.dto.NutritionPlanTemplateItemDto;

public final class NutritionPlanTemplateItemMapper {
    private NutritionPlanTemplateItemMapper() { }

    public static NutritionPlanTemplateItemDto toDto(NutritionPlanTemplateItem e) {
        return new NutritionPlanTemplateItemDto(
                e.getId(),
                e.getItemName(),
                e.getDetails(),
                e.getSequenceOrder()
        );
    }

    public static void updateEntity(NutritionPlanTemplateItem e, NutritionPlanTemplateItemDto d) {
        e.setItemName(d.itemName());
        e.setDetails(d.details());
        e.setSequenceOrder(d.sequenceOrder());
    }
}
