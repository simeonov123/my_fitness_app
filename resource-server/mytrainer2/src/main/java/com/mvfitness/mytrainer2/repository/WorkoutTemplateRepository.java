// src/main/java/com/mvfitness/mytrainer2/repository/WorkoutTemplateRepository.java
package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.WorkoutTemplate;
import com.mvfitness.mytrainer2.domain.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WorkoutTemplateRepository extends JpaRepository<WorkoutTemplate, Long> {
    Page<WorkoutTemplate> findByTrainerAndNameContainingIgnoreCase(
            User trainer,
            String q,
            Pageable pageable
    );
}
