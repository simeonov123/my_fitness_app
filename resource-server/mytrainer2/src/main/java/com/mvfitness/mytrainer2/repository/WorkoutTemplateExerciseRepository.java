// src/main/java/com/mvfitness/mytrainer2/repository/WorkoutTemplateExerciseRepository.java
package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.WorkoutTemplateExercise;
import com.mvfitness.mytrainer2.domain.WorkoutTemplate;
import jakarta.transaction.Transactional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface WorkoutTemplateExerciseRepository
        extends JpaRepository<WorkoutTemplateExercise, Long> {

    /** find all exercises for a given template, ordered by sequenceOrder */
    List<WorkoutTemplateExercise> findByWorkoutTemplateOrderBySequenceOrderAsc(WorkoutTemplate tpl);

    /** delete all exercises belonging to a template (used on full replace) */
    void deleteByWorkoutTemplate(WorkoutTemplate tpl);

    /**
     * Delete all WorkoutTemplateExercise rows for a given template.
     */
    @Modifying
    @Transactional
    @Query("""
      delete from WorkoutTemplateExercise wte
      where wte.workoutTemplate.id = :templateId
      """)
    void deleteByWorkoutTemplateId(Long templateId);



}
