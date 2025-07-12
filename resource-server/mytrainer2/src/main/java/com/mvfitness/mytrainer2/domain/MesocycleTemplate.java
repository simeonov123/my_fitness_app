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
@Table(name = "mesocycle_templates")
public class MesocycleTemplate extends BaseTimestampedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // program_template_id -> program_templates.id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "program_template_id", nullable = false)
    private ProgramTemplate programTemplate;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String goal;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "sequence_order")
    private Integer sequenceOrder;

    @OneToMany(mappedBy = "mesocycleTemplate", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<MicrocycleTemplate> microcycleTemplates = new ArrayList<>();
}
