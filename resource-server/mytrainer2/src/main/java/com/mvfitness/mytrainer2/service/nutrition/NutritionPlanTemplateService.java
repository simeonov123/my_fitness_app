// ─── src/main/java/com/mvfitness/mytrainer2/service/nutrition/NutritionPlanTemplateService.java
package com.mvfitness.mytrainer2.service.nutrition;

import com.mvfitness.mytrainer2.dto.NutritionPlanTemplateDto;
import org.springframework.data.domain.Page;

public interface NutritionPlanTemplateService {
    Page<NutritionPlanTemplateDto> list(String kcUserId, String q, int page, int size, String sort);

    NutritionPlanTemplateDto get(String kcUserId, Long templateId);

    NutritionPlanTemplateDto create(String kcUserId, NutritionPlanTemplateDto dto);

    NutritionPlanTemplateDto update(String kcUserId, Long templateId, NutritionPlanTemplateDto dto);

    void delete(String kcUserId, Long templateId);
}
