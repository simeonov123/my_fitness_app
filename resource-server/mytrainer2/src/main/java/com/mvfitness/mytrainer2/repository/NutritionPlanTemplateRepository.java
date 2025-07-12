// ─── src/main/java/com/mvfitness/mytrainer2/repository/NutritionPlanTemplateRepository.java
package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.NutritionPlanTemplate;
import com.mvfitness.mytrainer2.domain.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NutritionPlanTemplateRepository extends JpaRepository<NutritionPlanTemplate, Long> {
    Page<NutritionPlanTemplate> findByTrainerAndNameContainingIgnoreCase(
            User trainer,
            String search,
            Pageable pageable
    );
}
