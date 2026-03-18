package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.WorkoutInstanceExercise;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface WorkoutInstanceExerciseRepository extends JpaRepository<WorkoutInstanceExercise, Long> {
    /* list all exercises for ONE training-session (across all clients) */
    List<WorkoutInstanceExercise> findByWorkoutInstance_TrainingSession_IdOrderBySequenceOrderAsc(Long sessionId);

    void deleteByWorkoutInstance_TrainingSession_Id(Long sessionId);

    void deleteByWorkoutInstance_Id(Long workoutInstanceId);

    @Query("""
            select wie.id
              from WorkoutInstanceExercise wie
              join wie.workoutInstance wi
              join wi.trainingSession ts
              join wi.client c
              join wie.exercise e
             where c.id = :clientId
               and e.id = :exerciseId
               and ts.id <> :sessionId
               and ts.isCompleted = true
             order by ts.startTime desc, wi.performedAt desc, wie.sequenceOrder asc
            """)
    List<Long> findHistoryIdsForClientExercise(
            @Param("clientId") Long clientId,
            @Param("exerciseId") Long exerciseId,
            @Param("sessionId") Long sessionId,
            Pageable pageable
    );

    @Query("""
            select distinct wie
              from WorkoutInstanceExercise wie
              join fetch wie.workoutInstance wi
              join fetch wi.trainingSession ts
              join fetch wi.client c
              join fetch wie.exercise e
             where wie.id in :ids
            """)
    List<WorkoutInstanceExercise> findAllWithDetailsByIdIn(@Param("ids") List<Long> ids);
}
