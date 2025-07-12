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
@Table(name = "nutrition_plan_templates")
public class NutritionPlanTemplate extends BaseTimestampedEntity {

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

    @OneToMany(mappedBy = "nutritionPlanTemplate", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<NutritionPlanTemplateItem> items = new ArrayList<>();
}
