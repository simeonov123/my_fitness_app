package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.MesocycleTemplate;
import com.mvfitness.mytrainer2.domain.ProgramTemplate;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MesocycleTemplateRepository extends JpaRepository<MesocycleTemplate, Long> {
    Optional<MesocycleTemplate> findFirstByProgramTemplateOrderBySequenceOrderAsc(ProgramTemplate programTemplate);
    List<MesocycleTemplate> findByProgramTemplateOrderBySequenceOrderAsc(ProgramTemplate programTemplate);
}
