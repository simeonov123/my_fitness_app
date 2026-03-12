package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.MuscleGroup;
import com.mvfitness.mytrainer2.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MuscleGroupRepository extends JpaRepository<MuscleGroup, Long> {
    List<MuscleGroup> findByTrainerOrIsCustomFalseOrderByNameAsc(User trainer);
    Optional<MuscleGroup> findByIdAndTrainer(Long id, User trainer);
}
