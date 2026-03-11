package com.mvfitness.mytrainer2.domain;

import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "client_folders")
public class ClientFolder extends BaseTimestampedEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(name = "sequence_order")
    private Integer sequenceOrder;

    @Builder.Default
    @OneToMany(mappedBy = "folder")
    private List<Client> clients = new ArrayList<>();
}
