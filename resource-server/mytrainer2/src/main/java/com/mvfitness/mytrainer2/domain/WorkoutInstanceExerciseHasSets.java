package com.mvfitness.mytrainer2.domain;

import com.mvfitness.mytrainer2.domain.WorkoutInstanceExercise;
import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "workout_instance_exercise_has_sets")
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class WorkoutInstanceExerciseHasSets {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "workout_instance_exercise_id", nullable = false)
    private WorkoutInstanceExercise workoutInstanceExercise;

    @Column(name = "set_number", nullable = false)
    private Integer setNumber;

    @Builder.Default
    @OneToMany(mappedBy = "instanceSet",
            cascade = CascadeType.ALL,
            orphanRemoval = true)
    private List<SetData> setData = new ArrayList<>();

    public void addSetData(SetData data) {
        data.setInstanceSet(this);
        this.setData.add(data);
    }
}
