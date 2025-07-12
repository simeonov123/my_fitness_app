package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.WorkoutInstanceExercise;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface WorkoutInstanceExerciseRepository extends JpaRepository<WorkoutInstanceExercise, Long> {
    /* list all exercises for ONE training-session (across all clients) */
    List<WorkoutInstanceExercise> findByWorkoutInstance_TrainingSession_IdOrderBySequenceOrderAsc(Long sessionId);

    void deleteByWorkoutInstance_TrainingSession_Id(Long sessionId);
}
