// src/main/java/com/mvfitness/mytrainer2/domain/SetData.java
package com.mvfitness.mytrainer2.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "set_data")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SetData {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // <-- import your own enum, not Hibernate's
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private SetType type;

    @Column(nullable = false)
    private Double value;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exercise_set_id")
    private ExerciseHasSets exerciseSet;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "instance_set_id")
    private WorkoutInstanceExerciseHasSets instanceSet;

    /** ensure only one side is active */
    public void setExerciseSet(ExerciseHasSets exerciseSet) {
        this.exerciseSet = exerciseSet;
        this.instanceSet = null;
    }

    public void setInstanceSet(WorkoutInstanceExerciseHasSets instanceSet) {
        this.instanceSet = instanceSet;
        this.exerciseSet = null;
    }
}
