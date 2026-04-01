package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.ProgramTemplate;
import com.mvfitness.mytrainer2.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ProgramTemplateRepository extends JpaRepository<ProgramTemplate, Long> {
    List<ProgramTemplate> findByTrainerOrderByUpdatedAtDesc(User trainer);
}
