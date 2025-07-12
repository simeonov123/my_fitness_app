package com.mvfitness.mytrainer2.domain;

import lombok.*;

import jakarta.persistence.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "nutrition_plan_template_items")
public class NutritionPlanTemplateItem extends BaseTimestampedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // nutrition_plan_template_id -> nutrition_plan_templates.id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "nutrition_plan_template_id", nullable = false)
    private NutritionPlanTemplate nutritionPlanTemplate;

    @Column(length = 100)
    private String itemName;

    @Column(columnDefinition = "TEXT")
    private String details;

    private Integer sequenceOrder;
}
