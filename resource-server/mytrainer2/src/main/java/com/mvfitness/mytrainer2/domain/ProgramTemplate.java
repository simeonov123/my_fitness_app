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
@Table(name = "program_templates")
public class ProgramTemplate extends BaseTimestampedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // trainer_id -> users.id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trainer_id")
    private User trainer;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "goal", columnDefinition = "TEXT")
    private String goal;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    // Bidirectional to MesocycleTemplate
    @OneToMany(mappedBy = "programTemplate", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<MesocycleTemplate> mesocycleTemplates = new ArrayList<>();
}
