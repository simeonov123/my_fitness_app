package com.mvfitness.mytrainer2.domain;

import lombok.*;

import jakarta.persistence.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "exercise_substitutions")
public class ExerciseSubstitution extends BaseTimestampedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // primary_exercise_id -> exercises.id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "primary_exercise_id", nullable = false)
    private Exercise primaryExercise;

    // substitute_exercise_id -> exercises.id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "substitute_exercise_id", nullable = false)
    private Exercise substituteExercise;
}
