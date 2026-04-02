package com.mvfitness.mytrainer2.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "program_days")
public class ProgramDay extends BaseTimestampedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "program_id", nullable = false)
    private Program program;

    @Column(name = "day_index", nullable = false)
    private Integer dayIndex;

    @Column(name = "rest_day", nullable = false)
    private Boolean restDay;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "workout_template_id")
    private WorkoutTemplate workoutTemplate;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(length = 50)
    private String status;

    @Column(name = "started_at")
    private LocalDateTime startedAt;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "training_session_id")
    private TrainingSession trainingSession;
}
