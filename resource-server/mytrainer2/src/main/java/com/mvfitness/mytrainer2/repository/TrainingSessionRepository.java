package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.TrainingSession;
import com.mvfitness.mytrainer2.domain.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface TrainingSessionRepository extends JpaRepository<TrainingSession, Long> {
    Page<TrainingSession> findByTrainerAndSessionNameContainingIgnoreCase(
            User trainer, String q, Pageable pageable);

    /**
     * fetch session together with its clients in one round-trip
     */
    @EntityGraph(attributePaths = "clients")
    Optional<TrainingSession> findWithClientsById(Long id);


    /* ==== NEW helpers ================================================= */

    /**
     * Paged slice for one day (00:00 ≤ start &lt; next day 00:00).
     */
    Page<TrainingSession> findByTrainerAndStartTimeBetween(
            User trainer,
            LocalDateTime from,
            LocalDateTime to,
            Pageable pageable);

    /**
     * Aggregate counts per day in a date-range (inclusive).
     */
    @Query("""
            select date(ts.startTime)       as day,
                   count(ts)                as cnt
              from TrainingSession ts
             where ts.trainer = :trainer
               and ts.startTime between :from and :to
             group by date(ts.startTime)
            """)
    List<Object[]> countPerDay(@Param("trainer") User trainer,
                               @Param("from") LocalDateTime from,
                               @Param("to") LocalDateTime to);
}
