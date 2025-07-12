package com.mvfitness.mytrainer2.domain;

import lombok.*;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "microcycles")
public class Microcycle extends BaseTimestampedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // mesocycle_id -> mesocycles.id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mesocycle_id", nullable = false)
    private Mesocycle mesocycle;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String goal;

    @Column(columnDefinition = "TEXT")
    private String description;

    private LocalDate startDate;
    private LocalDate endDate;
    private Integer sequenceOrder;

    @OneToMany(mappedBy = "microcycle", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<TrainingSession> trainingSessions = new ArrayList<>();
}
