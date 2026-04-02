package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.Program;
import com.mvfitness.mytrainer2.domain.ProgramDay;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ProgramDayRepository extends JpaRepository<ProgramDay, Long> {
    List<ProgramDay> findByProgramOrderByDayIndexAsc(Program program);

    Optional<ProgramDay> findByProgramAndDayIndex(Program program, Integer dayIndex);
}
