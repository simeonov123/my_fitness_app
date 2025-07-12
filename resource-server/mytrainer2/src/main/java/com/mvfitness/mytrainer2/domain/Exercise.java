package com.mvfitness.mytrainer2.domain;

import lombok.*;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "exercises")
public class Exercise extends BaseTimestampedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // trainer_id -> users.id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trainer_id")
    private User trainer;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    private Boolean isCustom  = Boolean.TRUE;

    // Bidirectional references:
    @OneToMany(mappedBy = "exercise", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<WorkoutTemplateExercise> workoutTemplateExercises = new ArrayList<>();

    @OneToMany(mappedBy = "exercise", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<WorkoutInstanceExercise> workoutInstanceExercises = new ArrayList<>();

    // For "exercise_substitutions", you could do something like:
    @OneToMany(mappedBy = "primaryExercise", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ExerciseSubstitution> substitutionsAsPrimary = new ArrayList<>();

    @OneToMany(mappedBy = "substituteExercise", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ExerciseSubstitution> substitutionsAsSubstitute = new ArrayList<>();

    @Column(name="default_set_type", length=50)
    private String defaultSetType;

    @Column(name="default_set_params", columnDefinition="TEXT")
    private String defaultSetParams;
}
