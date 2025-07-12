package com.mvfitness.mytrainer2.domain;

import lombok.*;

import jakarta.persistence.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "microcycle_template_workouts")
public class MicrocycleTemplateWorkouts extends BaseTimestampedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "microcycle_template_id", nullable = false)
    private MicrocycleTemplate microcycleTemplate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "workout_template_id")
    private WorkoutTemplate workoutTemplate;

    private Integer dayIndex;

    @Column(columnDefinition = "TEXT")
    private String notes;
}
