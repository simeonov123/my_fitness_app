package com.mvfitness.mytrainer2.repository;

import com.mvfitness.mytrainer2.domain.Client;
import com.mvfitness.mytrainer2.domain.TrainingSession;
import com.mvfitness.mytrainer2.domain.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface TrainingSessionRepository extends JpaRepository<TrainingSession, Long> {
    Page<TrainingSession> findByTrainerAndSessionNameContainingIgnoreCase(
            User trainer, String q, Pageable pageable);

    Page<TrainingSession> findDistinctByClientsContainingAndSessionNameContainingIgnoreCase(
            Client client, String q, Pageable pageable);

    @Query("""
            select distinct ts
              from TrainingSession ts
              join ts.clients c
             where c.accountUser = :accountUser
               and lower(ts.sessionName) like lower(concat('%', :q, '%'))
            """)
    Page<TrainingSession> findDistinctByClients_AccountUserAndSessionNameContainingIgnoreCase(
            @Param("accountUser") User accountUser,
            @Param("q") String q,
            Pageable pageable);

    /**
     * fetch session together with its clients in one round-trip
     */
    @EntityGraph(attributePaths = "clients")
    Optional<TrainingSession> findWithClientsById(Long id);

    @EntityGraph(attributePaths = "clients")
    Optional<TrainingSession> findWithClientsByIdAndClientsContaining(Long id, Client client);

    @EntityGraph(attributePaths = "clients")
    @Query("""
            select distinct ts
              from TrainingSession ts
              join ts.clients c
             where ts.id = :id
               and c.accountUser = :accountUser
            """)
    Optional<TrainingSession> findWithClientsByIdAndClients_AccountUser(@Param("id") Long id,
                                                                        @Param("accountUser") User accountUser);


    /* ==== NEW helpers ================================================= */

    /**
     * Paged slice for one day (00:00 ≤ start &lt; next day 00:00).
     */
    Page<TrainingSession> findByTrainerAndStartTimeBetween(
            User trainer,
            LocalDateTime from,
            LocalDateTime to,
            Pageable pageable);

    Page<TrainingSession> findDistinctByClientsContainingAndStartTimeBetween(
            Client client,
            LocalDateTime from,
            LocalDateTime to,
            Pageable pageable);

    @Query("""
            select distinct ts
              from TrainingSession ts
              join ts.clients c
             where c.accountUser = :accountUser
               and ts.startTime between :from and :to
            """)
    Page<TrainingSession> findDistinctByClients_AccountUserAndStartTimeBetween(
            @Param("accountUser") User accountUser,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to,
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

    @Query("""
            select date(ts.startTime)       as day,
                   count(distinct ts)       as cnt
              from TrainingSession ts
              join ts.clients c
             where c = :client
               and ts.startTime between :from and :to
             group by date(ts.startTime)
            """)
    List<Object[]> countPerDayForClient(@Param("client") Client client,
                                        @Param("from") LocalDateTime from,
                                        @Param("to") LocalDateTime to);

    @Query("""
            select date(ts.startTime)       as day,
                   count(distinct ts)       as cnt
              from TrainingSession ts
              join ts.clients c
             where c.accountUser = :accountUser
               and ts.startTime between :from and :to
             group by date(ts.startTime)
            """)
    List<Object[]> countPerDayForAccountUser(@Param("accountUser") User accountUser,
                                             @Param("from") LocalDateTime from,
                                             @Param("to") LocalDateTime to);

    @Modifying
    @Query("""
            update TrainingSession ts
               set ts.workoutTemplate = null
             where ts.workoutTemplate.id = :templateId
            """)
    void clearWorkoutTemplateByTemplateId(@Param("templateId") Long templateId);
}
