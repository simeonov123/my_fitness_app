package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.TrainingSession;
import com.mvfitness.mytrainer2.domain.User;
import com.mvfitness.mytrainer2.domain.WorkoutInstance;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface WorkoutInstanceRepository extends JpaRepository<WorkoutInstance, Long> {
    /** list every instance whose parent session belongs to a given trainer */
    Page<WorkoutInstance> findByTrainingSession_Trainer(User trainer, Pageable pageable);

    /** list instances belonging to exactly one session (the session is already ownership-checked) */
    Page<WorkoutInstance> findByTrainingSession(TrainingSession session, Pageable pageable);

    @Modifying
    @Query("""
            update WorkoutInstance wi
               set wi.workoutTemplate = null
             where wi.workoutTemplate.id = :templateId
            """)
    void clearWorkoutTemplateByTemplateId(@Param("templateId") Long templateId);
}
