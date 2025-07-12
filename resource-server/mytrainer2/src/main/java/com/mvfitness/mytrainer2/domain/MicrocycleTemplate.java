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
@Table(name = "microcycle_templates")
public class MicrocycleTemplate extends BaseTimestampedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // mesocycle_template_id -> mesocycle_templates.id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mesocycle_template_id", nullable = false)
    private MesocycleTemplate mesocycleTemplate;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String goal;

    @Column(columnDefinition = "TEXT")
    private String description;

    private Integer lengthInDays;

    private Integer sequenceOrder;

    // Link to MicrocycleTemplateWorkouts
    @OneToMany(mappedBy = "microcycleTemplate", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<MicrocycleTemplateWorkouts> microcycleTemplateWorkouts = new ArrayList<>();
}
