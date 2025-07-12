package com.mvfitness.mytrainer2.domain;

import lombok.*;

import jakarta.persistence.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "nutrition_plan_items")
public class NutritionPlanItem extends BaseTimestampedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // nutrition_plan_id -> nutrition_plans.id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "nutrition_plan_id", nullable = false)
    private NutritionPlan nutritionPlan;

    @Column(length = 100)
    private String itemName;

    @Column(columnDefinition = "TEXT")
    private String details;

    private Integer sequenceOrder;
}
