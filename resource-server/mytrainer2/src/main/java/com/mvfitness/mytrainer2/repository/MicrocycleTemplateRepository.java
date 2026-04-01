package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.MesocycleTemplate;
import com.mvfitness.mytrainer2.domain.MicrocycleTemplate;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface MicrocycleTemplateRepository extends JpaRepository<MicrocycleTemplate, Long> {
    Optional<MicrocycleTemplate> findFirstByMesocycleTemplateOrderBySequenceOrderAsc(MesocycleTemplate mesocycleTemplate);
}
