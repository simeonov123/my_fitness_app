package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.Program;
import com.mvfitness.mytrainer2.domain.ProgramTemplate;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ProgramRepository extends JpaRepository<Program, Long> {
    List<Program> findByProgramTemplate(ProgramTemplate programTemplate);
}
