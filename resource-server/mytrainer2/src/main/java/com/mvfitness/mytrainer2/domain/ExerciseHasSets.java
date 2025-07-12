// src/main/java/com/mvfitness/mytrainer2/domain/ExerciseHasSets.java
package com.mvfitness.mytrainer2.domain;

import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "exercise_has_sets")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ExerciseHasSets {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "workout_exercise_id", nullable = false)
    private WorkoutTemplateExercise workoutExercise;

    @Column(name = "set_number", nullable = false)
    private Integer setNumber;

    /**
     * Template‐level per‐set data (e.g. KG / REPS / TIME entries).
     * We initialize the list here so addSetData(...) never NPEs.
     */
    @Builder.Default
    @OneToMany(
            mappedBy = "exerciseSet",
            cascade = CascadeType.ALL,
            orphanRemoval = true,
            fetch = FetchType.LAZY
    )
    private List<SetData> setData = new ArrayList<>();

    /** Helper to wire the bidirectional relationship. */
    public void addSetData(SetData data) {
        data.setExerciseSet(this);
        this.setData.add(data);
    }
}
