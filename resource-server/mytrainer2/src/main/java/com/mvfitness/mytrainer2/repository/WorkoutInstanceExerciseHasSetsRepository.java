package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.WorkoutInstanceExerciseHasSets;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

public interface WorkoutInstanceExerciseHasSetsRepository extends JpaRepository<WorkoutInstanceExerciseHasSets, Long> {
}
