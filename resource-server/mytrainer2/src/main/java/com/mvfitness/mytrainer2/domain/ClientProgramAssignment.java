package com.mvfitness.mytrainer2.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "client_program_assignments")
public class ClientProgramAssignment extends BaseTimestampedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "client_id", nullable = false)
    private Client client;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "program_id", nullable = false)
    private Program program;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "assigned_by_trainer_id", nullable = false)
    private User assignedByTrainer;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(length = 50)
    private String status;

    @Column(name = "assigned_at", nullable = false)
    private LocalDateTime assignedAt;

    @PrePersist
    void prePersist() {
        if (assignedAt == null) {
            assignedAt = LocalDateTime.now();
        }
        if (status == null || status.isBlank()) {
            status = "ACTIVE";
        }
    }
}
