package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.Microcycle;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MicrocycleRepository extends JpaRepository<Microcycle, Long> {
}
