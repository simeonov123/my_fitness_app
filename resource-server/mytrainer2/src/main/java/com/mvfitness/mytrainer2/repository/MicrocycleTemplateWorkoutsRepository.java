package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.MicrocycleTemplate;
import com.mvfitness.mytrainer2.domain.MicrocycleTemplateWorkouts;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MicrocycleTemplateWorkoutsRepository extends JpaRepository<MicrocycleTemplateWorkouts, Long> {
    List<MicrocycleTemplateWorkouts> findByMicrocycleTemplateOrderByDayIndexAsc(MicrocycleTemplate microcycleTemplate);
}
