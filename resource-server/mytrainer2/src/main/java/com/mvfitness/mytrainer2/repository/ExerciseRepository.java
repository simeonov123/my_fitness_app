package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.Exercise;
import com.mvfitness.mytrainer2.domain.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ExerciseRepository  extends JpaRepository<Exercise, Long> {
    Exercise findByName(String name);

    boolean existsByName(String name);

    boolean existsByIdAndName(Long id, String name);

    Page<Exercise> findByTrainerAndNameContainingIgnoreCase(
            User trainer,
            String q,
            Pageable pageable
    );

    Page<Exercise> findByIsCustomFalseAndNameContainingIgnoreCase(
            String q, Pageable pageable
    );
}
