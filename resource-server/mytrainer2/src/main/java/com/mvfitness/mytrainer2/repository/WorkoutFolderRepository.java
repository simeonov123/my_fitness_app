package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.User;
import com.mvfitness.mytrainer2.domain.WorkoutFolder;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface WorkoutFolderRepository extends JpaRepository<WorkoutFolder, Long> {
    List<WorkoutFolder> findByTrainerOrderBySequenceOrderAscIdAsc(User trainer);
}
