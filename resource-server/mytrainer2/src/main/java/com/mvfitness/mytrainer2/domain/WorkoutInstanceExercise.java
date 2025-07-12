package com.mvfitness.mytrainer2.domain;

import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "workout_instance_exercises")
public class WorkoutInstanceExercise extends BaseTimestampedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /* parents */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "workout_instance_id", nullable = false)
    private WorkoutInstance workoutInstance;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;

    /* scalar cols */
    private Integer sequenceOrder;

    @Column(length = 50)
    private String setType;

    @Column(columnDefinition = "TEXT")
    private String setParams;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Builder.Default
    @OneToMany(mappedBy = "workoutInstanceExercise",
            cascade = CascadeType.ALL,
            orphanRemoval = true)
    private List<WorkoutInstanceExerciseHasSets> workoutInstanceExerciseHasSets = new ArrayList<>();
}
