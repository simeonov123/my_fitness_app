package com.mvfitness.mytrainer2.domain;

import lombok.*;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "aggregated_stats")
public class AggregatedStats {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // client_id -> clients.id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "client_id", nullable = false)
    private Client client;

    @Column(length = 50, nullable = false)
    private String entityType;

    @Column(nullable = false)
    private Long entityId;

    private Integer totalVolume;

    @Column(precision = 6, scale = 2)
    private BigDecimal averageWeight;

    @Column(precision = 3, scale = 2)
    private BigDecimal ratingAverage;

    private LocalDate startDate;
    private LocalDate endDate;


}
