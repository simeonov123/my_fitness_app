package com.mvfitness.mytrainer2.domain;

import lombok.*;

import jakarta.persistence.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "feedback")
public class Feedback extends BaseTimestampedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // user_id -> users.id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "item_type", length = 50, nullable = false)
    private String itemType;

    @Column(name = "item_id", nullable = false)
    private Long itemId;

    private Integer rating;

    @Column(columnDefinition = "TEXT")
    private String comment;
}
